import SwiftUI
import AVFoundation
import UIKit
import CoreML
import Vision

// Main SwiftUI View for Tab Navigation
struct VisuallyImpairedView: View {
    var body: some View {
        TabView {
            CameraTabView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .navigationBarHidden(true)
    }
}

// SwiftUI View to display the Camera feed
struct CameraTabView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                if cameraManager.isDetectionRunning {
                    Button(action: {
                        cameraManager.stopLiveStream()
                    }) {
                        Text("Stop Detection")
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 50)
                } else {
                    Button(action: {
                        cameraManager.startLiveStream()
                    }) {
                        Text("Start Detection")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            cameraManager.configure()
        }
    }
}

// Camera Manager
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var model: VNCoreMLModel?
    private var lastFrameTime = Date()
    private var lastDetectionTime = Date()
    private var lastAnnouncedObject: String?
    private var lastAnnouncementTime = Date() // Track the time of the last announcement
    private let framesPerSecond = 5 // Adjusted for smoother detection
    private let allowedClasses = ["Desk", "Light Switch", "Hand", "Earbud", "Door", "Board", "Airpods Case", "Oumy", "Juju", "Laptop", "Projector", "Trash Can", "Outlet", "Cellphone", "Chair", "Fire Extinguisher", "Glasses", "Podium", "Keyboard", "Pencil", "Exit sign", "Poster", "Water Bottle"]

    @Published var isDetectionRunning = false

    override init() {
        super.init()
        configureCoreMLModel()
    }

    func configure() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Error: Unable to access the back camera!")
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            print("Error: Couldn't add camera input.")
            session.commitConfiguration()
            return
        }

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            print("Error: Couldn't add video output.")
            session.commitConfiguration()
            return
        }

        session.commitConfiguration()
        session.startRunning() // Camera feed always runs
    }

    func startLiveStream() {
        isDetectionRunning = true
        announceDetectionStart()
        scheduleNothingAnnouncement()
    }

    func stopLiveStream() {
        isDetectionRunning = false
        announceDetectionStop()
    }

    private func configureCoreMLModel() {
        do {
            let coreMLModel = try AinModel_1(configuration: MLModelConfiguration())
            model = try VNCoreMLModel(for: coreMLModel.model)
            print("Model loaded successfully.")
        } catch {
            print("Error: Failed to load Core ML model - \(error.localizedDescription)")
        }
    }

    private func processFrame(imageBuffer: CVImageBuffer) {
        guard let model = model, isDetectionRunning else { return }

        let now = Date()
        if now.timeIntervalSince(lastFrameTime) < 1.0 / Double(framesPerSecond) { return }
        lastFrameTime = now

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self?.handleDetectionResults(results)
            } else if let error = error {
                print("Error processing frame: \(error.localizedDescription)")
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform request: \(error.localizedDescription)")
        }
    }

    private func handleDetectionResults(_ results: [VNRecognizedObjectObservation]) {
        guard let label = results.first?.labels.first?.identifier, allowedClasses.contains(label) else { return }

        let now = Date()
        if label != lastAnnouncedObject, now.timeIntervalSince(lastAnnouncementTime) > 1 { // Wait at least 1 seconds
            lastAnnouncedObject = label
            lastDetectionTime = now
            lastAnnouncementTime = now
            announceDetectedObject(label)
        }
    }

    private func announceDetectionStart() {
        let utterance = AVSpeechUtterance(string: "Starting detection.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-UK")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
        }
    }

    private func announceDetectionStop() {
        let utterance = AVSpeechUtterance(string: "Stopping detection.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-UK")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
        }
    }

    private func announceDetectedObject(_ object: String) {
        let utterance = AVSpeechUtterance(string: "\(object)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-UK")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
        }
    }

    private func scheduleNothingAnnouncement() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.lastDetectionTime) >= 5, self.isDetectionRunning {
                self.announceNothingDetected()
                self.scheduleNothingAnnouncement() // Reschedule
            }
        }
    }

    private func announceNothingDetected() {
        let utterance = AVSpeechUtterance(string: "Nothing.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-UK")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFrame(imageBuffer: imageBuffer)
    }
}

// Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}


// Preview
struct VisuallyImpairedView_Previews: PreviewProvider {
    static var previews: some View {
        VisuallyImpairedView()
    }
}




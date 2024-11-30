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

// SwiftUI View for displaying the camera feed and starting object detection
struct CameraTabView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
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
        .onAppear {
            cameraManager.configure()
        }
    }
}

// Class to manage the camera
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var model: VNCoreMLModel?
    private var lastFrameTime = Date()
    private var lastDetectionTime: Date?
    private var lastAnnouncedObject: String?
    private let framesPerSecond = 2
    private let allowedClasses = ["Mouse", "Light Switch", "Hand", "Earbud", "Door", "Board", "Airpods Case"] 

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
    }

    func startLiveStream() {
        session.startRunning()
        announceDetectionStart()
    }

    private func configureCoreMLModel() {
        do {
            let coreMLModel = try AinModel_2(configuration: MLModelConfiguration())
            model = try VNCoreMLModel(for: coreMLModel.model)
            print("Model loaded successfully.")
        } catch {
            print("Error: Failed to load Core ML model - \(error.localizedDescription)")
        }
    }

    private func processFrame(imageBuffer: CVImageBuffer) {
        guard let model = model else {
            print("Error: Core ML model is not loaded.")
            return
        }

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
        for observation in results {
            guard let label = observation.labels.first?.identifier else { continue }

            // Skip if the class is not in the allowed list
            if !allowedClasses.contains(label) { continue }

            // Announce only if the object changes
            if label != lastAnnouncedObject {
                lastAnnouncedObject = label
                announceDetectedObject(label)
            }
        }
    }

    private func announceDetectionStart() {
        let utterance = AVSpeechUtterance(string: "Starting detection.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
        }
    }

    private func announceDetectedObject(_ object: String) {
        let utterance = AVSpeechUtterance(string: "\(object)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        if now.timeIntervalSince(lastFrameTime) < 1.0 / Double(framesPerSecond) { return }
        lastFrameTime = now

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFrame(imageBuffer: imageBuffer)
    }
}

// UIViewRepresentable for Camera Preview in SwiftUI
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        session.startRunning()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// Preview for Visually Impaired View
struct VisuallyImpairedView_Previews: PreviewProvider {
    static var previews: some View {
        VisuallyImpairedView()
    }
}



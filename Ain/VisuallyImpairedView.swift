import SwiftUI
import AVFoundation
import UIKit

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

// Class to manage the Camera
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var roboflowURL: URL?
    private var lastFrameTime = Date()
    private var lastDetectionTime: Date?
    private var detectionTimer: Timer?
    private var lastAnnouncedObject: String?
    private let framesPerSecond = 2
    private var frameCountSinceLastDetection = 0
    private let maxFramesWithoutDetection = 10

    override init() {
        super.init()
        configureRoboflow()
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
        resetDetectionTracking()
    }

    private func configureRoboflow() {
        roboflowURL = URL(string: "https://detect.roboflow.com/ain-on19r/7?api_key=99tvoVX14VOvwcbDYyqQ")
    }

    private func processFrame(imageBuffer: CVImageBuffer) {
        guard let roboflowURL = roboflowURL else {
            print("Error: Roboflow URL is not configured.")
            return
        }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let uiImage = UIImage(ciImage: ciImage)

        guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
            print("Error: Failed to encode image as JPEG.")
            return
        }

        let fileContent = imageData.base64EncodedString()
        guard let postData = fileContent.data(using: .utf8) else {
            print("Error: Could not encode image data to UTF-8.")
            return
        }

        var request = URLRequest(url: roboflowURL, timeoutInterval: Double.infinity)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData

        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }

            do {
                if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    self.handleDetectionResult(dict)
                }
            } catch {
                print("Failed to parse Roboflow response: \(error.localizedDescription)")
            }
        }).resume()
    }

    private func handleDetectionResult(_ result: [String: Any]) {
        if let predictions = result["predictions"] as? [[String: Any]] {
            if predictions.isEmpty {
                frameCountSinceLastDetection += 1
                checkNoDetectionCondition()
            } else {
                handleNonEmptyPrediction(predictions)
            }
        } else {
            print("No 'predictions' key in response.")
        }
    }

    private func handleNonEmptyPrediction(_ predictions: [[String: Any]]) {
        for prediction in predictions {
            if let label = prediction["class"] as? String {
                if label != lastAnnouncedObject {
                    announceDetectedObject(label)
                    lastAnnouncedObject = label
                    resetDetectionTracking()
                    break
                }
            }
        }
    }

    private func checkNoDetectionCondition() {
        if frameCountSinceLastDetection >= maxFramesWithoutDetection,
           let lastDetectionTime = lastDetectionTime,
           Date().timeIntervalSince(lastDetectionTime) >= 5.0 {
            announceDetectedObject("Nothing")
            resetDetectionTracking()
        }
    }

    private func resetDetectionTracking() {
        frameCountSinceLastDetection = 0
        lastDetectionTime = Date()
    }

    private func announceDetectionStart() {
        let utterance = AVSpeechUtterance(string: "Starting detection.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
        }
    }

    private func announceDetectedObject(_ object: String) {
        let utterance = AVSpeechUtterance(string: "Detected \(object)")
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

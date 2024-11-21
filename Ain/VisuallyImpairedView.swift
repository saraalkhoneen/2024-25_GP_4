import SwiftUI
import AVFoundation
import Firebase
import FirebaseStorage

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

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var roboflowURL: URL?
    private var lastFrameTime = Date()

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
    }
    
    private func configureRoboflow() {
        // Use the full API endpoint provided by Roboflow
                    roboflowURL = URL(string: "https://app.roboflow.com/ds/5U8XURyiN4?key=D946GYUpBl")
    }

    private func processFrame(imageBuffer: CVImageBuffer) {
        guard let roboflowURL = roboflowURL else {
            print("Error: Roboflow URL is not configured.")
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let uiImage = UIImage(ciImage: ciImage)
        
        // Save the frame locally for debugging
        saveImageForDebugging(uiImage)
        
        guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
            print("Error: Failed to encode image as JPEG.")
            return
        }
        
        var request = URLRequest(url: roboflowURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending frame to Roboflow: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error: Non-200 HTTP response.")
                return
            }
            
            guard let data = data else {
                print("Error: No data received.")
                return
            }
            
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Roboflow Response: \(rawResponse)")
            }
            
            guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Failed to parse Roboflow response.")
                return
            }
            
            self.handleDetectionResult(jsonResponse)
        }.resume()
    }
    
    private func handleDetectionResult(_ result: [String: Any]) {
        if let predictions = result["predictions"] as? [[String: Any]] {
            if predictions.isEmpty {
                print("Predictions are empty.")
            } else {
                for prediction in predictions {
                    if let label = prediction["class"] as? String {
                        DispatchQueue.main.async {
                            self.announceDetectedObject(label)
                        }
                    }
                }
            }
        } else {
            print("No 'predictions' key in response.")
        }
    }
    
    private func announceDetectionStart() {
        let utterance = AVSpeechUtterance(string: "Starting object detection.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
            print("Voice feedback: \(utterance.speechString)") // Debugging log
        }
    }
    
    private func announceDetectedObject(_ object: String) {
        let utterance = AVSpeechUtterance(string: "Detected \(object)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
            print("Voice feedback: \(utterance.speechString)") // Debugging log
        }
    }
    
    private func saveImageForDebugging(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("debug_frame.jpg")
        do {
            try imageData.write(to: filePath)
            print("Debug frame saved to: \(filePath)")
        } catch {
            print("Failed to save debug frame: \(error.localizedDescription)")
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        if now.timeIntervalSince(lastFrameTime) < 1.0 { return } // Process 1 frame per second
        lastFrameTime = now
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFrame(imageBuffer: imageBuffer)
    }
}

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

struct VisuallyImpairedView_Previews: PreviewProvider {
    static var previews: some View {
        VisuallyImpairedView()
    }
}


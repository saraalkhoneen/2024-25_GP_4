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
                    cameraManager.startRecording()
                }) {
                    Text("Start Recording")
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
    private var videoOutput = AVCaptureMovieFileOutput()
    private var outputURL: URL?
    
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
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            print("Error: Couldn't add video output.")
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    func startRecording() {
        let outputDirectory = FileManager.default.temporaryDirectory
        outputURL = outputDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        
        guard let outputURL = outputURL else {
            print("Error: Unable to generate output URL.")
            return
        }
        
        if !videoOutput.isRecording {
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        if videoOutput.isRecording {
            videoOutput.stopRecording()
        }
    }
    
    private func uploadToFirebase(fileURL: URL) {
        let storage = Storage.storage(url: "gs://ain-5ee1b.appspot.com") // Your custom bucket
        let storageRef = storage.reference().child("videos/\(UUID().uuidString).mov")

        storageRef.putFile(from: fileURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading video: \(error.localizedDescription)")
                return
            }

            print("Upload successful!")
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to retrieve download URL: \(error.localizedDescription)")
                    return
                }

                if let downloadURL = url {
                    print("Video uploaded successfully to: \(downloadURL.absoluteString)")
                }
            }
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo fileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
            return
        }
        
        print("Recording finished successfully. Saving to Firebase...")
        
        // Verify the file exists before uploading
        if FileManager.default.fileExists(atPath: fileURL.path) {
            uploadToFirebase(fileURL: fileURL)
        } else {
            print("Error: File not found at \(fileURL.path)")
        }
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

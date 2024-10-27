import SwiftUI
import AVFoundation

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
        .navigationBarHidden(true) // Ensures no navigation bars appear
    }
}

// Camera tab view with camera preview
struct CameraTabView: View {
    var body: some View {
        ZStack {
            // Camera view as background
            CameraPreviewView()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

// UIViewRepresentable for displaying the camera preview
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return view
        }
        
        session.addInput(input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        
        session.startRunning()
        
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

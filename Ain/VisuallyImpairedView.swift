//  VisuallyImpairedView.swift
//  Ain
//  Created by Sara alkhoneen and joud alhussain

import SwiftUI
import AVFoundation

struct VisuallyImpairedView: View {
    var body: some View {
        ZStack {
            // Camera view as background
            CameraPreviewView()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top-right settings icon
                HStack {
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(15)
                    }
                    .padding(.top, 40)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

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

struct VisuallyImpairedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VisuallyImpairedView()
        }
    }
}

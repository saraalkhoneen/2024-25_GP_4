//
//  ContentView.swift
//  test
//
//  Created by Ain on 1/7/25.
//

import SwiftUI
import Speech

struct ContentView: View {
    @State private var message: String = "Shake the device!"
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var isRecognizing = false

    var body: some View {
        VStack {
            Text(message)
                .font(.largeTitle)
                .padding()
        }
        .onShake {
            startListening()
        }
        .onAppear {
            requestSpeechAuthorization()
        }
    }

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Authorized")
            case .denied:
                print("Denied")
            case .restricted, .notDetermined:
                print("Not available")
            @unknown default:
                break
            }
        }
    }

    private func startListening() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            message = "Speech recognizer is not available."
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        let audioEngine = AVAudioEngine()

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result = result {
                    let spokenText = result.bestTranscription.formattedString
                    message = spokenText
                }
                if error != nil || (result?.isFinal ?? false) {
                    audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    recognitionTask = nil
                }
            }
        } catch {
            message = "Audio Engine Error: \(error.localizedDescription)"
        }
    }
}

// Extension for shake detection
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetector(action: action))
    }
}

struct ShakeDetector: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ShakeView(action: action))
    }
}

struct ShakeView: UIViewControllerRepresentable {
    let action: () -> Void

    func makeUIViewController(context: Context) -> ShakeUIViewController {
        let controller = ShakeUIViewController()
        controller.action = action
        return controller
    }

    func updateUIViewController(_ uiViewController: ShakeUIViewController, context: Context) {}
}

class ShakeUIViewController: UIViewController {
    var action: (() -> Void)?

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            action?()
        }
    }
}

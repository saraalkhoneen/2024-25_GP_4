import SwiftUI
import AVFoundation
import UIKit
import CoreML
import Vision
import FirebaseStorage
import Firebase
import FirebaseAuth
import CoreLocation
import UserNotifications

import Speech
import CoreMotion

struct VisuallyImpairedView: View {
    @StateObject private var locationManager = LocationManager()

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
        .onAppear {
            locationManager.startUpdatingLocation()
        }
        .navigationBarHidden(true)
    }
}

struct LocationSharingView: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack {
            if let location = locationManager.lastKnownLocation {
                Text("Latitude: \(location.latitude)")
                Text("Longitude: \(location.longitude)")
                
                Button("Share Location") {
                    shareLocation(location: location)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text("Fetching location...")
            }
        }
        .padding()
    }
    
    private func shareLocation(location: CLLocationCoordinate2D) {
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("Error: User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Guardian")
            .whereField("visuallyImpairedEmail", isEqualTo: userEmail)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching guardian UID: \(error.localizedDescription)")
                    return
                }
                
                if let guardianDoc = snapshot?.documents.first {
                    let guardianUID = guardianDoc.documentID
                    db.collection("Locations")
                        .document(guardianUID)
                        .setData([
                            "latitude": location.latitude,
                            "longitude": location.longitude,
                            "timestamp": Timestamp(date: Date())
                        ]) { error in
                            if let error = error {
                                print("Error sharing location: \(error.localizedDescription)")
                            } else {
                                print("Location shared successfully")
                            }
                        }
                }
            }
    }
    
}
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    @Published var lastKnownLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.lastKnownLocation = location.coordinate
        }
        self.updateLocationInFirestore(location: location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to fetch location: \(error.localizedDescription)")
    }

    private func updateLocationInFirestore(location: CLLocationCoordinate2D) {
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("Error: User not logged in")
            return
        }

        let db = Firestore.firestore()
        db.collection("Guardian")
            .whereField("visuallyImpairedEmail", isEqualTo: userEmail)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching guardian UID: \(error.localizedDescription)")
                    return
                }

                if let guardianDoc = snapshot?.documents.first {
                    let guardianUID = guardianDoc.documentID
                    db.collection("Locations")
                        .document(guardianUID)
                        .setData([
                            "latitude": location.latitude,
                            "longitude": location.longitude,
                            "timestamp": Timestamp(date: Date())
                        ]) { error in
                            if let error = error {
                                print("Error sharing location: \(error.localizedDescription)")
                            } else {
                                print("Location updated successfully")
                            }
                        }
                }
            }
    }
}


// SwiftUI View to display the Camera feed
struct CameraTabView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var motionManager = MotionManager() // Add MotionManager instance
    @State private var isListening = false // Track listening state

    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                if cameraManager.uploadProgress > 0 && cameraManager.uploadProgress < 100 {
                    CircularProgressBar(progress: cameraManager.uploadProgress / 100)
                        .frame(width: 80, height: 80)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            cameraManager.configure() // Initialize the camera manager
            motionManager.startMonitoring() // Start motion monitoring for shake detection
            print("MotionManager started.") // Debugging: Confirm MotionManager is initialized
        }

        .onChange(of: motionManager.isShaking) { isShaking in
            if isShaking {
                print("Shake detected!") // Confirm shake detection works
                triggerVoiceCommand() // Call voice command function
            } else {
                print("Shake reset, no command triggered.") // Confirm reset
            }
        }


    }

    private func triggerVoiceCommand() {
        guard !isListening else {
            print("Already listening, ignoring this shake.") // Debugging
            return
        }

        // Request speech authorization before proceeding
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized.")
                    self.startSpeechRecognition() // Start recognition after authorization
                case .denied:
                    print("Speech recognition authorization denied.")
                case .restricted:
                    print("Speech recognition restricted on this device.")
                case .notDetermined:
                    print("Speech recognition not determined.")
                @unknown default:
                    print("Unknown speech recognition authorization status.")
                }
            }
        }
    }


    private func startSpeechRecognition() {
        isListening = true
        print("Listening for voice commands...") // Debugging

        let audioEngine = AVAudioEngine()
        let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechAudioBufferRecognitionRequest()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer is not available.") // Debugging
            isListening = false
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            print("Audio Engine started.") // Debugging
        } catch {
            print("Audio Engine couldn't start: \(error.localizedDescription)") // Debugging
            isListening = false
            return
        }

        recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                let command = result.bestTranscription.formattedString.lowercased()
                print("Command heard: \(command)") // Debugging
                self.handleVoiceCommand(command) // Handle the recognized command
            } else if let error = error {
                print("Speech recognition error: \(error.localizedDescription)") // Debugging
            }

            // Stop audio engine after recognition is complete
            self.isListening = false
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
        }

        // Add a timeout of 10 seconds to stop recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isListening {
                print("Speech recognition timeout.")
                self.isListening = false
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
            }
        }
    }



    private func handleVoiceCommand(_ command: String) {
        print("Handling command: \(command)") // Debugging

        switch command {
        case "start":
            cameraManager.startLiveStream()
            print("Started detection") // Debugging

        case "text":
            cameraManager.startTextRecognitionStream()
            print("Started text recognition") // Debugging

        case "stop":
            cameraManager.stopLiveStream()
            cameraManager.stopTextRecognitionStream()
            print("Stopped detection and text recognition") // Debugging

        case "help":
            cameraManager.capturePhotoAndVideo { success in
                cameraManager.announceHelpRequestSuccess()
                sendHelpRequest()
            }
            print("Help request sent") // Debugging

        default:
            cameraManager.announceMessage("Unknown command. Please try again.")
            print("Unknown command: \(command)") // Debugging
        }
    }




    /// Sends a help request to the guardian by creating a notification in Firestore.
    /// Sends a help request notification
       func sendHelpRequest() {
           let db = Firestore.firestore()

           guard let currentUserEmail = Auth.auth().currentUser?.email else {
               print("Error: User email not found")
               return
           }

           fetchUserDetails(forEmail: currentUserEmail) { userDetails in
               guard let userDetails = userDetails else {
                   print("Error: User details not found")
                   return
               }

               let fullName = "\(userDetails["firstName"] ?? "Unknown") \(userDetails["lastName"] ?? "User")"

               fetchGuardianUID(forEmail: currentUserEmail) { guardianUID in
                   guard let guardianUID = guardianUID else {
                       print("Error: Guardian UID not found")
                       return
                   }

                   let notificationId = UUID().uuidString
                   let notification = [
                       "id": notificationId,
                       "title": "Help Request",
                       "details": "\(fullName) has requested help. Check the media tab for photos and videos.",
                       "date": Timestamp(date: Date())
                   ] as [String: Any]

                   db.collection("Notifications")
                       .document(guardianUID)
                       .collection("UserNotifications")
                       .document(notificationId)
                       .setData(notification) { error in
                           if let error = error {
                               print("Error sending notification: \(error.localizedDescription)")
                           } else {
                               print("Notification sent successfully with ID: \(notificationId)")

                               // Trigger local notification
                               self.triggerLocalNotification(title: "Help Request", body: "\(fullName) has requested help.")
                           }
                       }
               }
           }
       }

       /// Triggers a local notification
       func triggerLocalNotification(title: String, body: String) {
           let content = UNMutableNotificationContent()
           content.title = title
           content.body = body
           content.sound = .default

           let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

           UNUserNotificationCenter.current().add(request) { error in
               if let error = error {
                   print("Error scheduling local notification: \(error.localizedDescription)")
               } else {
                   print("Local notification triggered successfully.")
               }
           }
       }

       /// Fetch user details based on email
       func fetchUserDetails(forEmail email: String, completion: @escaping ([String: String]?) -> Void) {
           let db = Firestore.firestore()

           db.collection("Visually_Impaired")
               .whereField("email", isEqualTo: email)
               .getDocuments { snapshot, error in
                   if let error = error {
                       print("Error fetching user details: \(error.localizedDescription)")
                       completion(nil)
                       return
                   }

                   if let document = snapshot?.documents.first, let data = document.data() as? [String: String] {
                       completion(data)
                   } else {
                       print("No user found with the email: \(email)")
                       completion(nil)
                   }
               }
       }

       /// Fetch guardian UID based on the VI email
       func fetchGuardianUID(forEmail email: String, completion: @escaping (String?) -> Void) {
           let db = Firestore.firestore()

           db.collection("Guardian")
               .whereField("visuallyImpairedEmail", isEqualTo: email)
               .getDocuments { snapshot, error in
                   if let error = error {
                       print("Error fetching Guardian UID: \(error.localizedDescription)")
                       completion(nil)
                       return
                   }

                   if let document = snapshot?.documents.first {
                       completion(document.documentID)
                   } else {
                       print("No guardian found for email: \(email)")
                       completion(nil)
                   }
               }
       }
   }

struct CircularProgressBar: View {
    var progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .opacity(0.3)
                .foregroundColor(.blue)

            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)

            Text(String(format: "%.0f%%", progress * 100))
                .font(.caption)
                .foregroundColor(.blue)
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
    @Published var uploadProgress: Double = 0 // Track upload progress
    
    private let photoOutput = AVCapturePhotoOutput() // Added for photo capture
    private let videoFileOutput = AVCaptureMovieFileOutput() // Added for video recording
    private var capturedPhotoData: Data? // Store photo data
    private var isVideoSaved = false // Track video save completion
    private var lastRecognizedText: String = ""
    @Published var isTextRecognitionRunning = false
    private var isProcessingTextFrame = false
    private let textRecognitionInterval: TimeInterval = 2.0 // 2 seconds
    private var textRecognitionTask: DispatchWorkItem? // To manage recognition cancellation



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
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput) // Add photo output
        }
        
        if session.canAddOutput(videoFileOutput) {
            session.addOutput(videoFileOutput) // Add video file output
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
    func startTextRecognitionStream() {
           isTextRecognitionRunning = true
           announceMessage("Text recognition started.")
       }

       func stopTextRecognitionStream() {
           isTextRecognitionRunning = false
           textRecognitionTask?.cancel() // Cancel ongoing recognition task
           stopSpeech() // Stop any ongoing speech synthesis
           announceMessage("Text recognition stopped.")
       }

       private func stopSpeech() {
           if speechSynthesizer.isSpeaking {
               speechSynthesizer.stopSpeaking(at: .immediate)
           }
       }
    
    private func resizeImageBuffer(_ imageBuffer: CVImageBuffer, width: Int, height: Int) -> CVImageBuffer {
        let ciImage = CIImage(cvPixelBuffer: imageBuffer) // Convert image buffer to CIImage
        let resizeTransform = CGAffineTransform(scaleX: CGFloat(width) / ciImage.extent.width,
                                                y: CGFloat(height) / ciImage.extent.height)
        let resizedImage = ciImage.transformed(by: resizeTransform)

        let context = CIContext() // Core Image context for rendering
        var resizedBuffer: CVPixelBuffer?

        // Create a CVPixelBuffer with the target size
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attributes as CFDictionary,
                                         &resizedBuffer)

        guard status == kCVReturnSuccess, let outputBuffer = resizedBuffer else {
            print("Failed to create resized CVPixelBuffer.")
            return imageBuffer // Fallback to the original buffer
        }
        // Render the resized image into the new CVPixelBuffer
        context.render(resizedImage, to: outputBuffer)
        return outputBuffer
    }
    private func preprocessImageBuffer(_ imageBuffer: CVImageBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let resizeTransform = CGAffineTransform(scaleX: CGFloat(width) / ciImage.extent.width,
                                                y: CGFloat(height) / ciImage.extent.height)
        let resizedImage = ciImage.transformed(by: resizeTransform)

        let context = CIContext()
        var resizedBuffer: CVPixelBuffer?

        // Create a CVPixelBuffer with the target size
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attributes as CFDictionary,
                                         &resizedBuffer)

        guard status == kCVReturnSuccess, let outputBuffer = resizedBuffer else {
            print("Failed to create resized CVPixelBuffer.")
            return nil
        }

        // Render the resized image into the new CVPixelBuffer
        context.render(resizedImage, to: outputBuffer)
        return outputBuffer
    }

    private func processTextFrame(imageBuffer: CVImageBuffer) {
          guard isTextRecognitionRunning, !isProcessingTextFrame else { return }

          isProcessingTextFrame = true

          // Create a cancelable recognition task
          textRecognitionTask = DispatchWorkItem { [weak self] in
              guard let self = self, self.isTextRecognitionRunning else { return }

              let request = VNRecognizeTextRequest { request, error in
                  guard error == nil,
                        let results = request.results as? [VNRecognizedTextObservation],
                        self.isTextRecognitionRunning else {
                      self.isProcessingTextFrame = false
                      return
                  }

                  let recognizedText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")

                  DispatchQueue.main.async {
                      self.handleRecognizedText(recognizedText)
                  }
              }

              let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])
              do {
                  try handler.perform([request])
              } catch {
                  print("Error performing text recognition: \(error.localizedDescription)")
              }

              self.isProcessingTextFrame = false
          }

          // Execute the task on a background queue
          if let task = textRecognitionTask {
              DispatchQueue.global().async(execute: task)
          }
      }

      private func handleRecognizedText(_ text: String) {
          guard !text.isEmpty else { return }

          let now = Date()

          // Announce the text if enough time has passed since the last announcement
          if now.timeIntervalSince(lastAnnouncementTime) > textRecognitionInterval {
              if text != lastRecognizedText {
                  lastRecognizedText = text
                  lastAnnouncementTime = now
                  announceMessage(text)
              }
          }
      }

      func announceMessage(_ message: String) {
          guard isTextRecognitionRunning else { return } // Skip if recognition is stopped

          let utterance = AVSpeechUtterance(string: message)
          utterance.voice = AVSpeechSynthesisVoice(language: "en-UK")
          DispatchQueue.main.async {
              self.speechSynthesizer.speak(utterance)
          }
      }
  
    func announceHelpRequestSuccess() {
        let successMessage = "Your photo and video have been uploaded successfully."
        announceMessage(successMessage)
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
        if now.timeIntervalSince(lastFrameTime) < 1.5 / Double(framesPerSecond) { return }
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
        if label != lastAnnouncedObject, now.timeIntervalSince(lastAnnouncementTime) > 1 { // Wait at least 1 second
            lastAnnouncedObject = label
            lastDetectionTime = now
            lastAnnouncementTime = now
            announceDetectedObject(label)
        }
    }
    func announceHelpRequest() {
        let utterance = AVSpeechUtterance(string: "help is requested .")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-UK")
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
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

    func capturePhotoAndVideo(completion: @escaping (Bool) -> Void) {
        let outputDirectory = FileManager.default.temporaryDirectory
        let videoOutputURL = outputDirectory.appendingPathComponent("\(UUID().uuidString).mp4")

        if !videoFileOutput.isRecording {
            videoFileOutput.startRecording(to: videoOutputURL, recordingDelegate: self)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .auto
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.videoFileOutput.isRecording {
                self.videoFileOutput.stopRecording()
            }

            DispatchQueue.global().async {
                while self.capturedPhotoData == nil || !self.isVideoSaved { /* Wait */ }
                self.uploadMedia(photoData: self.capturedPhotoData!, videoURL: videoOutputURL, completion: completion)
            }
        }
    }

    private func uploadMedia(photoData: Data, videoURL: URL, completion: @escaping (Bool) -> Void) {
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            print("Error: User not logged in")
            completion(false)
            return
        }

        // Fetch guardian UID for current VI
        fetchGuardianUID(forEmail: currentUserEmail) { guardianUID in
            guard let guardianUID = guardianUID else {
                print("Error: Guardian UID not found")
                completion(false)
                return
            }

            let storage = Storage.storage()
            let storageRef = storage.reference()

            // Store photos and videos under the guardian's UID
            let photoRef = storageRef.child("media/\(guardianUID)/photos/\(UUID().uuidString).jpg")
            let videoRef = storageRef.child("media/\(guardianUID)/videos/\(UUID().uuidString).mov")

            let dispatchGroup = DispatchGroup()
            var uploadSuccess = true

            // Upload photo
            dispatchGroup.enter()
            let photoUploadTask = photoRef.putData(photoData, metadata: nil) { _, error in
                if let error = error {
                    print("Photo upload failed: \(error.localizedDescription)")
                    uploadSuccess = false
                }
                dispatchGroup.leave()
            }

            // Upload video
            dispatchGroup.enter()
            let videoUploadTask = videoRef.putFile(from: videoURL, metadata: nil) { _, error in
                if let error = error {
                    print("Video upload failed: \(error.localizedDescription)")
                    uploadSuccess = false
                }
                dispatchGroup.leave()
            }

            dispatchGroup.notify(queue: .main) {
                completion(uploadSuccess)
            }
        }
    }
    /// Fetches the guardian UID associated with the visually impaired user's email.
    /// - Parameters:
    ///   - email: The visually impaired user's email.
    ///   - completion: A completion handler that returns the guardian's UID.
    func fetchGuardianUID(forEmail email: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()

        db.collection("Guardian")
            .whereField("visuallyImpairedEmail", isEqualTo: email)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching Guardian UID: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("No guardian found for email: \(email)")
                    completion(nil)
                    return
                }

                let guardianUID = document.documentID
                print("Guardian UID found: \(guardianUID)")
                completion(guardianUID)
            }
    }

}
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var lastShakeTime: TimeInterval = 0

    @Published var isShaking = false

    func startMonitoring() {
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            let acceleration = data.acceleration
            let magnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)

            print("Acceleration magnitude: \(magnitude)")

            if magnitude > 2.5, Date().timeIntervalSince1970 - self.lastShakeTime > 1.0 {
                print("Shake detected!")
                self.isShaking = true
                self.lastShakeTime = Date().timeIntervalSince1970

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.isShaking = false
                }
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
    }

    deinit {
        stopMonitoring()
    }
}



extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        capturedPhotoData = photo.fileDataRepresentation()
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo fileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
        } else {
            print("Video recording finished successfully.")
            isVideoSaved = true
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Process frames for object detection
        if isDetectionRunning {
            processFrame(imageBuffer: imageBuffer)
        }

        // Process frames for text recognition
        if isTextRecognitionRunning {
            processTextFrame(imageBuffer: imageBuffer)
        }
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

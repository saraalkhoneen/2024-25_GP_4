import SwiftUI
import AVFoundation
import UIKit
import CoreML
import Vision
import FirebaseStorage
import Firebase
import FirebaseAuth
import CoreLocation


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
    @State private var showUploadMessage: Bool = false

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

                HStack(spacing: 20) {
                    Button(action: {
                        if cameraManager.isDetectionRunning {
                            cameraManager.stopLiveStream()
                        } else {
                            cameraManager.startLiveStream()
                        }
                    }) {
                        Text(cameraManager.isDetectionRunning ? "Stop Detection" : "Start Detection")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .padding()
                            .background(cameraManager.isDetectionRunning ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        cameraManager.capturePhotoAndVideo { success in
                            showUploadMessage = true
                        }
                        cameraManager.announceHelpRequest() // Announce that help is requested
                        sendHelpRequest() // Send help request notification
                    }) {
                        Text("Help Request")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
            .alert(isPresented: $showUploadMessage) {
                Alert(
                    title: Text("Upload Complete"),
                    message: Text("Your photo and video have been uploaded successfully."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            cameraManager.configure()
        }
    }

    /// Sends a help request to the guardian by creating a notification in Firestore.
    func sendHelpRequest() {
        let db = Firestore.firestore()

        // Fetch the current user's email
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            print("Error: User email not found")
            return
        }

        // Fetch the user's details (first name, last name) from Firestore
        fetchUserDetails(forEmail: currentUserEmail) { userDetails in
            guard let userDetails = userDetails else {
                print("Error: User details not found")
                return
            }

            let fullName = "\(userDetails["firstName"] ?? "Unknown") \(userDetails["lastName"] ?? "User")"

            // Fetch the guardian UID associated with this visually impaired user's email
            fetchGuardianUID(forEmail: currentUserEmail) { guardianUID in
                guard let guardianUID = guardianUID else {
                    print("Error: Guardian UID not found")
                    return
                }

                // Create notification data
                let notification = [
                    "id": UUID().uuidString,
                    "title": "Help Request",
                    "details": "\(fullName) has requested help. Check the media tab for photos and videos.",
                    "date": Timestamp(date: Date())
                ] as [String: Any]

                // Dynamically create collections and documents in Firestore
                db.collection("Notifications")
                    .document(guardianUID)
                    .collection("UserNotifications")
                    .addDocument(data: notification) { error in
                        if let error = error {
                            print("Error sending notification: \(error.localizedDescription)")
                        } else {
                            print("Notification sent successfully and collections/documents were created dynamically.")
                        }
                    }
            }
        }
    }

    /// Fetches the user's details (first name, last name) based on their email.
    /// - Parameters:
    ///   - email: The email of the user.
    ///   - completion: A completion handler that returns the user's details as a dictionary.
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

                if let document = snapshot?.documents.first {
                    print("Guardian UID found: \(document.documentID)")
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
        let storage = Storage.storage()
        let storageRef = storage.reference()

        let photoRef = storageRef.child("media/photos/\(UUID().uuidString).jpg")
        let videoRef = storageRef.child("media/videos/\(UUID().uuidString).mov")

        let dispatchGroup = DispatchGroup()
        var uploadSuccess = true

        dispatchGroup.enter()
        let photoUploadTask = photoRef.putData(photoData, metadata: nil)

        photoUploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                DispatchQueue.main.async {
                    self.uploadProgress = progress.fractionCompleted * 100
                }
            }
        }

        photoUploadTask.observe(.success) { _ in
            dispatchGroup.leave()
        }

        photoUploadTask.observe(.failure) { _ in
            uploadSuccess = false
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        let videoUploadTask = videoRef.putFile(from: videoURL, metadata: nil)

        videoUploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                DispatchQueue.main.async {
                    self.uploadProgress = progress.fractionCompleted * 100
                }
            }
        }

        videoUploadTask.observe(.success) { _ in
            dispatchGroup.leave()
        }

        videoUploadTask.observe(.failure) { _ in
            uploadSuccess = false
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.uploadProgress = 0 // Reset progress
            completion(uploadSuccess)
        }
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

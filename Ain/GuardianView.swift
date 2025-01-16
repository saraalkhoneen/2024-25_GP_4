import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AVKit
import MapKit

struct GuardianView: View {
    private let db = Firestore.firestore()
    private let firstTimeLoginKey = "hasLoggedInAfterSignUp"
    
    @State private var uniqueCode: String = ""
    @State private var guardianName: String = ""
    @State private var selectedTab: Int = 2
    @State private var notifications: [Notification] = []
    @State private var isShowingCommandView = false
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.edgesIgnoringSafeArea(.all)
            
            TabView(selection: $selectedTab) {
                NotificationsView(notifications: $notifications)
                    .tabItem {
                        Image(systemName: "bell.fill")
                        Text("Notifications")
                    }
                    .tag(0)
                
                MediaView()
                    .tabItem {
                        Image(systemName: "photo.fill")
                        Text("Media")
                    }
                    .tag(1)
                
                NavigationView {
                    VStack {
                        Image("icon")
                            .resizable()
                            .frame(width: 110, height: 110)
                        
                        VStack(spacing: 10) {
                            Text("Hello \(guardianName)")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.top, 20)
                            
                            Text("Your Unique Code: \(uniqueCode)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color(hexString: "1A3E48"))
                                .cornerRadius(10)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        }
                        
                        VStack(spacing: 10) {
                            Spacer()
                            Text("Welcome to Ain")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                            
                            Text("Support your loved ones effortlessly, stay connected, and be there whenever they need you.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                            Spacer(minLength: 60)
                            
                            Button(action: {
                                isShowingCommandView = true
                            }) {
                                Text("How to get started")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hexString: "1A3E48"))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                            .sheet(isPresented: $isShowingCommandView) {
                                CommandView()
                            }
                        }
                        .navigationBarBackButtonHidden(true)
                    }
                    .background(Color(hexString: "F2F2F2").edgesIgnoringSafeArea(.all))
                    .navigationBarBackButtonHidden(true)
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(2)
                
                VITrackingView()
                    .tabItem {
                        Image(systemName: "location.fill")
                        Text("Location")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(4)
            }
        }
        .onAppear {
            fetchGuardianData()
            setupNotificationListener()
        }
    }
    
    /// Fetches the guardian's data (name, unique code) from Firestore.
    private func fetchGuardianData() {
        guard let user = Auth.auth().currentUser else {
            print("Error: User not logged in.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Guardian").document(user.uid).getDocument { document, error in
            if let error = error {
                print("Error fetching guardian data: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                guardianName = "\(data?["firstName"] as? String ?? "") \(data?["lastName"] as? String ?? "")"
                uniqueCode = data?["uniqueCode"] as? String ?? "No unique code available."
            }
        }
    }
    
    private func setupNotificationListener() {
        guard let user = Auth.auth().currentUser else {
            print("Error: User not logged in.")
            return
        }

        let db = Firestore.firestore()
        db.collection("Notifications")
            .document(user.uid)
            .collection("UserNotifications")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else {
                    print("Error: Snapshot is nil.")
                    return
                }

                print("Snapshot received. Document changes count: \(snapshot.documentChanges.count)")

                DispatchQueue.main.async {
                    for change in snapshot.documentChanges {
                        let data = change.document.data()
                        if let notification = Notification(dictionary: data) {
                            switch change.type {
                            case .added:
                                print("Notification added: \(notification.id)")
                                if !self.notifications.contains(where: { $0.id == notification.id }) {
                                    self.notifications.append(notification)
                                }
                            case .modified:
                                print("Notification modified: \(notification.id)")
                                if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
                                    self.notifications[index] = notification
                                }
                            case .removed:
                                print("Notification removed: \(notification.id)")
                                self.notifications.removeAll { $0.id == notification.id }
                            default:
                                break
                            }
                        }
                    }

                    print("Notifications updated: \(self.notifications.count) items")
                }
            }
    }

    }

    
    // MARK: - Notifications View
    struct NotificationsView: View {
        @Binding var notifications: [Notification]
        @State private var showConfirmationDialog = false
        @State private var selectedNotification: Notification?
        var body: some View {
            NavigationView {
                VStack {
                    if notifications.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "bell.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            Text("No notifications yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("When new notifications arrive, they will appear here.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        List {
                            ForEach(notifications) { notification in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(notification.title)
                                        .font(.headline)
                                    Text(notification.details)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("Date: \(formattedDate(notification.date))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 5)
                                .onTapGesture {
                                    selectedNotification = notification
                                    showConfirmationDialog = true
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Notifications")
                .confirmationDialog("Are you sure you want to delete this notification?", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        if let notification = selectedNotification {
                            deleteNotification(notification: notification)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        /// Deletes the notification from Firestore and removes it from the UI.
        /// - Parameter notification: The notification to delete.
        private func deleteNotification(notification: Notification) {
            guard let user = Auth.auth().currentUser else {
                print("Error: User not logged in.")
                return
            }

            print("Attempting to delete notification with ID: \(notification.id)")

            let db = Firestore.firestore()
            db.collection("Notifications")
                .document(user.uid)
                .collection("UserNotifications")
                .document(notification.id)
                .delete { error in
                    if let error = error {
                        print("Error deleting notification from Firestore: \(error.localizedDescription)")
                    } else {
                        print("Notification successfully deleted from Firestore.")
                        DispatchQueue.main.async {
                            self.notifications.removeAll { $0.id == notification.id }
                            print("Notifications updated locally. Remaining count: \(self.notifications.count)")
                        }
                    }
                }
        }


        
        /// Formats a date to a readable string.
        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    
    // MARK: - Media View
    struct MediaView: View {
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Media")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                        .padding(.bottom , 10)
                    
                    Spacer()
                    
                    NavigationLink(destination: PhotosView()) {
                        MediaTabView(icon: "photo", title: "Photos", color: Color(hexString: "1A3E48"))
                            .padding(.horizontal, 40) // Add padding for a wider look
                    }
                    
                    NavigationLink(destination: VideosView()) {
                        MediaTabView(icon: "video", title: "Videos", color: Color(hexString: "1A3E48"))
                            .padding(.horizontal, 40) // Add padding for a wider look
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    struct MediaTabView: View {
        let icon: String
        let title: String
        let color: Color
        
        var body: some View {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(.white)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 200, height: 200)
            .background(color)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
    
    // MARK: - Photos View
    struct PhotosView: View {
        @State private var photoURLs: [(url: URL, date: Date)] = []
        @State private var isLoading = true
        @State private var selectedPhoto: URL? = nil
        @State private var isZoomed: Bool = false
        
        var body: some View {
            ScrollView {
                VStack {
                    if isLoading {
                        ProgressView("Loading photos...")
                    } else if photoURLs.isEmpty {
                        Text("No photos available")
                            .foregroundColor(.gray)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(photoURLs, id: \.url) { item in
                                VStack {
                                    AsyncImage(url: item.url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .cornerRadius(10)
                                                .onTapGesture {
                                                    selectedPhoto = item.url
                                                    isZoomed = true
                                                }
                                        } else if phase.error != nil {
                                            Text("Error loading image")
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                    .frame(height: 150)
                                    Text("Date: \(formattedDate(item.date))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $isZoomed) {
                if let photoURL = selectedPhoto {
                    ZoomView(content: Image(uiImage: UIImage(contentsOfFile: photoURL.path) ?? UIImage()), isPresented: $isZoomed)
                }
            }
            .onAppear(perform: fetchPhotos)
        }
        
        private func fetchPhotos() {
            let storageRef = Storage.storage().reference().child("media/photos")
            storageRef.listAll { result, error in
                if let error = error {
                    print("Error fetching photos: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                guard let items = result?.items else {
                    isLoading = false
                    return
                }
                for item in items {
                    item.getMetadata { metadata, _ in
                        item.downloadURL { url, _ in
                            if let url = url, let metadata = metadata, let timeCreated = metadata.timeCreated {
                                DispatchQueue.main.async {
                                    photoURLs.append((url: url, date: timeCreated))
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
        
        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Videos View
    struct VideosView: View {
        @State private var videoURLs: [(url: URL, date: Date)] = []
        @State private var isLoading = true
        @State private var selectedVideo: URL? = nil
        @State private var isZoomed: Bool = false
        
        var body: some View {
            ScrollView {
                VStack {
                    if isLoading {
                        ProgressView("Loading videos...")
                    } else if videoURLs.isEmpty {
                        Text("No videos available")
                            .foregroundColor(.gray)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(videoURLs, id: \.url) { item in
                                VStack {
                                    VideoPlayerView(videoURL: item.url)
                                        .frame(height: 150)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                            selectedVideo = item.url
                                            isZoomed = true
                                        }
                                    Text("Date: \(formattedDate(item.date))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $isZoomed) {
                if let videoURL = selectedVideo {
                    ZoomView(content: VideoPlayer(player: AVPlayer(url: videoURL)), isPresented: $isZoomed)
                }
            }
            .onAppear(perform: fetchVideos)
        }
        
        private func fetchVideos() {
            let storageRef = Storage.storage().reference().child("media/videos")
            storageRef.listAll { result, error in
                if let error = error {
                    print("Error fetching videos: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                guard let items = result?.items else {
                    isLoading = false
                    return
                }
                for item in items {
                    item.getMetadata { metadata, _ in
                        item.downloadURL { url, _ in
                            if let url = url, let metadata = metadata, let timeCreated = metadata.timeCreated {
                                DispatchQueue.main.async {
                                    videoURLs.append((url: url, date: timeCreated))
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
        
        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    struct ZoomView<Content: View>: View {
        let content: Content
        @Binding var isPresented: Bool
        
        var body: some View {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                content
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
                    .background(Color.black)
                    .onTapGesture {
                        isPresented = false
                    }
            }
        }
    }
    
    struct VideoPlayerView: View {
        let videoURL: URL
        
        var body: some View {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
        }
    }
struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}


struct VITrackingView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var locationAnnotation: [LocationAnnotation] = []
    @State private var locationAvailable = false
    @State private var viName: String = "Location" // Default title
    @State private var lastUpdated: String = "" // Store last update time
    
    var body: some View {
        NavigationView {
            VStack {
                if locationAvailable {
                    Map(coordinateRegion: $region, annotationItems: locationAnnotation) { annotation in
                        MapPin(coordinate: annotation.coordinate, tint: .red)
                    }
                    .edgesIgnoringSafeArea(.all)
                    
                    if !lastUpdated.isEmpty {
                        Text("Last updated: \(lastUpdated)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                } else {
                    Text("Waiting for location...")
                        .foregroundColor(.gray)
                }
            }
            .onAppear(perform: fetchLocation)
            .navigationTitle(viName)
        }
    }
    
    /// Fetches the location and user information
    private func fetchLocation() {
        guard let user = Auth.auth().currentUser else {
            print("Error: User not logged in.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Locations")
            .document(user.uid)
            .addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("Error fetching location: \(error.localizedDescription)")
                    return
                }
                
                guard let data = documentSnapshot?.data() else {
                    print("No data in location document.")
                    return
                }
                
                print("Location data fetched: \(data)")
                
                // Update location
                if let latitude = data["latitude"] as? CLLocationDegrees,
                   let longitude = data["longitude"] as? CLLocationDegrees {
                    let newCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    DispatchQueue.main.async {
                        self.locationAnnotation = [LocationAnnotation(coordinate: newCoordinate)]
                        self.region.center = newCoordinate
                        self.locationAvailable = true
                    }
                }
                
                // Update last updated time
                if let timestamp = data["timestamp"] as? Timestamp {
                    let date = timestamp.dateValue()
                    DispatchQueue.main.async {
                        self.lastUpdated = formatDate(date)
                    }
                }
                
                // Update VI name directly if available
                if let firstName = data["firstName"] as? String,
                   let lastName = data["lastName"] as? String {
                    DispatchQueue.main.async {
                        self.viName = "\(firstName) \(lastName)'s Location"
                    }
                } else if let visuallyImpairedEmail = data["viEmail"] as? String {
                    // Fallback to fetch name using email
                    fetchVIName(email: visuallyImpairedEmail)
                }
            }
    }
    
    /// Fallback function to fetch VI name using email
    private func fetchVIName(email: String) {
        let db = Firestore.firestore()
        db.collection("Visually_Impaired")
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching VI name: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("No document found for email: \(email)")
                    return
                }
                
                let data = document.data()
                if let firstName = data["firstName"] as? String,
                   let lastName = data["lastName"] as? String {
                    DispatchQueue.main.async {
                        self.viName = "\(firstName) \(lastName)'s Location"
                        print("Fetched name: \(self.viName)")
                    }
                }
            }
    }
    
    /// Formats a date to a readable string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


    struct SettingsView1: View {
        var body: some View {
            Text("Settings Content")
        }
    }
    
    struct AddUserGuideView1: View {
        var body: some View {
            Text("Guide on Adding a Visually Impaired User")
        }
    }

// MARK: - Notification Model
struct Notification: Identifiable {
    let id: String
    let title: String
    let details: String
    let date: Date

    init(id: String = UUID().uuidString, title: String, details: String, date: Date) {
        self.id = id
        self.title = title
        self.details = details
        self.date = date
    }

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let title = dictionary["title"] as? String,
              let details = dictionary["details"] as? String,
              let timestamp = dictionary["date"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.details = details
        self.date = timestamp.dateValue()
    }
}
struct GuardianView_Previews: PreviewProvider {
    static var previews: some View {
        GuardianView()
    }
}

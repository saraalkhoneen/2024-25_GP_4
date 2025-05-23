import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AVKit
import MapKit
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completionHandler([])
            return
        }

        // Fetch user role to ensure correct targeting
        let db = Firestore.firestore()
        db.collection("Guardian").document(currentUser.uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user role: \(error.localizedDescription)")
                completionHandler([])
                return
            }

            if document?.exists == true {
                // Show notification only for guardians
                completionHandler([.banner, .sound])
            } else {
                // Do not show the notification
                completionHandler([])
            }
        }
    }
}




struct GuardianView: View {
    private let db = Firestore.firestore()
    private let firstTimeLoginKey = "hasLoggedInAfterSignUp"
    
    @State private var uniqueCode: String = ""
    @State private var guardianName: String = ""
    @State private var selectedTab: Int = 2
    @State private var notifications: [Notification] = []
    @State private var isShowingCommandView = false
    private static var notificationListener: ListenerRegistration?
    
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.edgesIgnoringSafeArea(.all)
            
            TabView(selection: $selectedTab) {
                NotificationsView(notifications: $notifications, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "bell.fill")
                        Text("Notifications")
                    }
                    .tag(0)
                
                MediaView()
                    .tabItem {
                        Image(systemName: "photo.fill")
                        Text("Help Requests")
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
                   
                   // Request notification permissions
                   UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                       if let error = error {
                           print("Error requesting notification permissions: \(error.localizedDescription)")
                       } else if granted {
                           print("Notification permissions granted.")
                       } else {
                           print("Notification permissions denied.")
                       }
                   }
                   
                   // Set the notification delegate and handle notification taps
                   let delegate = NotificationDelegate()
                   delegate.onNotificationTap = {
                       DispatchQueue.main.async {
                           self.selectedTab = 0 // Switch to the Notifications tab
                       }
                   }
                   UNUserNotificationCenter.current().delegate = delegate
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
    
    static func stopNotificationListener() {
        notificationListener?.remove()
        notificationListener = nil
        print("Notification listener detached.")
    }
    
    private func setupNotificationListener() {
        guard let user = Auth.auth().currentUser else {
            print("Error: User not logged in.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Guardian")
            .document(user.uid)
            .getDocument { document, error in
                if let error = error {
                    print("Error verifying user role: \(error.localizedDescription)")
                    return
                }
                
                // Check if the user is a guardian
                guard let document = document, document.exists else {
                    print("This user is not a guardian.")
                    return
                }
                
                // If the user is a guardian, listen for notifications
                self.listenForNotifications(userId: user.uid)
            }
    }
    
    // Helper function to listen for notifications
    private func listenForNotifications(userId: String) {
        let db = Firestore.firestore()
        GuardianView.notificationListener = db.collection("Notifications")
            .document(userId)
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

                DispatchQueue.main.async {
                    snapshot.documentChanges.forEach { change in
                        switch change.type {
                        case .added:
                            let data = change.document.data()
                            if let notification = Notification(dictionary: data),
                               !self.notifications.contains(where: { $0.id == notification.id }) {
                                self.notifications.insert(notification, at: 0) // Insert at the beginning
                                self.triggerLocalNotification(notification: notification)
                            }
                        case .modified:
                            let data = change.document.data()
                            if let updatedNotification = Notification(dictionary: data),
                               let index = self.notifications.firstIndex(where: { $0.id == updatedNotification.id }) {
                                self.notifications[index] = updatedNotification
                            }
                        case .removed:
                            let removedId = change.document.documentID
                            self.notifications.removeAll { $0.id == removedId }
                        }
                    }
                }
            }
    }

    private func triggerLocalNotification(notification: Notification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.details
        content.sound = .default

        let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error.localizedDescription)")
            } else {
                print("Local notification triggered successfully for \(notification.id).")
            }
        }
    }

    class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
        var onNotificationTap: (() -> Void)? // Callback to handle tab switching
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            guard let currentUser = Auth.auth().currentUser else {
                completionHandler([])
                return
            }

            // Fetch user role to ensure correct targeting
            let db = Firestore.firestore()
            db.collection("Guardian").document(currentUser.uid).getDocument { document, error in
                if let error = error {
                    print("Error fetching user role: \(error.localizedDescription)")
                    completionHandler([])
                    return
                }

                if document?.exists == true {
                    // Show notification only for guardians
                    completionHandler([.banner, .sound])
                } else {
                    // Do not show the notification
                    completionHandler([])
                }
            }
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            print("Notification tapped")
            // Call the callback to handle tab switching
            onNotificationTap?()
            completionHandler()
        }
    }

    // MARK: - Notification View
    struct NotificationsView: View {
        @Binding var notifications: [Notification]
        @Binding var selectedTab: Int // Pass the selectedTab binding to switch tabs
        @State private var isEditing: Bool = false // Toggles selection mode
        @State private var selectedNotifications: Set<String> = []
        @State private var isSelectAll: Bool = false
        
        @State private var showInfoAlert = false

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
                        VStack {
                            // Display "Select All" toggle only in editing mode
                            if isEditing {
                                Toggle("Select All", isOn: $isSelectAll)
                                    .padding(.horizontal)
                                    .onChange(of: isSelectAll) { newValue in
                                        if newValue {
                                            selectedNotifications = Set(notifications.map { $0.id })
                                        } else {
                                            selectedNotifications.removeAll()
                                        }
                                    }
                            }
                            
                            
                                                   // List Notifications (sorted by last arrival)
                                                   List {
                                                       ForEach(notifications.sorted(by: { $0.date > $1.date })) { notification in
                                                           HStack {
                                                               if isEditing {
                                                                   Image(systemName: selectedNotifications.contains(notification.id) ? "checkmark.square.fill" : "square")
                                                                       .onTapGesture {
                                                                           toggleSelection(for: notification.id)
                                                                       }
                                                               }
                                                               
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
                                                           }
                                                       }
                                                   }
                            
                            // Clear Selected Button (only appears in editing mode)
                            if isEditing {
                                Button(action: deleteSelectedNotifications) {
                                    Text("Clear Selected")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(selectedNotifications.isEmpty ? Color.gray : Color.red)
                                        .cornerRadius(8)
                                        .disabled(selectedNotifications.isEmpty)
                                }
                                .padding()
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Text("Notifications")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hexString: "3C6E71"))

                            Button(action: {
                                showInfoAlert.toggle()
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(Color(hexString: "3C6E71"))
                                    .font(.title2)
                            }
                            .alert(isPresented: $showInfoAlert) {
                                Alert(
                                    title: Text("Info"),
                                    message: Text("Notifications appear here when they arrive."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                    }
                }

                .navigationBarItems(trailing: Button(isEditing ? "Done" : "Select") {
                    isEditing.toggle()
                    if !isEditing {
                        // Reset selection when exiting editing mode
                        selectedNotifications.removeAll()
                        isSelectAll = false
                    }
                })
            }
        }
        
        /// Handles the tap on a notification
        private func handleNotificationTap(notification: Notification) {
            print("Notification tapped: \(notification.title)")
            // Redirect to the Media tab
            selectedTab = 1 // Set to the Media tab index
        }
        
        /// Toggles the selection state of a notification
        private func toggleSelection(for id: String) {
            if selectedNotifications.contains(id) {
                selectedNotifications.remove(id)
            } else {
                selectedNotifications.insert(id)
            }
            isSelectAll = selectedNotifications.count == notifications.count
        }
        
        /// Deletes the selected notifications
        private func deleteSelectedNotifications() {
            guard let user = Auth.auth().currentUser else {
                print("Error: User not logged in.")
                return
            }
            
            let db = Firestore.firestore()
            let group = DispatchGroup()
            
            for notificationId in selectedNotifications {
                group.enter()
                db.collection("Notifications")
                    .document(user.uid)
                    .collection("UserNotifications")
                    .document(notificationId)
                    .delete { error in
                        if let error = error {
                            print("Error deleting notification \(notificationId): \(error.localizedDescription)")
                        } else {
                            DispatchQueue.main.async {
                                notifications.removeAll { $0.id == notificationId }
                            }
                        }
                        group.leave()
                    }
            }
            
            group.notify(queue: .main) {
                selectedNotifications.removeAll()
                isSelectAll = false
            }
        }
        
        /// Formats a date to a readable string
        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }


    // MARK: - Media View
    struct MediaView: View {
        @State private var selectedTab: String = "Photos" // Default selection
        @State private var showInfoAlert = false

        var body: some View {
            NavigationView {
                VStack(spacing: 5) {
                    // Title and Description
                    HStack(spacing: 8) {
                        Text("Help Requests")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hexString: "3C6E71"))

                        Button(action: {
                            showInfoAlert.toggle()
                        }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(Color(hexString: "3C6E71"))
                                .font(.title2)
                        }
                        .alert(isPresented: $showInfoAlert) {
                            Alert(
                                title: Text("Info"),
                                message: Text("Media such as videos and pictures will appear here when uploaded."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                    .padding(.top, 10)

                    // Segmented Control for Photos and Videos
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = "Photos" }) {
                            Text("Photos")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTab == "Photos" ? Color(hexString: "3c6e71") : Color.gray.opacity(0.2))
                                .foregroundColor(selectedTab == "Photos" ? .white : .black)
                                .cornerRadius(10, corners: [.topLeft, .bottomLeft])
                        }
                       Button(action: { selectedTab = "Videos" }) {
                            Text("Videos")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTab == "Videos" ? Color(hexString: "3c6e71") : Color.gray.opacity(0.2))
                                .foregroundColor(selectedTab == "Videos" ? .white : .black)
                                .cornerRadius(10, corners: [.topRight, .bottomRight]) }}
                    .padding(.horizontal)
                    Spacer().frame(height: 5) // Reduced gap
                    // Display PhotosView or VideosView based on selected tab
                    if selectedTab == "Photos" {
                        PhotosView() } else {
                        VideosView() }
                    Spacer()
                }
                .background(Color.white.edgesIgnoringSafeArea(.all))
                
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
    
    struct PhotosView: View {
        @State private var photoURLs: [(url: IdentifiableURL, date: Date)] = [] // Updated to use IdentifiableURL
        @State private var isLoading = true
        @State private var selectedPhoto: IdentifiableURL? = nil // Updated to use IdentifiableURL
        @State private var isEditing: Bool = false
        @State private var selectedPhotos: Set<URL> = []
        @State private var selectAllPhotos: Bool = false

        var body: some View {
            VStack {
                if isLoading {
                    ProgressView("Loading photos...")
                } else if photoURLs.isEmpty {
                    Text("No photos available")
                        .foregroundColor(.gray)
                } else {
                    if isEditing {
                        Toggle("Select All", isOn: $selectAllPhotos)
                            .padding(.horizontal)
                            .onChange(of: selectAllPhotos) { newValue in
                                if newValue {
                                    selectedPhotos = Set(photoURLs.map { $0.url.url })
                                } else {
                                    selectedPhotos.removeAll()
                                }
                            }
                    }
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(photoURLs, id: \.url.id) { item in
                                VStack {
                                    AsyncImage(url: item.url.url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .cornerRadius(10)
                                                .onTapGesture {
                                                    selectedPhoto = item.url // Trigger full-screen mode
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
            .sheet(item: $selectedPhoto) { photo in
                FullScreenImageView(imageURL: photo.url) // Show full-screen image
            }
            .onAppear(perform: fetchPhotos) // Calls fetchPhotos when the view appears
        }

        private func fetchPhotos() {
            guard let user = Auth.auth().currentUser else {
                print("Error: User not logged in")
                isLoading = false
                return
            }

            let storageRef = Storage.storage().reference().child("media/\(user.uid)/photos")
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
                                    let identifiableURL = IdentifiableURL(url: url) // Wrap URL
                                    self.photoURLs.append((url: identifiableURL, date: timeCreated))
                                    self.photoURLs.sort { $0.date > $1.date } // Sort latest on top
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
    struct IdentifiableURL: Identifiable {
        let id = UUID() // Unique identifier for each item
        let url: URL
    }
    struct FullScreenImageView: View {
        let imageURL: URL

        var body: some View {
            VStack {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .edgesIgnoringSafeArea(.all)
                    } else if phase.error != nil {
                        Text("Error loading image")
                    } else {
                        ProgressView()
                    }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }

    
    struct ZoomableImageView: UIViewRepresentable {
        let image: UIImage
        
        func makeUIView(context: Context) -> UIScrollView {
            let scrollView = UIScrollView()
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 4.0
            scrollView.delegate = context.coordinator
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])
            
            return scrollView
        }
        
        func updateUIView(_ uiView: UIScrollView, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
        
        class Coordinator: NSObject, UIScrollViewDelegate {
            func viewForZooming(in scrollView: UIScrollView) -> UIView? {
                return scrollView.subviews.first
            }
        }
    }
    
    // MARK: - Videos View
    struct VideosView: View {
        @State private var videoURLs: [(url: URL, date: Date)] = [] // List of videos
        @State private var isLoading = true
        @State private var isEditing: Bool = false
        @State private var selectedVideos: Set<URL> = []
        @State private var selectAllVideos: Bool = false

        var body: some View {
            VStack {
                if isLoading {
                    ProgressView("Loading videos...")
                } else if videoURLs.isEmpty {
                    Text("No videos available")
                        .foregroundColor(.gray)
                } else {
                    if isEditing {
                        Toggle("Select All", isOn: $selectAllVideos)
                            .padding(.horizontal)
                            .onChange(of: selectAllVideos) { newValue in
                                if newValue {
                                    selectedVideos = Set(videoURLs.map { $0.url })
                                } else {
                                    selectedVideos.removeAll()
                                }
                            }
                    }
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(videoURLs, id: \.url) { item in
                                VStack {
                                    ZStack(alignment: .topTrailing) {
                                        VideoPlayer(player: AVPlayer(url: item.url))
                                            .frame(height: 150)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                            )

                                        if isEditing {
                                            Button(action: {
                                                toggleSelection(for: item.url)
                                            }) {
                                                Image(systemName: selectedVideos.contains(item.url) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(selectedVideos.contains(item.url) ? .blue : .gray)
                                            }
                                            .padding(10)
                                        }
                                    }
                                    Text("Date: \(formattedDate(item.date))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                    }
                    if isEditing && !selectedVideos.isEmpty {
                        Button(action: deleteSelectedVideos) {
                            Text("Delete Selected")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
            }
            .onAppear(perform: fetchVideos)
        }

        private func toggleSelection(for url: URL) {
            if selectedVideos.contains(url) {
                selectedVideos.remove(url)
            } else {
                selectedVideos.insert(url)
            }
            selectAllVideos = selectedVideos.count == videoURLs.count
        }

        private func deleteSelectedVideos() {
            guard let user = Auth.auth().currentUser else { return }

            let group = DispatchGroup()
            for videoURL in selectedVideos {
                group.enter()
                let storageRef = Storage.storage().reference(forURL: videoURL.absoluteString)
                storageRef.delete { error in
                    if error == nil {
                        videoURLs.removeAll { $0.url == videoURL }
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                selectedVideos.removeAll()
                selectAllVideos = false
            }
        }
    

        private func fetchVideos() {
            guard let user = Auth.auth().currentUser else {
                print("Error: User not logged in")
                isLoading = false
                return
            }

            let storageRef = Storage.storage().reference().child("media/\(user.uid)/videos")
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
                                    self.videoURLs.append((url: url, date: timeCreated))
                                    self.videoURLs.sort { $0.date > $1.date } // Sort latest on top
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



    struct FullScreenVideoPlayer: View {
        let videoURL: URL
        @Binding var isPresented: Bool

        @State private var player: AVPlayer? = nil // AVPlayer instance for playback

        var body: some View {
            ZStack(alignment: .topLeading) {
                // VideoPlayer initialized with the player
                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        // Initialize and start playback
                        player = AVPlayer(url: videoURL)
                        player?.play()
                    }
                    .onDisappear {
                        // Stop playback when the view disappears
                        player?.pause()
                        player = nil
                    }

                // Close button
                Button(action: {
                    isPresented = false // Dismiss full-screen mode
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
    }




    struct ZoomableVideoPlayerView: UIViewRepresentable {
        let videoURL: URL

        func makeUIView(context: Context) -> UIScrollView {
            let scrollView = UIScrollView()
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 4.0
            scrollView.delegate = context.coordinator

            // Check for audio track
            if let asset = AVAsset(url: videoURL) as? AVURLAsset,
               asset.tracks(withMediaType: .audio).isEmpty {
                print("Video has no audio track")
            } else {
                print("Video has an audio track")
            }

            let player = AVPlayer(url: videoURL)
            let playerItem = AVPlayerItem(url: videoURL)
            player.replaceCurrentItem(with: playerItem)

            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspect

            let containerView = UIView()
            playerLayer.frame = containerView.bounds
            containerView.layer.addSublayer(playerLayer)

            scrollView.addSubview(containerView)

            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])

            player.play() // Play video automatically

            return scrollView
        }

        func updateUIView(_ uiView: UIScrollView, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator: NSObject, UIScrollViewDelegate {
            func viewForZooming(in scrollView: UIScrollView) -> UIView? {
                return scrollView.subviews.first
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
        @State private var showInfoAlert = false

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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showInfoAlert.toggle()
                        }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(Color(hexString: "3C6E71"))
                                .font(.title2)
                        }
                        .alert(isPresented: $showInfoAlert) {
                            Alert(
                                title: Text("Info"),
                                message: Text("This page shows the last known location of the visually impaired user."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                }

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


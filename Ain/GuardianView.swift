import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AVKit

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

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "details": details,
            "date": Timestamp(date: date)
        ]
    }

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let title = dictionary["title"] as? String,
              let details = dictionary["details"] as? String,
              let timestamp = dictionary["date"] as? Timestamp else { return nil }

        self.id = id
        self.title = title
        self.details = details
        self.date = timestamp.dateValue()
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

                LocationView()
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
        }
    }

    private func fetchGuardianData() {
        if let user = Auth.auth().currentUser {
            db.collection("Guardian").document(user.uid).getDocument { (document, error) in
                if let document = document, document.exists {
                    uniqueCode = document.data()? ["uniqueCode"] as? String ?? "No unique code found."
                    guardianName = [document.data()? ["firstName"], document.data()? ["lastName"]].compactMap { $0 as? String }.joined(separator: " ")
                } else {
                    uniqueCode = "Error fetching code: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        } else {
            uniqueCode = "User not logged in."
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @Binding var notifications: [Notification]

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
                    List(notifications) { notification in
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
                    }
                }
            }
            .navigationTitle("Notifications")
            .padding(.bottom, 30)
            .onAppear {
                fetchNotifications()
            }
        }
    }

    private func fetchNotifications() {
        let db = Firestore.firestore()
        db.collection("Notifications").order(by: "date", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching notifications: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No notifications found.")
                return
            }
            notifications = documents.compactMap { Notification(dictionary: $0.data()) }
        }
    }

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

struct LocationView1: View {
    var body: some View {
        Text("Location Content")
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

struct GuardianView_Previews: PreviewProvider {
    static var previews: some View {
        GuardianView()
    }
}

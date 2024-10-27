import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// Model for Notification
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
    
    // Convert to dictionary for Firestore storage
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "details": details,
            "date": Timestamp(date: date)
        ]
    }
    
    // Initialize from Firestore dictionary
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
    private let db = Firestore.firestore() // Firestore reference
    private let firstTimeLoginKey = "hasLoggedInAfterSignUp"

    @State private var uniqueCode: String = ""
    @State private var guardianName: String = ""
    @State private var selectedTab: Int = 2
    @State private var notifications: [Notification] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.edgesIgnoringSafeArea(.all)
            
            TabView(selection: $selectedTab) {
                
                NotificationsView1(notifications: $notifications)
                    .tabItem {
                        Image(systemName: "bell.fill")
                        Text("Notifications")
                    }
                    .tag(0)
                    .background(Color(hexString: "F2F2F2").edgesIgnoringSafeArea(.all))
                
                MediaView1()
                    .tabItem {
                        Image(systemName: "photo.fill")
                        Text("Media")
                    }
                    .tag(1)
                    .background(Color(hexString: "F2F2F2").edgesIgnoringSafeArea(.all))
                
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
                            
                            NavigationLink(destination: AddUserGuideView1()) {
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
                    .background(Color(hexString: "F2F2F2").edgesIgnoringSafeArea(.all))
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(4)
                    .background(Color(hexString: "F2F2F2").edgesIgnoringSafeArea(.all))
                
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
                    uniqueCode = document.data()?["uniqueCode"] as? String ?? "No unique code found."
                    guardianName = [document.data()?["firstName"], document.data()?["lastName"]].compactMap { $0 as? String }.joined(separator: " ")
                } else {
                    uniqueCode = "Error fetching code: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        } else {
            uniqueCode = "User not logged in."
        }
    }

// Placeholder views
struct MediaView1: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Media")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .foregroundColor(Color(hexString: "3C6E71"))
                
                Spacer()
                
                // Message indicating no media available
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    
                    Text("No videos or pictures yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("When the media uploaded, it will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .background(Color(hexString: "F2F2F2").edgesIgnoringSafeArea(.all))
        }
    }
    }}
struct AddUserGuideView1: View { var body: some View { Text("Guide on Adding a Visually Impaired User") } }
struct LocationView1: View { var body: some View { Text("Location Content") } }
struct SettingsView1: View { var body: some View { Text("Settings Content") } }
struct NotificationsView1: View {
    @Binding var notifications: [Notification]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Notifications")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .foregroundColor(Color(hexString: "3C6E71"))
                
                Spacer()
                
                if notifications.isEmpty {
                    // Display placeholder when there are no notifications
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
                    .padding(.top, 50)
                } else {
                    // Display list of notifications if there are any
                    List(notifications) { notification in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(notification.title)
                                .font(.headline)
                                .foregroundColor(.black)
                            
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
                
                Spacer()
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




    struct GuardianView_Previews: PreviewProvider {
    static var previews: some View {
        GuardianView()
    }
}


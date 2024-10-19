import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
struct GuardianView: View {
    @State private var uniqueCode: String = "" // Holds the fetched unique code
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(hexString: "3C6E71")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Top right gear icon (settings)
                    HStack {
                        Spacer()
                        // Navigation to SettingsView
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .padding(.trailing, 20)
                                .padding(.top, 20)
                        }
                    }
                    // Unique Code Display
                                        Text("Your Unique Code: \(uniqueCode)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.black.opacity(0.7))
                                            .cornerRadius(10)
                                            .padding(.horizontal, 20)
                    // Main Grid of Boxes
                    VStack(spacing: 20) {
                        HStack(spacing: 15) {
                            // Pictures & Videos
                            BoxView(
                                title: "PICTURES&\nVIDEOS",
                                backgroundColor: Color(hexString: "D95F4B"),
                                icon: Image(systemName: "cloud.fill")
                            )
                            
                            // Navigation to LocationView
                            NavigationLink(destination: LocationView()) {
                                BoxView(
                                    title: "LOCATION",
                                    backgroundColor: Color(hexString: "1A3E48"),
                                    icon: Image(systemName: "location.fill")
                                )
                            }
                        }
                        
                        // Navigation to CommandView
                        NavigationLink(destination: CommandView()) {
                            BoxView(
                                title: "COMMAND LIST",
                                backgroundColor: Color(hexString: "EAE2D6"),
                                icon: Image(systemName: "speaker.wave.2.fill")
                            )
                            .frame(height: 160)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Notifications Box
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Notifications")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                            Text("3")
                                .padding(5)
                                .background(Color(hexString: "3C6E71"))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 10) {
                            NotificationView(title: "Picture", time: "from 8 pm")
                            NotificationView(title: "Video", time: "from 8 pm")
                            NotificationView(title: "SOS", time: "from 8 pm")
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                            fetchUniqueCode() // Call the fetch function on appear
                        }
        }
    }
    
    private func fetchUniqueCode() {
        let db = Firestore.firestore()

        // Fetching the currently logged-in user ID
        if let user = Auth.auth().currentUser {
            let userId = user.uid // Get the unique ID of the currently logged-in user

            db.collection("Guardian").document(userId).getDocument { (document, error) in
                if let document = document, document.exists {
                    if let code = document.data()?["uniqueCode"] as? String {
                        uniqueCode = code // Update the unique code
                    } else {
                        uniqueCode = "No unique code found."
                    }
                } else {
                    uniqueCode = "Error fetching code: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        } else {
            uniqueCode = "User not logged in."
        }
    }


}

// BoxView for the main grid boxes
struct BoxView: View {
    var title: String
    var backgroundColor: Color
    var icon: Image
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            backgroundColor
                .cornerRadius(15)
                .frame(height: 130)
                .shadow(radius: 5)
            
            VStack(alignment: .leading) {
                icon
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .padding([.top, .trailing], 10)
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .bold()
                    .padding(.leading)
                    .padding(.bottom, 10)
            }
            .padding()
        }
    }
}

// NotificationView for each notification
struct NotificationView: View {
    var title: String
    var time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text("Thu")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(time)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "trash.fill")
                .foregroundColor(.gray)
                .padding()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct GuardianView_Previews: PreviewProvider {
    static var previews: some View {
        GuardianView()
    }
}

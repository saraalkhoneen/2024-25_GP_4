import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// AppState to manage logged-in state
class AppState: ObservableObject {
    static let shared = AppState()
    @Published var isLoggedIn = true
}

// Settings View
struct SettingsView: View {
    @State private var userName: String = "Loading..."
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showPrivacyPolicy = false
    @State private var showTermsConditions = false
    @State private var showAboutUs = false
    @State private var showChangePassword = false
    @State private var navigateToContentView = false  // New state for navigation
    @State private var showActionSheet = false // State for action sheet confirmation

    var body: some View {
        NavigationView {
            ZStack {
                Color(hexString: "F2F2F2")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Text("Settings")
                            .font(.title2)
                            .foregroundColor(Color(hexString: "3C6E71"))
                            .fontWeight(.bold)
                            .padding(.top, 50)
                        Spacer()
                    }
                    
                    VStack {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .foregroundColor(Color(hexString: "3C6E71"))
                            Text(userName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding()
                        .background(Color(hexString: "F2F2F2"))
                        .cornerRadius(15)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Account Settings")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading)
                        
                        Button(action: { showChangePassword = true }) {
                            HStack {
                                Text("Change password")
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(hexString: "F2F2F2"))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showChangePassword) {
                            ChangePasswordView()
                        }
                    }
                    .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("More")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading)
                        
                        Button(action: { showAboutUs.toggle() }) {
                            HStack {
                                Text("About us")
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(hexString: "F2F2F2"))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showAboutUs) {
                            AboutUsView()
                        }
                        
                        Button(action: { showPrivacyPolicy.toggle() }) {
                            HStack {
                                Text("Privacy policy")
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(hexString: "F2F2F2"))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showPrivacyPolicy) {
                            PrivacyPolicyView()
                        }
                        
                        Button(action: { showTermsConditions.toggle() }) {
                            HStack {
                                Text("Terms and conditions")
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(hexString: "F2F2F2"))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showTermsConditions) {
                            TermsConditionsView()
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // "Go to Content" Button using Action Sheet
                    Button(action: {
                        showActionSheet = true // Show action sheet on tap
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.red)
                            .background(Color(hexString: "F2F2F2"))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                    }
                    .actionSheet(isPresented: $showActionSheet) {
                        ActionSheet(
                            title: Text("Are you sure?"),
                            message: Text("By continuing, you will be signed out of your account"),
                            buttons: [
                                .default(Text("Yes, Sign out")) {
                                    navigateToContentView = true // Trigger the full screen cover
                                },
                                .cancel()
                            ]
                        )
                    }
                    .fullScreenCover(isPresented: $navigateToContentView) {
                        ContentView().navigationBarBackButtonHidden(true)
                    }


                                     // Hidden NavigationLink to trigger navigation
                                     NavigationLink(
                                         destination: ContentView().navigationBarBackButtonHidden(true),
                                         isActive: $navigateToContentView
                                     ) {
                                         EmptyView()
                                     }
                                     
                                     Spacer()
                                 }
                                 .padding(.top, -20)
                             }
                             .navigationBarBackButtonHidden(true)
                             .onAppear {
                                 fetchUserData()
                             }
                         }
                     }
                     
    private func fetchUserData() {
        let db = Firestore.firestore()
        guard let user = Auth.auth().currentUser else {
            userName = "User not logged in."
            return
        }

        // Check if user is a Guardian
        db.collection("Guardian").document(user.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                let firstName = document.data()?["firstName"] as? String ?? ""
                let lastName = document.data()?["lastName"] as? String ?? ""
                userName = "\(firstName) \(lastName)"
            } else {
                // If not a Guardian, check if user is Visually Impaired
                db.collection("VisuallyImpaired").document(user.uid).getDocument { (document, error) in
                    if let document = document, document.exists {
                        let firstName = document.data()?["firstName"] as? String ?? ""
                        let lastName = document.data()?["lastName"] as? String ?? ""
                        userName = "\(firstName) \(lastName)"
                    } else {
                        userName = "Error fetching name: \(error?.localizedDescription ?? "User type not found")"
                    }
                }
            }
        }
    }

                 }

    // private func signOut() {
    //     let auth = Auth.auth()
    //     do {
    //         // Perform Firebase sign out
    //         try auth.signOut()
    //
    //         // Update UserDefaults to indicate the user is no longer signed in
    //         let defaults = UserDefaults.standard
    //         defaults.set(false, forKey: "isUserSignedIn")
    //
    //         // Set AppState to logged out to manage the navigation state
    //         AppState.shared.isLoggedIn = false
    //
    //         // Optionally dismiss the current view if needed
    //         self.presentationMode.wrappedValue.dismiss()
    //
    //     } catch let signOutError as NSError {
    //         // Handle any sign-out error and show an alert
    //         alertMessage = "Error signing out: \(signOutError.localizedDescription)"
    //         showAlert = true
    //     }
    // }

struct ChangePasswordView: View {
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Change Password")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 30)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: resetPassword) {
                Text("Send Reset Password Email")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "D95F4B"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email."
            showAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                alertMessage = error.localizedDescription
            } else {
                alertMessage = "Password reset email sent. Please check your inbox."
            }
            showAlert = true
        }
    }
}

// Additional Views
struct AboutUsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("About Us")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Our Mission")
                    .font(.headline)
                    .padding(.top, 10)
                Text("Our mission is to create applications that enhance the lives of our users, focusing on innovation, quality, and user satisfaction.")
                    .padding(.horizontal)

                Text("Our Vision")
                    .font(.headline)
                    .padding(.top, 10)
                Text("We envision a future where technology seamlessly integrates into daily life, making tasks simpler and more enjoyable.")
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("About Us")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Introduction")
                    .font(.headline)
                    .padding(.top, 10)
                Text("This privacy policy outlines how user information is collected, used, and safeguarded. We prioritize transparency and are committed to protecting user data in compliance with applicable laws.")
                    .padding(.horizontal)

                Text("Data Collection")
                    .font(.headline)
                    .padding(.top, 10)
                Text("We collect data to provide better services to our users. Information collected includes, but is not limited to, personal details, usage data, and device information.")
                    .padding(.horizontal)

                Text("Data Usage")
                    .font(.headline)
                    .padding(.top, 10)
                Text("Collected data is used to improve our services, enhance user experience, and provide personalized content. We may also use data for analytics, troubleshooting, and support.")
                    .padding(.horizontal)

                Text("Data Protection")
                    .font(.headline)
                    .padding(.top, 10)
                Text("We implement industry-standard security measures to protect user data. Access to data is limited to authorized personnel, and we regularly review our data protection practices.")
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}


struct TermsConditionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Terms and Conditions")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Introduction")
                    .font(.headline)
                    .padding(.top, 10)
                Text("These terms and conditions govern your use of this application. By using the app, you agree to comply with and be bound by these terms.")
                    .padding(.horizontal)

                Text("User Responsibilities")
                    .font(.headline)
                    .padding(.top, 10)
                Text("Users are expected to use the app responsibly and abide by all rules. Any misuse of the app, including unauthorized access, modification, or distribution, is strictly prohibited.")
                    .padding(.horizontal)

                Text("Account Security")
                    .font(.headline)
                    .padding(.top, 10)
                Text("Users are responsible for maintaining the confidentiality of their account information. We are not liable for any loss or damage resulting from unauthorized access to your account.")
                    .padding(.horizontal)

                Text("Limitation of Liability")
                    .font(.headline)
                    .padding(.top, 10)
                Text("We are not liable for any damages resulting from the use or inability to use the app. Users accept that the app is provided as-is, without any warranties.")
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Terms and Conditions")
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

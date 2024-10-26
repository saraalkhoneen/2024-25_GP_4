import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @State private var isShowingSignOutAlert = false
    @State private var userName: String = "Loading..."
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showPrivacyPolicy = false
    @State private var showTermsConditions = false
    @State private var showAboutUs = false
    @State private var showChangePassword = false
    @Environment(\.presentationMode) var presentationMode

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
                    
                    Button(action: {
                        isShowingSignOutAlert = true
                    }) {
                        HStack {
                            Text("Sign out")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color(hexString: "F2F2F2"))
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    }
                    .alert(isPresented: $isShowingSignOutAlert) {
                        Alert(
                            title: Text("Are you sure you want to sign out?"),
                            message: Text("You will be logged out of your account."),
                            primaryButton: .destructive(Text("Sign out")) {
                                signOut()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                    Spacer()
                }
                .padding(.top, -20)
            }
            .navigationBarItems(leading: EmptyView())
            .navigationBarBackButtonHidden(true)
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                fetchUserData()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func fetchUserData() {
        let db = Firestore.firestore()
        if let user = Auth.auth().currentUser {
            db.collection("Guardian").document(user.uid).getDocument { (document, error) in
                if let document = document, document.exists {
                    let firstName = document.data()?["firstName"] as? String ?? ""
                    let lastName = document.data()?["lastName"] as? String ?? ""
                    userName = "\(firstName) \(lastName)"
                } else {
                    userName = "Error fetching name: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        } else {
            userName = "User not logged in."
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            presentationMode.wrappedValue.dismiss()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            alertMessage = "Error signing out: \(signOutError.localizedDescription)"
            showAlert = true
        }
    }
}

// Change Password View
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
                Text("This is the About Us page where information about the application and its purpose is shared. Additional details on the team, mission, and vision can be added here.")
                    .padding(.horizontal)
            }
            .padding()
        }
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
                Text("The privacy policy outlines how user information is collected, used, and safeguarded. It provides transparency and details on data privacy practices.")
                    .padding(.horizontal)
            }
            .padding()
        }
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
                Text("These are the terms and conditions for using the application. Users are expected to abide by the outlined rules and regulations.")
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

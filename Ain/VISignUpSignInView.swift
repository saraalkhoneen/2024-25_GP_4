import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct VISignUpSignInView: View {
    @State private var selectedTab: String = "Sign Up"
    
    var body: some View {
        NavigationView {
            VStack {
                TopCurveShape()
                    .fill(Color(hexString: "3C6E71"))
                    .frame(height: 40)
                    .edgesIgnoringSafeArea(.top)
                
                Text("Visually Impaired")
                    .font(.headline)
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.top, 10)
                
                HStack(spacing: 0) {
                    Button(action: { selectedTab = "Sign Up" }) {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTab == "Sign Up" ? Color(hexString: "3c6e71") : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTab == "Sign Up" ? .white : .black)
                            .cornerRadius(10, corners: [.topLeft, .bottomLeft])
                    }
                    
                    Button(action: { selectedTab = "Sign In" }) {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTab == "Sign In" ? Color(hexString: "3c6e71") : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTab == "Sign In" ? .white : .black)
                            .cornerRadius(10, corners: [.topRight, .bottomRight])
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer().frame(height: 40)
                
                if selectedTab == "Sign Up" {
                    ViSignUpView(selectedTab: $selectedTab)
                } else {
                    ViSignInView()
                }
                
                Spacer()
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
        }
    }
}

// Step-by-Step Sign-Up Process for Visually Impaired
struct ViSignUpView: View {
    @Binding var selectedTab: String
    @State private var step = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var uniqueCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var signUpSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            if step == 1 {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                        Text("First Name").font(.subheadline).foregroundColor(.gray)
                        Text("*").foregroundColor(.red)
                    }
                    CustomTextField(placeholder: "First Name", text: $firstName)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                        Text("Last Name").font(.subheadline).foregroundColor(.gray)
                        Text("*").foregroundColor(.red)
                    }
                    CustomTextField(placeholder: "Last Name", text: $lastName)
                }
                .padding(.horizontal)
                
                Button(action: validateStep1Inputs) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "D95F4B"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading)
                
            } else if step == 2 {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                        Text("Email").font(.subheadline).foregroundColor(.gray)
                        Text("*").foregroundColor(.red)
                    }
                    CustomTextField(placeholder: "Email", text: $email)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                        Text("Unique Code").font(.subheadline).foregroundColor(.gray)
                        Text("*").foregroundColor(.red)
                    }
                    CustomTextField(placeholder: "Unique Code", text: $uniqueCode)
                }
                .padding(.horizontal)
                
                HStack(spacing: 10) {
                    Button(action: { step = 1 }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "5a5a5a"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    Button(action: validateStep2Inputs) {
                        HStack {
                            Text("Sign Up")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "D95F4B"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding(.horizontal)
               .overlay(loadingOverlay)
               .overlay(
                   Group {
                       if signUpSuccess {
                           VStack(spacing: 10) {
                               Image(systemName: "checkmark.circle.fill")
                                   .font(.system(size: 60))
                                   .foregroundColor(.green)
                               Text("Registration Successful!")
                                   .font(.headline)
                                   .foregroundColor(.white)
                               Text("Please check your inbox for email verification,\nthen sign in.")
                                   .multilineTextAlignment(.center)
                                   .foregroundColor(.white)
                                   .padding(.horizontal)
                           }
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                           .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                       }
                   }
               )
           }
    
    private func validateStep1Inputs() {
        if firstName.isEmpty && lastName.isEmpty {
            alertMessage = "Please enter both your first and last names."
            showAlert = true
        } else if firstName.isEmpty {
            alertMessage = "Please enter your first name."
            showAlert = true
        } else if firstName.count < 2 {
            alertMessage = "First name must be at least 2 letters."
            showAlert = true
        } else if lastName.isEmpty {
            alertMessage = "Please enter your last name."
            showAlert = true
        } else if lastName.count < 2 {
            alertMessage = "Last name must be at least 2 letters."
            showAlert = true
        } else {
            step = 2
        }
    }


    
    private func validateStep2Inputs() {
        if email.isEmpty {
            alertMessage = "Please enter your email."
            showAlert = true
        } else if !isValidEmail(email) {
            alertMessage = "Please enter a valid email address."
            showAlert = true
        } else if uniqueCode.isEmpty {
            alertMessage = "Please enter the unique code."
            showAlert = true
        } else {
            validateGuardianCodeAndEmail()
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func validateGuardianCodeAndEmail() {
        isLoading = true
        let guardianCollection = Firestore.firestore().collection("Guardian")
        
        guardianCollection
            .whereField("uniqueCode", isEqualTo: uniqueCode.uppercased())
            .getDocuments { snapshot, error in
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "Error accessing the database: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self.alertMessage = "The unique code entered is invalid."
                    self.showAlert = true
                    return
                }
                
                let matchingDocument = documents.first { $0.data()["visuallyImpairedEmail"] as? String == self.email }
                
                guard let document = matchingDocument else {
                    self.alertMessage = "The email does not match the registered email for this unique code."
                    self.showAlert = true
                    return
                }
                
                if let viID = document.data()["VI_ID"] as? String, !viID.isEmpty {
                    self.alertMessage = "This unique code is already linked with another user."
                    self.showAlert = true
                    return
                }
                
                self.registerUser(guardianDocID: document.documentID)
            }
    }

    private func registerUser(guardianDocID: String) {
           isLoading = true
           Auth.auth().createUser(withEmail: email, password: "DefaultPass123!") { result, error in
               self.isLoading = false
               if let error = error {
                   self.alertMessage = error.localizedDescription
                   self.showAlert = true
               } else if let user = result?.user {
                   user.sendEmailVerification { error in
                       if let error = error {
                           self.alertMessage = "Failed to send verification email: \(error.localizedDescription)"
                           self.showAlert = true
                       } else {
                           self.signUpSuccess = true // Show success overlay
                           DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                               self.selectedTab = "Sign In"
                               self.signUpSuccess = false
                           }
                           self.saveUserToFirestore(user: user, guardianDocID: guardianDocID)
                       }
                   }
               }
           }
       }
    
    private func saveUserToFirestore(user: FirebaseAuth.User, guardianDocID: String) {
        let db = Firestore.firestore()
        db.collection("Visually_Impaired").document(user.uid).setData([
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "uniqueCode": uniqueCode.uppercased()
        ]) { error in
            if let error = error {
                self.alertMessage = "Error saving user data: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                self.linkVisuallyImpairedToGuardian(guardianDocID: guardianDocID, visuallyImpairedUID: user.uid)
            }
        }
    }
    
    private func linkVisuallyImpairedToGuardian(guardianDocID: String, visuallyImpairedUID: String) {
        let db = Firestore.firestore()
        db.collection("Guardian").document(guardianDocID).updateData(["VI_ID": visuallyImpairedUID]) { error in
            if let error = error {
                self.alertMessage = "Error linking with guardian: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                self.selectedTab = "Sign In"
            }
        }
    }
    
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

// Sign-In Process for Visually Impaired (Only Unique Code Required)
struct ViSignInView: View {
    @State private var uniqueCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var navigateToMainView = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 2) {
                    Text("Unique Code").font(.subheadline).foregroundColor(.gray)
                    Text("*").foregroundColor(.red)
                }
                CustomTextField(placeholder: "Enter Guardian's Unique Code", text: $uniqueCode)
            }
            .padding(.horizontal)
            
            Button(action: signInUser) {
                HStack {
                    Text("Sign In")
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hexString: "D95F4B"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(isLoading)
            
            NavigationLink(destination: VisuallyImpairedView().navigationBarBackButtonHidden(true), isActive: $navigateToMainView) { EmptyView() }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
        .overlay(loadingOverlay)
    }
    
    private func signInUser() {
        guard !uniqueCode.isEmpty else {
            alertMessage = "Please enter the unique code."
            showAlert = true
            return
        }

        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("Guardian").whereField("uniqueCode", isEqualTo: uniqueCode.uppercased()).getDocuments { snapshot, error in
            self.isLoading = false
            
            if let error = error {
                self.alertMessage = "Error verifying unique code: \(error.localizedDescription)"
                self.showAlert = true
                return
            }
            
            guard let document = snapshot?.documents.first, let viID = document.data()["VI_ID"] as? String else {
                self.alertMessage = "Invalid or unlinked unique code."
                self.showAlert = true
                return
            }
            
            self.loadUserEmailAndSignIn(viID: viID)
        }
    }
    
    private func loadUserEmailAndSignIn(viID: String) {
        let db = Firestore.firestore()
        db.collection("Visually_Impaired").document(viID).getDocument { document, error in
            if let document = document, let email = document.data()?["email"] as? String {
                self.isLoading = true
                Auth.auth().signIn(withEmail: email, password: "DefaultPass123!") { authResult, error in
                    self.isLoading = false
                    if let error = error {
                        self.alertMessage = error.localizedDescription
                        self.showAlert = true
                    } else if let user = authResult?.user, !user.isEmailVerified {
                        // Email not verified, show alert and sign out
                        self.alertMessage = "Please verify your email before signing in."
                        self.showAlert = true
                        try? Auth.auth().signOut()
                    } else {
                        // Email verified, proceed to main view
                        self.navigateToMainView = true
                    }
                }
            } else {
                self.alertMessage = "Error retrieving user email."
                self.showAlert = true
            }
        }
    }

    
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}


struct VISignUpSignInView_Previews: PreviewProvider {
    static var previews: some View {
        VISignUpSignInView()
    }
}



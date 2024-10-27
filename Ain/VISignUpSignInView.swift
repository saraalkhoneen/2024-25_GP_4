// SignUpSignInView.swift
// Ain
// Created by sara alkhoneen and joud 
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
                    ViStepByStepSignUpView(selectedTab: $selectedTab)
                } else {
                    ViSignInView()
                }
                
                Spacer()
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
        }
    }
}

struct ViStepByStepSignUpView: View {
    @Binding var selectedTab: String
    @State private var step = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var confirmEmail = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var uniqueCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            if step == 1 {
                CustomTextField(placeholder: "First Name", text: $firstName)
                CustomTextField(placeholder: "Last Name", text: $lastName)
                
                Button(action: proceedToStep2) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "D95F4B"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading)
                
            } else if step == 2 {
                CustomTextField(placeholder: "Email", text: $email)
                CustomTextField(placeholder: "Confirm Email", text: $confirmEmail)
                
                Button(action: validateEmails) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "D95F4B"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading)
                
            } else if step == 3 {
                CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                CustomTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                CustomTextField(placeholder: "Unique Code", text: $uniqueCode)
                
                Button(action: registerUser) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "D95F4B"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding(.horizontal)
        .overlay(loadingOverlay)
    }
    
    private func proceedToStep2() {
        if firstName.isEmpty {
            alertMessage = "Please enter your first name."
            showAlert = true
        } else if lastName.isEmpty {
            alertMessage = "Please enter your last name."
            showAlert = true
        } else {
            step = 2
        }
    }
    
    private func validateEmails() {
        guard !email.isEmpty, !confirmEmail.isEmpty else {
            alertMessage = "Please fill in both email fields."
            showAlert = true
            return
        }
        
        guard email == confirmEmail, isValidEmail(email) else {
            alertMessage = email == confirmEmail ? "Invalid email format." : "Emails do not match."
            showAlert = true
            return
        }
        
        checkEmailExists(email)
    }
    
    private func checkEmailExists(_ email: String) {
        isLoading = true
        Firestore.firestore().collection("Visually_Impaired")
            .whereField("email", isEqualTo: email)
            .getDocuments { querySnapshot, error in
                isLoading = false
                if let error = error {
                    alertMessage = "Error checking email: \(error.localizedDescription)"
                    showAlert = true
                } else if querySnapshot?.documents.isEmpty == false {
                    alertMessage = "Email is already registered."
                    showAlert = true
                } else {
                    step = 3
                }
            }
    }
    
    private func registerUser() {
        guard !firstName.isEmpty && !lastName.isEmpty else {
            alertMessage = "Please fill in your first and last name."
            showAlert = true
            return
        }
        
        // Validate email fields
        validateEmails()
        
        // Validate password with detailed cases
        if !isPasswordLongEnough(password) {
            alertMessage = "Password must be at least 8 characters long."
            showAlert = true
            return
        }
        
        if !containsUppercase(password) {
            alertMessage = "Password must include at least one uppercase letter."
            showAlert = true
            return
        }
        
        if !containsLowercase(password) {
            alertMessage = "Password must include at least one lowercase letter."
            showAlert = true
            return
        }
        
        if !containsNumber(password) {
            alertMessage = "Password must include at least one number."
            showAlert = true
            return
        }
        
        if !containsSpecialCharacter(password) {
            alertMessage = "Password must include at least one special character."
            showAlert = true
            return
        }
        // Check if unique code is provided
          guard !uniqueCode.isEmpty else {
              alertMessage = "Please enter your unique code."
              showAlert = true
              return
          }

        // Check unique code before continuing
        checkUniqueCodeExists(uniqueCode)
    }

    private func checkUniqueCodeExists(_ code: String) {
        isLoading = true
        Firestore.firestore().collection("Guardian")
            .whereField("uniqueCode", isEqualTo: code.uppercased())
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    alertMessage = "Error checking unique code: \(error.localizedDescription)"
                    showAlert = true
                } else if snapshot?.documents.isEmpty == false {
                    performUserRegistration()
                } else {
                    alertMessage = "Invalid unique code."
                    showAlert = true
                }
            }
    }
    
    private func performUserRegistration() {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else if let user = result?.user {
                user.sendEmailVerification { error in
                    if let error = error {
                        alertMessage = "Failed to send verification email: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        saveUserToFirestore(user: user)
                    }
                }
            }
        }
    }
    
    private func saveUserToFirestore(user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        let visuallyImpairedData = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "uniqueCode": uniqueCode.uppercased()
        ]
        
        db.collection("Visually_Impaired").document(user.uid).setData(visuallyImpairedData) { error in
            if let error = error {
                alertMessage = "Error saving user: \(error.localizedDescription)"
                showAlert = true
            } else {
                updateGuardianWithVisuallyImpairedUID(user.uid)
            }
        }
    }

    private func updateGuardianWithVisuallyImpairedUID(_ visuallyImpairedUID: String) {
        let db = Firestore.firestore()
        db.collection("Guardian")
            .whereField("uniqueCode", isEqualTo: uniqueCode.uppercased())
            .getDocuments { snapshot, error in
                if let error = error {
                    alertMessage = "Error updating guardian: \(error.localizedDescription)"
                    showAlert = true
                } else if let document = snapshot?.documents.first {
                    document.reference.updateData([
                        "VI_ID": visuallyImpairedUID
                    ]) { error in
                        if let error = error {
                            alertMessage = "Error linking with guardian: \(error.localizedDescription)"
                        } else {
                            alertMessage = "Registration successful. Please verify your email."
                            showAlert = true
                            selectedTab = "Sign In"
                        }
                    }
                } else {
                    alertMessage = "Guardian not found with provided unique code."
                    showAlert = true
                }
            }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    // Helper functions for specific password requirements
    private func isPasswordLongEnough(_ password: String) -> Bool {
        return password.count >= 8
    }

    private func containsUppercase(_ password: String) -> Bool {
        let uppercaseRegex = ".[A-Z]+."
        return NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password)
    }

    private func containsLowercase(_ password: String) -> Bool {
        let lowercaseRegex = ".[a-z]+."
        return NSPredicate(format: "SELF MATCHES %@", lowercaseRegex).evaluate(with: password)
    }

    private func containsNumber(_ password: String) -> Bool {
        let numberRegex = ".[0-9]+."
        return NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password)
    }

    private func containsSpecialCharacter(_ password: String) -> Bool {
        let specialCharacterRegex = ".[!@#$%^&(),.?\":{}|<>]+.*"
        return NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex).evaluate(with: password)
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


// Sign In View
struct ViSignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var uniqueCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var navigateToMainView = false

    var body: some View {
        VStack(spacing: 20) {
            CustomTextField(placeholder: "Email", text: $email)
            CustomTextField(placeholder: "Password", text: $password, isSecure: true)
            CustomTextField(placeholder: "Unique Code", text: $uniqueCode)
            
            Button(action: signInUser) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "D95F4B"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(isLoading)
            
            Button(action: resetPassword) {
                Text("Reset Password")
                    .foregroundColor(.blue)
            }
            .padding(.top, 20)
            
            NavigationLink(destination: VisuallyImpairedView().navigationBarBackButtonHidden(true), isActive: $navigateToMainView) { EmptyView() }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
        .overlay(loadingOverlay)
    }
    
    private func signInUser() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("Guardian").whereField("uniqueCode", isEqualTo: uniqueCode.uppercased()).getDocuments { snapshot, error in
            isLoading = false
            
            if let error = error {
                alertMessage = "issue in checking your unique code. Please try again later. Error: \(error.localizedDescription)"
                showAlert = true
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    isLoading = false
                    
                    if let error = error {
                        switch AuthErrorCode(rawValue: error._code) {
                        case .wrongPassword:
                            alertMessage = "The password is incorrect."
                        case .invalidEmail:
                            alertMessage = "The email address is invalid."
                        case .userNotFound:
                            alertMessage = "No account found for this email."
                        default:
                            alertMessage = "Sign-in failed due to an unexpected error: \(error.localizedDescription). Please try again."
                        }
                        showAlert = true
                    } else if let user = authResult?.user, !user.isEmailVerified {
                        alertMessage = "Your email is not verified. Please check your inbox."
                        showAlert = true
                    } else {
                        navigateToMainView = true
                    }
                }
                
            } else {
                alertMessage = "The unique code entered is invalid."
                showAlert = true
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            alertMessage = error?.localizedDescription ?? "Password reset email sent."
            showAlert = true
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

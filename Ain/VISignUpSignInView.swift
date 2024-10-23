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
                // Top background curve
                TopCurveShape()
                    .fill(Color(hexString: "3C6E71"))
                    .frame(height: 40)
                    .edgesIgnoringSafeArea(.top)
                
                // Segmented control for Sign Up and Sign In
                HStack(spacing: 0) {
                    Button(action: {
                        selectedTab = "Sign Up"
                    }) {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTab == "Sign Up" ? Color(hexString: "3c6e71") : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTab == "Sign Up" ? .white : .black)
                            .cornerRadius(10, corners: [.topLeft, .bottomLeft])
                    }
                    
                    Button(action: {
                        selectedTab = "Sign In"
                    }) {
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
                
                // Display Sign Up or Sign In based on selected tab
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

// Step-by-Step Sign Up process
struct ViStepByStepSignUpView: View {
    @Binding var selectedTab: String
    @State private var step = 1
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var uniqueCode: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            if step == 1 {
                // Step 1: First Name and Last Name
                CustomTextField(placeholder: "First Name", text: $firstName)
                CustomTextField(placeholder: "Last Name", text: $lastName)
                
                Button(action: {
                    if firstName.isEmpty || lastName.isEmpty {
                        alertMessage = "Please fill in both first name and last name."
                        showAlert = true
                    } else {
                        step = 2
                    }
                }) {
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
                // Step 2: Email and Confirm Email
                CustomTextField(placeholder: "Email", text: $email)
                CustomTextField(placeholder: "Confirm Email", text: $confirmEmail)
                
                Button(action: {
                    validateEmails()
                }) {
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
                // Step 3: Password and Confirm Password
                CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                CustomTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                // Unique Code Field
                CustomTextField(placeholder: "Unique Code", text: $uniqueCode)
                
                Button(action: {
                    validatePasswords()
                }) {
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
    
    var loadingOverlay: some View {
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
    
    private func validateEmails() {
        if email.isEmpty || confirmEmail.isEmpty {
            alertMessage = "Please fill in both email fields."
            showAlert = true
        } else if !isValidEmail(email) {
            alertMessage = "Please enter a valid email address."
            showAlert = true
        } else if email != confirmEmail {
            alertMessage = "The email addresses do not match. Please check and try again."
            showAlert = true
        } else {
            checkEmailExists(email) // Check if email exists before proceeding
        }
    }
    
    private func validatePasswords() {
        if password.isEmpty || confirmPassword.isEmpty {
            alertMessage = "Please fill in both password fields."
            showAlert = true
        } else if password != confirmPassword {
            alertMessage = "The passwords do not match. Please check and try again."
            showAlert = true
        } else if !isPasswordStrong(password) {
            alertMessage = "Password must be at least 6 characters long, include an uppercase letter, a number, and a special character."
            showAlert = true
        } else {
            register()
        }
    }
    
    // Email and password validation functions
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    func isPasswordStrong(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*])[A-Za-z0-9!@#$%^&*]{6,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with: password)
    }
    
    // Email existence check
    func checkEmailExists(_ email: String) {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("Guardian").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            isLoading = false
            if let error = error {
                alertMessage = "Error checking email: \(error.localizedDescription)"
                showAlert = true
            } else if let documents = querySnapshot?.documents, !documents.isEmpty {
                alertMessage = "Email is already registered. Please use a different email."
                showAlert = true
            } else {
                // Proceed to step 3 if email does not exist
                step = 3
            }
        }
    }
    
    func register() {
        isLoading = true
        let uppercasedUniqueCode = uniqueCode.uppercased()
        let db = Firestore.firestore()
        
        db.collection("Guardian").whereField("uniqueCode", isEqualTo: uppercasedUniqueCode).getDocuments { (querySnapshot, error) in
            if let error = error {
                self.alertMessage = "Error checking unique code: \(error.localizedDescription)"
                self.showAlert = true
                self.isLoading = false
                return
            }
            
            if let documents = querySnapshot?.documents, let guardianDoc = documents.first {
                Auth.auth().createUser(withEmail: self.email, password: self.password) { authResult, error in
                    self.isLoading = false
                    if let error = error {
                        self.alertMessage = "Error signing up: \(error.localizedDescription)"
                        self.showAlert = true
                    } else if let authResult = authResult {
                        // Send verification email
                        authResult.user.sendEmailVerification { error in
                            if let error = error {
                                self.alertMessage = "Error sending verification email: \(error.localizedDescription)"
                                self.showAlert = true
                            } else {
                                // Save visually impaired user details to Firestore
                                let userRef = db.collection("Visually_Impaired").document(authResult.user.uid)
                                userRef.setData([
                                    "firstName": self.firstName,
                                    "lastName": self.lastName,
                                    "email": self.email,
                                    "guardianId": guardianDoc.documentID
                                ]) { error in
                                    if let error = error {
                                        self.alertMessage = "Error saving user details: \(error.localizedDescription)"
                                        self.showAlert = true
                                    } else {
                                        self.alertMessage = "Successfully signed up! A verification email has been sent. Please verify your email before signing in."
                                        self.showAlert = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            self.selectedTab = "Sign In"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                self.isLoading = false
                self.alertMessage = "Invalid unique code."
                self.showAlert = true
            }
        }
    }

}
// Sign In View
 struct ViSignInView: View {
     @State private var email: String = ""
     @State private var password: String = ""
     @State private var uniqueCode: String = ""
     @State private var showAlert = false
     @State private var alertMessage = ""
     @State private var isLoading = false
     @State private var navigateToVisuallyImpaired = false // State variable for navigation
     
     var body: some View {
         VStack(spacing: 20) {
             CustomTextField(placeholder: "Email", text: $email)
             CustomTextField(placeholder: "Password", text: $password, isSecure: true)
             CustomTextField(placeholder: "Unique Code", text: $uniqueCode)
             
             Button(action: {
                 signIn()
             }) {
                 Text("Sign In")
                     .frame(maxWidth: .infinity)
                     .padding()
                     .background(Color(hexString: "D95F4B"))
                     .foregroundColor(.white)
                     .cornerRadius(12)
             }
             .padding(.horizontal)
             .disabled(isLoading)
             //Button to reset password
                         Button(action: {
                         resetPassword()
                         }) {
                             Text("Reset Password")
                                 .foregroundColor(.blue)
                                 .padding()
                         }
                         .padding(.horizontal)
                         .disabled(isLoading)
             
             // NavigationLink to VisuallyImpairedView
             NavigationLink(destination: VisuallyImpairedView(), isActive: $navigateToVisuallyImpaired) { EmptyView() }
         }
         .alert(isPresented: $showAlert) {
             Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
         }
         .padding(.horizontal)
         .overlay(loadingOverlay)
     }
     
     var loadingOverlay: some View {
         Group {
             if isLoading {
                 Color.black.opacity(0.4)
                     .edgesIgnoringSafeArea(.all)
                 ProgressView("Loading...")
                     .progressViewStyle(CircularProgressViewStyle(tint: .white))
                     .scaleEffect(1.5)
                     .frame(maxWidth: 100, maxHeight: 100) // Set a fixed size for the loading indicator
             }
         }
     }
     
     func signIn() {
         isLoading = true
         let uppercasedUniqueCode = uniqueCode.uppercased()
         
         Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
             isLoading = false
             if let error = error {
                 alertMessage = "Error signing in: \(error.localizedDescription)"
                 showAlert = true
             } else if let authResult = authResult {
                 // Check if the email is verified
                 if authResult.user.isEmailVerified {
                     let db = Firestore.firestore()
                     db.collection("Guardian").whereField("uniqueCode", isEqualTo: uppercasedUniqueCode).getDocuments { (querySnapshot, error) in
                         if let error = error {
                             alertMessage = "Error checking unique code: \(error.localizedDescription)"
                             showAlert = true
                         } else if let documents = querySnapshot?.documents, let guardianDoc = documents.first {
                             // Unique code is valid, guardian found
                             navigateToVisuallyImpaired = true
                         } else {
                             alertMessage = "Unique code is invalid."
                             showAlert = true
                         }
                     }
                 } else {
                     alertMessage = "Your email address has not been verified. Please check your inbox."
                     showAlert = true
                 }
             }
         }
     }
     // Function to reset password
         func resetPassword() {
             guard !email.isEmpty else {
                 alertMessage = "Please enter your email address."
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

 // Custom TextField
     struct CustomTextField1: View {
         var placeholder: String
         @Binding var text: String
         var isSecure: Bool = false
         
         var body: some View {
             Group {
                 if isSecure {
                     SecureField(placeholder, text: $text)
                         .padding()
                         .background(Color.gray.opacity(0.2))
                         .cornerRadius(12)
                 } else {
                     TextField(placeholder, text: $text)
                         .autocapitalization(.allCharacters)
                         .disableAutocorrection(true)
                         .padding()
                         .background(Color.gray.opacity(0.2))
                         .cornerRadius(12)
                 }
             }
         }
     }
     struct ViSignUpSignInView_Previews: PreviewProvider {
         static var previews: some View {
             VISignUpSignInView()
         }
     }


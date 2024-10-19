//  SignUpSignInView.swift
//  Ain
//  Created by joud alhussain and Sara alkhoneen
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUpSignInView: View {
    @State private var selectedTab: String = "Sign up"
    @State private var isPasswordVisible: Bool = false

    
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
                        selectedTab = "Sign up"
                    }) {
                        Text("Sign up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTab == "Sign up" ? Color(hexString: "3c6e71") : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTab == "Sign up" ? .white : .black)
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
                if selectedTab == "Sign up" {
                    StepByStepSignUpView(selectedTab: $selectedTab)
                } else {
                    SignInView()
                }
                
                Spacer()
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
        }
    }
}

// Step-by-Step Sign Up process
struct StepByStepSignUpView: View {
    @Binding var selectedTab: String
    @State private var step = 1
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
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
                .disabled(isLoading)// Disable button while loading
                
            } else if step == 2 {
                // Step 2: Email and Confirm Email
                CustomTextField(placeholder: "Email", text: $email)
                CustomTextField(placeholder: "Confirm Email", text: $confirmEmail)
                
                Button(action: {
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
                }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "D95F4B"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading) // Disable button while loading
                
            } else if step == 3 {
                // Step 3: Password and Confirm Password
                CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                CustomTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                
                Button(action: {
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
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "D95F4B"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading) // Disable button while loading
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding(.horizontal)
        .overlay(
                    Group {
                        if isLoading {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            ProgressView("Loading...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                    }
                )
    }
    // Function to check if email is valid
        func isValidEmail(_ email: String) -> Bool {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}"
            let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return predicate.evaluate(with: email)
        }
        
        // Function to check password strength
        func isPasswordStrong(_ password: String) -> Bool {
            let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*])[A-Za-z0-9!@#$%^&*]{6,}$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
            return predicate.evaluate(with: password)
        }
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
    
    // Function for sign up
    func register() {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else if let user = result?.user {
                // Send verification email
                user.sendEmailVerification { error in
                    if let error = error {
                        alertMessage = "Error sending verification email: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        alertMessage = "Verification email sent. Please check your inbox."
                        showAlert = true
                        print("Verification email sent to: \(email)")
                    }
                }
                
                // Save user info to Firestore (without password)
                let db = Firestore.firestore()
                db.collection("Guardian").document(user.uid).setData([
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    
                    // Note: Do NOT store the password!
                ]) { error in
                    if let error = error {
                        alertMessage = "Error saving user info: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        alertMessage = "Verification email sent. Please check your inbox.\(email)"
                        showAlert = true
                        
                        selectedTab = "Sign In" // Redirect to Sign In after successful registration
                        step = 1 // Reset step for new user to start from the beginning
                    }
                }
            }
        }
    }
}

// Sign In View
struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isSignedIn = false // Track if the user is signed in

    
    var body: some View {
          VStack(spacing: 20) {
              CustomTextField(placeholder: "Email", text: $email)
                         CustomTextField(placeholder: "Password", text: $password, isSecure: true)

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
                         .disabled(isLoading) // Disable button while loading
                         
                         // NavigationLink to GuardianView
                         NavigationLink(destination: GuardianView(), isActive: $isSignedIn) {
                             EmptyView() // This will not be visible
                         }

                         // Reset Password Link
                         Button(action: {
                             resetPassword()
                         }) {
                             Text("Forgot Password?")
                                 .foregroundColor(Color.blue)
                         }
                         .padding(.top, 20)
                     }
                     .padding() // Add padding to the VStack
                     .alert(isPresented: $showAlert) {
                         Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                     }
                     .overlay(
                         Group {
                             if isLoading {
                                 Color.black.opacity(0.4)
                                     .edgesIgnoringSafeArea(.all)
                                 ProgressView("Loading...")
                                     .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                     .scaleEffect(1.5)
                             }
                         }
                     )
                 }

    func generateUniqueCode(firstName: String, lastName: String, completion: @escaping (String?) -> Void) {
        let codePrefix = "\(firstName.prefix(2).uppercased())\(lastName.prefix(2).uppercased())"
        let db = Firestore.firestore()
        
        func checkAndGenerate() {
            let randomDigits = String(format: "%02d", Int.random(in: 0...99))
            let uniqueCode = "\(codePrefix)\(randomDigits)"
            
            // Check if the generated code already exists
            db.collection("Guardian").whereField("uniqueCode", isEqualTo: uniqueCode).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error checking unique code: \(error.localizedDescription)")
                    completion(nil)
                } else if querySnapshot?.documents.isEmpty == true {
                    // Code is unique, return it
                    completion(uniqueCode)
                } else {
                    // Code exists, generate a new one
                    checkAndGenerate()
                }
            }
        }
        
        checkAndGenerate()
    }

    // Function for sign in
    func signIn() {
        // Ensure that both email and password fields are not empty
        guard !email.isEmpty && !password.isEmpty else {
            alertMessage = "Please enter both email and password."
            showAlert = true // Show alert message to the user
            return // Exit the function if the check fails
        }
        
        isLoading = true // Set loading state to true while signing in
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false // Set loading state to false after the sign-in attempt
            if let error = error {
                // If there's an error during sign-in, display the error message
                alertMessage = error.localizedDescription
                showAlert = true
            } else if let user = Auth.auth().currentUser {
                // Check if the user object is valid and available
                if user.isEmailVerified {
                    // User is verified, allow sign in
                    print("User signed in and verified: \(email)")
                    
                    // Retrieve the user's first and last name from Firestore or local storage
                    let db = Firestore.firestore()
                    db.collection("Guardian").document(user.uid).getDocument { document, error in
                        if let document = document, document.exists {
                            let firstName = document.get("firstName") as? String ?? "" // Get first name from Firestore
                            let lastName = document.get("lastName") as? String ?? "" // Get last name from Firestore
                            let storedUniqueCode = document.get("uniqueCode") as? String
                            // Generate unique code based on the retrieved first and last names
                            // Check if unique code exists
                                                    if let code = storedUniqueCode {
                                                        // Unique code exists, proceed with sign-in
                                                        isSignedIn = true
                                                    } else {
                                                        // Generate and save a new unique code if it doesn't exist
                                                        generateUniqueCode(firstName: firstName, lastName: lastName) { newCode in
                                                            if let code = newCode {
                                                                db.collection("Guardian").document(user.uid).updateData([
                                                                    "uniqueCode": code,
                                                                    "isVerified": true
                                                                ]) { error in
                                                                    if let error = error {
                                                                        alertMessage = "Error saving unique code: \(error.localizedDescription)"
                                                                        showAlert = true
                                                                    } else {
                                                                        isSignedIn = true
                                                                    }
                                                                }
                                                            } else {
                                                                alertMessage = "Error generating unique code."
                                                                showAlert = true
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    alertMessage = "User data not found."
                                                    showAlert = true
                                                }
                                            }
                                        } else {
                                            alertMessage = "Please verify your email before signing in."
                                            showAlert = true
                                            try? Auth.auth().signOut()
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
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @State private var isPasswordVisible = false
    
    var body: some View {
        HStack {
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if isSecure {
                Button(action: {
                    isPasswordVisible.toggle() // Toggle visibility
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 10)
            }
        }
    }
}

// Custom shape for the top curve
struct TopCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.4))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height * 0.1),
                          control: CGPoint(x: rect.width / 2, y: -50))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

// Extension to use hex colors
extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// CornerRadius extension to round specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct SignUpSignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpSignInView()
    }
}

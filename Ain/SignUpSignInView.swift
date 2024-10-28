import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUpSignInView: View {
    @State private var selectedTab: String = "Sign up"
    
    var body: some View {
        NavigationView {
            VStack {
                // Top background curve
                TopCurveShape()
                    .fill(Color(hexString: "3C6E71"))
                    .frame(height: 40)
                    .edgesIgnoringSafeArea(.top)
                
                // Light gray text on top of the page
                               Text("Guardian")
                                   .font(.headline)
                                   .foregroundColor(Color.gray.opacity(0.7)) // Light gray color
                                   .padding(.top, 10) // Adjust padding as needed
                      
                // Segmented control for Sign Up and Sign In
                HStack(spacing: 0) {
                    Button(action: { selectedTab = "Sign up" }) {
                        Text("Sign up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTab == "Sign up" ? Color(hexString: "3c6e71") : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTab == "Sign up" ? .white : .black)
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
                
                // Display Sign Up or Sign In based on selected tab
                if selectedTab == "Sign up" {
                    StepByStepSignUpView(selectedTab: $selectedTab)
                } else {
                    SignInView()
                }
                
                Spacer()
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .navigationBarBackButtonHidden(true)
        }
    }
}

// Step-by-Step Sign Up Process
struct StepByStepSignUpView: View {
    @Binding var selectedTab: String
    @State private var step = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var confirmEmail = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    @State private var signUpSuccess = false

    
   
    var body: some View {
        VStack(spacing: 20) {
            if step == 1 {
                VStack(alignment: .leading, spacing: 5) {
                    Text("First Name*")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    CustomTextField(placeholder: "Enter your First Name", text: $firstName)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Last Name*")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    CustomTextField(placeholder: "Enter your Last Name", text: $lastName)
                }
                
                HStack(spacing: 10) {
                    Spacer() // Pushes "Next" to the right
                    Button(action: proceedToNextStep) {
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
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                
            } else if step == 2 {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email*")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    CustomTextField(placeholder: "Enter your Email", text: $email)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Confirm Email*")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    CustomTextField(placeholder: "Confirm your Email", text: $confirmEmail)
                }
                
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
                    
                    Button(action: validateEmail) {
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
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                
            } else if step == 3 {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Password*")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    CustomTextField(placeholder: "Enter your Password", text: $password, isSecure: true)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Confirm Password*")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    CustomTextField(placeholder: "Confirm your Password", text: $confirmPassword, isSecure: true)
                }
                
                HStack(spacing: 10) {
                    Button(action: { step = 2 }) {
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
                    
                    Button(action: register) {
                        Text("Sign Up")
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
            Alert(title: Text("alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
               .overlay(
                   // Success overlay that appears on successful registration من هنا والي ف،قه يتحكم برساله نجاح الدخول 
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
    private func proceedToNextStep() {
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


    private func validateEmail() {
        guard !email.isEmpty, !confirmEmail.isEmpty else {
            alertMessage = "Please fill in both email fields."
            showAlert = true
            return
        }
        
        guard email.contains("@"), isValidEmail(email) else {
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }
        
        guard email == confirmEmail else {
            alertMessage = "The email addresses do not match."
            showAlert = true
            return
        }
        
        checkEmailExists(email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func checkEmailExists(_ email: String) {
        isLoading = true
        Firestore.firestore().collection("Guardian")
            .whereField("email", isEqualTo: email)
            .getDocuments { querySnapshot, error in
                isLoading = false
                if let error = error {
                    alertMessage = "Error checking email: \(error.localizedDescription)"
                    showAlert = true
                } else if let documents = querySnapshot?.documents, !documents.isEmpty {
                    alertMessage = "Email is already registered."
                    showAlert = true
                } else {
                    step = 3
                }
            }
    }

    private func register() {
        guard !password.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "Please fill in both password fields."
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "The passwords do not match."
            showAlert = true
            return
        }
        
        guard password.count >= 8 else {
            alertMessage = "Password must be at least 8 characters long."
            showAlert = true
            return
        }

        let uppercaseRegex = ".*[A-Z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password) else {
            alertMessage = "Password must include at least one uppercase letter."
            showAlert = true
            return
        }

        let lowercaseRegex = ".*[a-z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", lowercaseRegex).evaluate(with: password) else {
            alertMessage = "Password must include at least one lowercase letter."
            showAlert = true
            return
        }

        let numberRegex = ".*[0-9]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password) else {
            alertMessage = "Password must include at least one number."
            showAlert = true
            return
        }

        let specialCharacterRegex = ".*[!@#$%^&*.]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex).evaluate(with: password) else {
            alertMessage = "Password must include at least one special character."
            showAlert = true
            return
        }

        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                if let authError = AuthErrorCode(rawValue: error._code) {
                    switch authError {
                    case .emailAlreadyInUse:
                        alertMessage = "The email is already in use by another account."
                    case .invalidEmail:
                        alertMessage = "Invalid email address."
                    default:
                        alertMessage = error.localizedDescription
                    }
                }
                showAlert = true
            } else if let user = result?.user {
                user.sendEmailVerification { error in
                    if let error = error {
                        alertMessage = "Error sending verification email: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        alertMessage = "Verification email sent. Please check your inbox."
                        saveUserToFirestore(user: user)
                    }
                }
            }
        }
    }

    // Updated saveUserToFirestore to ensure unique code is generated
    private func saveUserToFirestore(user: FirebaseAuth.User) {
        generateUniqueCode { uniqueCode in
            Firestore.firestore().collection("Guardian").document(user.uid).setData([
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "uniqueCode": uniqueCode
            ]) { error in
                if let error = error {
                    alertMessage = "Error saving user info: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    signUpSuccess = true // Trigger success state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) { // هنا ترا ماسج  وتحديد مدته success feedback
                        selectedTab = "Sign In"
                        step = 1
                        signUpSuccess = false // Reset the success state
                    }
                }
            }
        }
    }
    // Generates a unique code and checks it in Firestore before returning
    private func generateUniqueCode(completion: @escaping (String) -> Void) {
        var uniqueCode = ""
        
        func createAndCheckCode() {
            uniqueCode = "\(firstName.prefix(2).uppercased())\(lastName.prefix(2).uppercased())\(String(format: "%02d", Int.random(in: 0...99)))"
            
            // Check if the unique code already exists
            Firestore.firestore().collection("Guardian").whereField("uniqueCode", isEqualTo: uniqueCode).getDocuments { (snapshot, error) in
                if let error = error {
                    alertMessage = "Error checking unique code: \(error.localizedDescription)"
                    showAlert = true
                } else if snapshot?.documents.isEmpty == false {
                    // Unique code already exists, generate a new one
                    createAndCheckCode()
                } else {
                    // Unique code is available
                    completion(uniqueCode)
                }
            }
        }
        
        // Start generating and checking the unique code
        createAndCheckCode()
    }
}

// Sign In View
struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isSignedIn = false

    var body: some View {
        VStack(spacing: 20) {
                   VStack(alignment: .leading, spacing: 5) {
                       Text("Email*")
                           .font(.subheadline)
                           .foregroundColor(.gray)
                       CustomTextField(placeholder: "Enter your Email", text: $email)
                   }
                   
                   VStack(alignment: .leading, spacing: 5) {
                       Text("Password*")
                           .font(.subheadline)
                           .foregroundColor(.gray)
                       CustomTextField(placeholder: "Enter your Password", text: $password, isSecure: true)
                   }
                   
                   Button(action: signIn) {
                       Text("Sign In")
                           .frame(maxWidth: .infinity)
                           .padding()
                           .background(Color(hexString: "D95F4B"))
                           .foregroundColor(.white)
                           .cornerRadius(12)
                   }
                   .padding(.horizontal)
                   .disabled(isLoading)

                   NavigationLink(destination: GuardianView().navigationBarBackButtonHidden(true), isActive: $isSignedIn) {
                       EmptyView()
                   }

                   Button(action: resetPassword) {
                       Text("Forgot Password?")
                           .foregroundColor(Color.blue)
                   }
                   .padding(.top, 20)
               }
        .padding()
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

    func signIn() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email."
            showAlert = true
            return
        }

        guard !password.isEmpty else {
            alertMessage = "Please enter your password."
            showAlert = true
            return
        }

        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else if let user = Auth.auth().currentUser {
                if user.isEmailVerified {
                
                    isSignedIn = true
                } else {
                    alertMessage = "Please verify your email before signing in."
                    showAlert = true
                    try? Auth.auth().signOut()
                }
            }
        }
    }

    func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            alertMessage = error?.localizedDescription ?? "Password reset email sent. Please check your inbox."
            showAlert = true
        }
    }

    // Re-authenticate function
    func reAuthenticateUser() {
        // Make sure to sign out the user if there's a previous session
        do {
            try Auth.auth().signOut()
        } catch let signOutError {
            print("Error signing out: \(signOutError)")
        }

        // Re-authenticate by asking the user to sign in again
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "Error signing in: \(error.localizedDescription)"
                showAlert = true
            } else {
                alertMessage = "User signed in successfully"
                showAlert = true
            }
        }
    }
}


struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @State private var isPasswordVisible = false

    var body: some View {
        ZStack {
            HStack {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .padding(.leading, 10)
                } else {
                    TextField(placeholder, text: $text)
                        .padding(.leading, 10)
                }

                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 10)
                }
            }
            .frame(height: 55) // Set a consistent height for the text field box
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.horizontal) // Add padding outside the ZStack to keep the field size consistent
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



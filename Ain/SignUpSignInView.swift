import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUpSignInView: View {
    @State private var selectedTab: String = "Sign up"
    @Environment(\.presentationMode) var presentationMode // Access presentation mode for navigation
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Go back to ContentView
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                            Text("Back")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.leading, 10)
                    
                    Spacer()
                }
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
    @State private var visuallyImpairedEmail = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var signUpSuccess = false
    @State private var showInfoAlert = false
    @State private var showHintAlert = false // State for displaying the hint alert


    var body: some View {
        VStack(spacing: 20) {
            if step == 1 {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                    Text("First Name")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        Text("*")
                                    .foregroundColor(.red)
                            }
                    CustomTextField(placeholder: "Enter your First Name", text: $firstName)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                    Text("Last Name")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        Text("*")
                                    .foregroundColor(.red)
                            }
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
                    HStack(spacing: 2) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("*")
                                .foregroundColor(.red)
                        }
                    CustomTextField(placeholder: "Enter your Email", text: $email)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                    Text("Confirm Email")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        Text("*")
                                    .foregroundColor(.red)
                            }
                    CustomTextField(placeholder: "Confirm your Email", text: $confirmEmail)
                }
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                        Text("Visually Impaired Email")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("*")
                            .foregroundColor(.red)
                    }
                        CustomTextField(placeholder: "Enter visually impaired's Email", text: $visuallyImpairedEmail)
                    
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
                    
                    Button(action: validateEmails) {
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
                    HStack {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("*")
                            .foregroundColor(.red)

                        // Hint button for password requirements
                        Button(action: {
                            showHintAlert.toggle() // Toggle the alert state
                        }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(Color(hexString: "3C6E71"))
                                .font(.title2)
                        }
                        .buttonStyle(PlainButtonStyle()) // Ensure no default button styles interfere
                    }

                    CustomTextField(placeholder: "Enter your Password", text: $password, isSecure: true)
                }
                .alert(isPresented: $showHintAlert) {
                    Alert(
                        title: Text("Password Requirements"),
                        message: Text("""
                        Your password must contain:
                        - At least 8 characters
                        - One uppercase letter
                        - One lowercase letter
                        - One number
                        - One special character (e.g., !@#$%)
                        """),
                        dismissButton: .default(Text("OK"))
                    )
                }

                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 2) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        Text("*")
                                    .foregroundColor(.red)
                            }
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


    private func validateEmails() {
            guard !email.isEmpty, !confirmEmail.isEmpty, !visuallyImpairedEmail.isEmpty else {
                alertMessage = "Please fill in All email fields."
                showAlert = true
                return
            }
            
            guard email == confirmEmail else {
                alertMessage = "The email addresses do not match."
                showAlert = true
                return
            }
            
            guard email != visuallyImpairedEmail else {
                alertMessage = "Guardian email and visually impaired email must be different."
                showAlert = true
                return
            }
            
        // Separate checks for valid email format
            guard email.contains("@"), isValidEmail(email) else {
                alertMessage = "Please enter a valid guardian email address."
                showAlert = true
                return
            }
            
            guard visuallyImpairedEmail.contains("@"), isValidEmail(visuallyImpairedEmail) else {
                alertMessage = "Please enter a valid visually impaired email address."
                showAlert = true
                return
            }
            
        checkEmailExists(email, visuallyImpairedEmail: visuallyImpairedEmail)

        }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
        private func checkEmailExists(_ email: String, visuallyImpairedEmail: String) {
            isLoading = true
            
            // Query to check if the guardian email exists
            Firestore.firestore().collection("Guardian")
                .whereField("email", isEqualTo: email)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        self.isLoading = false
                        self.alertMessage = "Error checking guardian email: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    } else if let documents = querySnapshot?.documents, !documents.isEmpty {
                        self.isLoading = false
                        self.alertMessage = "Guardian email is already registered."
                        self.showAlert = true
                        return
                    }
                    
                    // If guardian email is unique, proceed to check the visually impaired email
                    Firestore.firestore().collection("Guardian")
                        .whereField("visuallyImpairedEmail", isEqualTo: visuallyImpairedEmail)
                        .getDocuments { visuallyImpairedSnapshot, visuallyImpairedError in
                            self.isLoading = false
                            if let visuallyImpairedError = visuallyImpairedError {
                                self.alertMessage = "Error checking visually impaired email: \(visuallyImpairedError.localizedDescription)"
                                self.showAlert = true
                            } else if let visuallyImpairedDocs = visuallyImpairedSnapshot?.documents, !visuallyImpairedDocs.isEmpty {
                                self.alertMessage = "Visually impaired email is already registered."
                                self.showAlert = true
                            } else {
                                // If both emails are unique, proceed to the next step
                                self.step = 3
                            }
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
                "uniqueCode": uniqueCode,
                "visuallyImpairedEmail": visuallyImpairedEmail
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
    @State private var showPasswordReset = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                CustomTextField(placeholder: "Enter your Email", text: $email)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Password")
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

            Button(action: {
                showPasswordReset = true
            }) {
                Text("Forgot Password?")
                    .foregroundColor(Color.blue)
            }
            .padding(.top, 20)
            .sheet(isPresented: $showPasswordReset) {
                PasswordResetView()
            }
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
            } else if let user = Auth.auth().currentUser, user.isEmailVerified {
                isSignedIn = true
            } else {
                alertMessage = "Please verify your email before signing in."
                showAlert = true
                try? Auth.auth().signOut()
            }
        }
    }
}

// MARK: - Password Reset View
struct PasswordResetView: View {
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.headline)
                .padding(.top)

            CustomTextField(placeholder: "Enter your email", text: $email)

            Button(action: resetPassword) {
                Text("Send Reset Link")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "D95F4B"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Password Reset"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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

    func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }

        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false
            alertMessage = error?.localizedDescription ?? "Password reset email sent. Please check your inbox."
            showAlert = true
        }
    }
}

// Custom components, helper functions, and extensions would be here...
// such as CustomTextField, TopCurveShape, and Color hexString extension

// MARK: - CustomTextField
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
            .frame(height: 55)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}

// MARK: - TopCurveShape
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

// MARK: - Color Hex Extension
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

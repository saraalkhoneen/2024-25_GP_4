// SignUpSignInView.swift
// Ain
// Created by sara alkhoneen and joud alhussain
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Security
import Network

// MARK: - Keychain Helper
class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func saveToken(_ token: String, forKey key: String) {
        guard let tokenData = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getToken(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func deleteToken(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - User Profile Cache
class UserProfileCache {
    static let shared = UserProfileCache()
    private let profileKey = "UserProfile"
    
    func saveProfile(_ profile: [String: Any]) {
        UserDefaults.standard.set(profile, forKey: profileKey)
    }
    
    func getProfile() -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: profileKey)
    }
    
    func deleteProfile() {
        UserDefaults.standard.removeObject(forKey: profileKey)
    }
}

// MARK: - VISignUpSignInView
struct VISignUpSignInView: View {
    @State private var selectedTab: String = "Sign Up"
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

// MARK: - Step-by-Step Sign-Up
struct ViStepByStepSignUpView: View {
    @Binding var selectedTab: String
    @State private var step = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var uniqueCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
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
                
                Button(action: proceedToStep2) {
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
                    
                    Button(action: validateGuardianCodeAndEmail) {
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
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        )
    }
    
    private func proceedToStep2() {
        if firstName.isEmpty || firstName.count < 2 {
            alertMessage = "First name must be at least 2 characters."
            showAlert = true
        } else if lastName.isEmpty || lastName.count < 2 {
            alertMessage = "Last name must be at least 2 characters."
            showAlert = true
        } else {
            step = 2
        }
    }
    
    private func validateGuardianCodeAndEmail() {
        isLoading = true
        Firestore.firestore().collection("Guardian")
            .whereField("uniqueCode", isEqualTo: uniqueCode.uppercased())
            .whereField("visuallyImpairedEmail", isEqualTo: email)
            .getDocuments { snapshot, error in
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "Error verifying unique code: \(error.localizedDescription)"
                    self.showAlert = true
                } else if let document = snapshot?.documents.first,
                          document.data()["VI_ID"] == nil {
                    self.registerUser(guardianDocID: document.documentID)
                } else {
                    self.alertMessage = "Unique code and email do not match or are already linked with another user."
                    self.showAlert = true
                }
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
                self.saveUserToFirestore(user: user, guardianDocID: guardianDocID)
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
}

// MARK: - ViSignInView
struct ViSignInView: View {
    @State private var email = ""
    @State private var uniqueCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var navigateToMainView = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Email").font(.subheadline).foregroundColor(.gray)
                CustomTextField(placeholder: "Enter Email", text: $email)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Unique Code").font(.subheadline).foregroundColor(.gray)
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
    
    private func signInUser() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email."
            showAlert = true
            return
        }
        
        guard !uniqueCode.isEmpty else {
            alertMessage = "Please enter the unique code."
            showAlert = true
            return
        }
        
        isLoading = true
        Firestore.firestore().collection("Guardian")
            .whereField("uniqueCode", isEqualTo: uniqueCode.uppercased())
            .whereField("visuallyImpairedEmail", isEqualTo: email)
            .getDocuments { snapshot, error in
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "Error verifying unique code and email: \(error.localizedDescription)"
                    self.showAlert = true
                } else if let document = snapshot?.documents.first,
                          let viID = document.data()["VI_ID"] as? String {
                    self.loadUserEmailAndSignIn(viID: viID)
                } else {
                    self.alertMessage = "Invalid unique code or email."
                    self.showAlert = true
                }
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
                    } else {
                        self.navigateToMainView = true
                    }
                }
            } else {
                self.alertMessage = "Error retrieving user email."
                self.showAlert = true
            }
        }
    }
    private func attemptSignInOnline() {
        isLoading = true
        Firestore.firestore().collection("Guardian")
            .whereField("uniqueCode", isEqualTo: uniqueCode.uppercased())
            .whereField("visuallyImpairedEmail", isEqualTo: email)
            .getDocuments { snapshot, error in
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "Error verifying unique code and email: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let viID = document.data()["VI_ID"] as? String else {
                    self.alertMessage = "Invalid unique code or email."
                    self.showAlert = true
                    return
                }
                
                self.authenticateUserWithEmail(viID: viID)
            }
    }
    
    private func authenticateUserWithEmail(viID: String) {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("Visually_Impaired").document(viID).getDocument { document, error in
            self.isLoading = false
            if let error = error {
                self.alertMessage = "Error retrieving user email: \(error.localizedDescription)"
                self.showAlert = true
                return
            }
            
            guard let document = document, let email = document.data()?["email"] as? String else {
                self.alertMessage = "No user found for this unique code."
                self.showAlert = true
                return
            }
            
            self.signInWithFirebase(email: email)
        }
    }
    
    private func signInWithFirebase(email: String) {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: "DefaultPass123!") { authResult, error in
            self.isLoading = false
            if let error = error {
                self.handleFirebaseSignInError(error)
                return
            }
            
            guard let user = authResult?.user else {
                self.alertMessage = "Authentication failed. Please try again."
                self.showAlert = true
                return
            }
            
            guard user.isEmailVerified else {
                self.alertMessage = "Your email is not verified. Please check your inbox."
                self.showAlert = true
                return
            }
            
            // Navigate to the main view after successful sign-in
            self.navigateToMainView = true
        }
    }
    
    private func handleFirebaseSignInError(_ error: Error) {
        if let authError = AuthErrorCode(rawValue: error._code) {
            switch authError {
            case .networkError:
                alertMessage = "Network error occurred. Please check your connection and try again."
            case .userNotFound:
                alertMessage = "No user found for this email."
            case .wrongPassword:
                alertMessage = "Invalid password. Please try again."
            case .invalidEmail:
                alertMessage = "Invalid email format."
            default:
                alertMessage = "Authentication failed: \(error.localizedDescription)"
            }
        } else {
            alertMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        showAlert = true
    }
    
    struct VISignUpSignInView_Previews: PreviewProvider {
        static var previews: some View {
            VISignUpSignInView()
        }
    }
}

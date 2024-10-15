//  ResetPasswordEmailView.swift
//  Ain
//  Created by Sara alkhoneen and joud alhussain
import SwiftUI

struct ResetPasswordEmailView: View {
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            
            // Lock Icon
            Image(systemName: "lock.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            // Heading
            Text("Trouble signing in")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Enter your email to reset your password.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            
            // Email Fields
            VStack(spacing: 20) {
                TextField("Enter your email address", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                TextField("Confirm your email address", text: $confirmEmail)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Submit Button
            NavigationLink(destination: VerificationCodeView()) {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "3C6E71"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
        }
        .navigationBarTitle("Forgot Password", displayMode: .inline)
    }
}

// Step 2: Verification Code Entry
struct VerificationCodeView: View {
    @State private var code: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            
            // Envelope Icon
            Image(systemName: "envelope.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange)
                .padding(.bottom, 20)
            
            // Heading
            Text("Check your Email")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We sent a code to yourname@gmail.com")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            
            // Code Entry
            HStack(spacing: 15) {
                ForEach(0..<4) { _ in
                    TextField("", text: $code)
                        .frame(width: 50, height: 50)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 60)
            
            Spacer()
            
            // Submit Button
            NavigationLink(destination: ResetNewPasswordView()) {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "3C6E71"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
        }
        .navigationBarTitle("Forgot Password", displayMode: .inline)
    }
}

// Step 3: New Password Entry
struct ResetNewPasswordView: View {
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            
            // Lock Icon
            Image(systemName: "lock.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            // Heading
            Text("Create A Strong Password")
                .font(.title2)
                .fontWeight(.bold)
            
            // Password Fields
            VStack(spacing: 20) {
                SecureField("Enter a new password", text: $newPassword)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                SecureField("Confirm new password", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 10)
            
            // Password Requirements
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Must be at least 8 characters")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Must contain one special character")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            
            Spacer()
            
            // Submit Button
            Button(action: {
                // Handle password reset
            }) {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "3C6E71"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
        }
        .navigationBarTitle("Forgot Password", displayMode: .inline)
    }
}

struct ResetPasswordEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ResetPasswordEmailView()
        }
    }
}

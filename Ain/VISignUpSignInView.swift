//  VISignUpSignInView.swift
//  Ain
//  Created by Sara alkhoneen and joud alhussain

import SwiftUI

struct VISignUpSignInView: View {
    @State private var selectedTab: String = "Sign up"
    
    var body: some View {
        VStack {
            // Top background curve
            TopCurveShape()
                .fill(Color(hexString: "3C6E71"))
                .frame(height: 150)
                .edgesIgnoringSafeArea(.top)
            
            // Segmented control
            HStack(spacing: 0) {
                Button(action: {
                    selectedTab = "Sign up"
                }) {
                    Text("Sign up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTab == "Sign up" ? Color(hexString: "FF6B6B") : Color.gray.opacity(0.2))
                        .foregroundColor(selectedTab == "Sign up" ? .white : .black)
                        .cornerRadius(10, corners: [.topLeft, .bottomLeft])
                }

                Button(action: {
                    selectedTab = "Sign In"
                }) {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTab == "Sign In" ? Color(hexString: "FF6B6B") : Color.gray.opacity(0.2))
                        .foregroundColor(selectedTab == "Sign In" ? .white : .black)
                        .cornerRadius(10, corners: [.topRight, .bottomRight])
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)

            // Form fields
            if selectedTab == "Sign up" {
                VISignUpView()
            } else {
                VISignInView()
            }
            
            Spacer()
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

struct VISignUpView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var code: String = ""
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        Spacer()
            .frame(height: 40)

        VStack(spacing: 20) {
            CustomTextField(placeholder: "Insert your First Name here", text: $firstName)
            CustomTextField(placeholder: "Insert your Last Name here", text: $lastName)
            CustomTextField(placeholder: "Insert your code here", text: $code)
            CustomTextField(placeholder: "Insert your Email here", text: $email)
            CustomTextField(placeholder: "Confirm your Email here", text: $confirmEmail)
            CustomTextField(placeholder: "Insert your password here", text: $password, isSecure: true)
            CustomTextField(placeholder: "Confirm your password here", text: $confirmPassword, isSecure: true)
            
            Button(action: {
                // Handle VI sign-up action here
            }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "3C6E71"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

struct VISignInView: View {
    @State private var code: String = ""
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        Spacer()
            .frame(height: 40)
        VStack(spacing: 20) {
            CustomTextField(placeholder: "Insert your code here", text: $code)
            CustomTextField(placeholder: "Insert your Email here", text: $email)
            CustomTextField(placeholder: "Confirm your Email here", text: $confirmEmail)
            CustomTextField(placeholder: "Insert your password here", text: $password, isSecure: true)
            CustomTextField(placeholder: "Confirm your password here", text: $confirmPassword, isSecure: true)
            
            Button(action: {
                // Handle VI sign-in action here
            }) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "3C6E71"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(action: {
                // Handle forgot password action
            }) {
                Text("Forgot password?")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal)
    }
}

// Use the same CustomTextField, TopCurveShape, Color extension, and cornerRadius extension as in your existing SignUpSignInView.swift

struct VISignUpSignInView_Previews: PreviewProvider {
    static var previews: some View {
        VISignUpSignInView()
    }
}

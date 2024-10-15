//
//  SignUpSignInView.swift
//  Ain
//
//  Created by joud alhussain and Sara alkhoneen

import SwiftUI

struct SignUpSignInView: View {
    @State private var selectedTab: String = "Sign up"
    
    var body: some View {
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
           
            Spacer()
                .frame(height: 40) 


            // Display Sign Up or Sign In based on selected tab
            if selectedTab == "Sign up" {
                StepByStepSignUpView()
            } else {
                SignInView()
            }
            
            Spacer()
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

// Step-by-Step Sign Up process
struct StepByStepSignUpView: View {
    @State private var step = 1
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {

        VStack(spacing: 20) {
            if step == 1 {
                // Step 1: First Name and Last Name
                CustomTextField(placeholder: "First Name", text: $firstName)
                CustomTextField(placeholder: "Last Name", text: $lastName)
                
                Button(action: {
                    step = 2
                }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "D95F4B"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
            } else if step == 2 {
                // Step 2: Email and Confirm Email
                CustomTextField(placeholder: "Email", text: $email)
                CustomTextField(placeholder: "Confirm Email", text: $confirmEmail)
                
                Button(action: {
                    if email == confirmEmail {
                        sendConfirmationEmail(email: email)
                        step = 3
                    } else {
                        print("Emails do not match")
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
                
            } else if step == 3 {
                // Step 3: Password and Confirm Password
                CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                CustomTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                
                Button(action: {
                    // Final sign-up action
                    print("Sign-up completed")
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "D95F4B"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    // Function to send a confirmation email
    func sendConfirmationEmail(email: String) {
        print("Confirmation email sent to \(email)") // Replace this with actual email sending logic
    }
}

// Sign In View
struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            CustomTextField(placeholder: "Email", text: $email)
            CustomTextField(placeholder: "Password", text: $password, isSecure: true)
            
            Button(action: {
                // Handle sign-in action here
                print("Sign In action")
            }) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hexString: "D95F4B"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(action: {
                // Handle forgot password action
                print("Forgot password action")
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

// Custom TextField
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        if isSecure {
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

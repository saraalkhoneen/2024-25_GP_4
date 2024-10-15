//  SettingsView.swift
//  Ain
//  Created by Sara alkhoneen and joud alhussain
import SwiftUI

struct SettingsView: View {
    @State private var isShowingSignOutAlert = false
    @State private var isPushNotificationsEnabled = true

    var body: some View {
        NavigationView {
            ZStack {
                // Background color (hex 3C6E71)
                Color(hexString: "3C6E71")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Top background with the settings title
                    TopCurveShape()
                        .fill(Color(hexString: "3C6E71"))
                        .frame(height: 150)
                        .overlay(
                            HStack {
                                Spacer()
                                Text("Settings")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .padding(.top,80)
                                Spacer()
                            }
                        )
                        .edgesIgnoringSafeArea(.top)
                    
                    // White box container for all content
                    VStack(spacing: 20) {
                        // Profile section
                        VStack {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    .padding(.leading)
                                
                                Text("Badr")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.leading, 10)
                                
                                Spacer()
                            }
                            .padding(.vertical)
                        }
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                        
                        // Account Settings section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Account Settings")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.leading)
                            
                            NavigationLink(destination: ChangePasswordView()) {
                                HStack {
                                    Text("Change password")
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 1)
                            }
                            .padding(.horizontal)
                            
                            Toggle(isOn: $isPushNotificationsEnabled) {
                                Text("Push notifications")
                                    .foregroundColor(.black)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        // More section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("More")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.leading)
                            
                            NavigationLink(destination: AboutUsView()) {
                                HStack {
                                    Text("About us")
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 1)
                            }
                            .padding(.horizontal)
                            
                            NavigationLink(destination: PrivacyPolicyView()) {
                                HStack {
                                    Text("Privacy policy")
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 1)
                            }
                            .padding(.horizontal)
                            
                            NavigationLink(destination: TermsConditionsView()) {
                                HStack {
                                    Text("Terms and conditions")
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 1)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        Spacer()
                        
                        // Sign out button
                        Button(action: {
                            isShowingSignOutAlert = true
                        }) {
                            HStack {
                                Text("Sign out")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "arrowshape.turn.up.left.fill")
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                        }
                        .alert(isPresented: $isShowingSignOutAlert) {
                            Alert(
                                title: Text("Are you sure you want to sign out?"),
                                primaryButton: .destructive(Text("Sign out")) {
                                    // Handle the sign-out action here
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white) // White background for the box
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding()
                }
            }
            .navigationBarItems(leading: HStack {
                Button(action: {
                    // Action to go back to the previous view
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                        Text("Back")
                            .foregroundColor(.white)
                    }
                }
            })
            .navigationBarTitle("", displayMode: .inline) // Hides the default title
        }
    }
}

// Dummy views for navigation destinations
struct ChangePasswordView: View {
    var body: some View {
        Text("Change Password View")
            .font(.largeTitle)
    }
}

struct AboutUsView: View {
    var body: some View {
        Text("About Us View")
            .font(.largeTitle)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy View")
            .font(.largeTitle)
    }
}

struct TermsConditionsView: View {
    var body: some View {
        Text("Terms and Conditions View")
            .font(.largeTitle)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

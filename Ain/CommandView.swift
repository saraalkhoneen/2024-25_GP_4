//
//  CommandView.swift
//  Ain
//
//  Created by Sara alkhoneen on 11/04/1446 AH.
//

import SwiftUI

struct CommandView: View {
    var body: some View {
        VStack {
            // Navigation bar with back button and settings button
            HStack {
                // Back button
                // GuardianView button
                NavigationLink(destination: GuardianView()) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                        .padding()
                }
                
                Spacer()
                
                Text("Command:")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Settings button
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                        .padding()
                }
            }
            .padding(.horizontal, 20)
            
            // List of Command Buttons
            VStack(spacing: 20) {
                CommandButton(title: "Ain Start", icon: Image(systemName: "play.fill"))
                CommandButton(title: "Ain Find Text", icon: Image(systemName: "magnifyingglass"))
                CommandButton(title: "Ain Read Text", icon: Image(systemName: "speaker.wave.2.fill"))
                CommandButton(title: "Ain Help", icon: Image(systemName: "exclamationmark.triangle.fill"))
                CommandButton(title: "Ain Stop", icon: Image(systemName: "nosign"))
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .navigationBarHidden(true) // Hides the default navigation bar
    }
}

// Reusable component for Command buttons
struct CommandButton: View {
    var title: String
    var icon: Image
    
    var body: some View {
        HStack {
            icon
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(Color(hexString: "3C6E71")) // Use hex initializer for icon color
            
            Text(title)
                .foregroundColor(Color(hexString: "FF6B6B")) // Set the text color
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hexString: "1A3E48")) // Background color of the button
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {  // Embed in NavigationView for proper rendering
            CommandView()
        }
    }
}

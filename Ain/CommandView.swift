import SwiftUI

struct CommandView: View {
    @State private var showInfoAlert = false // State to control the general info alert
    
    // Custom type to store command info and conform to Identifiable
    struct CommandInfo: Identifiable {
        let id = UUID()
        let message: String
    }
    
    @State private var activeCommandInfo: CommandInfo? // Stores the information for the tapped command
    
    var body: some View {
        ScrollView { // Make the entire view scrollable
            VStack(alignment: .leading, spacing: 20) {
                // Page Title with Info Hint
                HStack {
                    Text("Start with Ain")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hexString: "3C6E71"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: {
                        showInfoAlert.toggle()
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(Color(hexString: "3C6E71"))
                            .font(.title2)
                            .padding(.leading, 4)
                    }
                    .alert(isPresented: $showInfoAlert) {
                        Alert(
                            title: Text("Info"),
                            message: Text("Ain allows the visually impaired user to interact with the app using voice commands for easier use."),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Divider()
                    .background(Color(hexString: "3C6E71"))
                    .padding(.horizontal)

                // Instructions for Adding a Visually Impaired User
                VStack(alignment: .leading, spacing: 10) {
                    Text("How to add a Visually Impaired user:")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hexString: "3C6E71"))
                        .multilineTextAlignment(.leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Download Ain on their device.")
                        Text("⁠2. Create an account for them.")
                        Text("3. In the ‘unique code’ field, enter the code shown in your homepage.")
                        Text("4. Complete the rest of the sign up process.")
                    }
                    .font(.body)
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Congratulations! Your accounts are now linked together.")
                        .foregroundColor(Color(hexString: "FF6B6B"))
                        .font(.body)
                        .padding(.leading, 10)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .background(Color(hexString: "3C6E71"))
                    .padding(.horizontal)
                
                // Command List Section with Tappable Items
                VStack(alignment: .leading, spacing: 15) {
                    Text("Help the visually impaired get started with the following commands:")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hexString: "3C6E71"))
                        .padding(.bottom, 10)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    CommandListItem(title: "Ain Start", icon: Image(systemName: "play.circle")) {
                        activeCommandInfo = CommandInfo(message: "Ain will start detecting objects.")
                    }
                    CommandListItem(title: "Ain Stop", icon: Image(systemName: "stop.circle")) {
                        activeCommandInfo = CommandInfo(message: "Ain will stop all functions.")
                    }
                    CommandListItem(title: "Ain Find Text", icon: Image(systemName: "magnifyingglass.circle")) {
                        activeCommandInfo = CommandInfo(message: "Ain will look up for text around you.")
                    }
                    CommandListItem(title: "Ain Read Text", icon: Image(systemName: "speaker.wave.2.circle")) {
                        activeCommandInfo = CommandInfo(message: "Ain will read the text in front of you.")
                    }
                    CommandListItem(title: "Ain Help", icon: Image(systemName: "exclamationmark.triangle.fill")) {
                        activeCommandInfo = CommandInfo(message: "Ain will send an SOS message to the guardian.")
                    }
                }
                .padding(.horizontal, 20)
                .alert(item: $activeCommandInfo) { info in
                    Alert(title: Text("Command Info"), message: Text(info.message), dismissButton: .default(Text("OK")))
                }

                Spacer()
            }
            .background(Color(hexString: "F2F2F2").edgesIgnoringSafeArea(.all))
        }
        .navigationBarHidden(true)
    }
}

// Reusable component for Command List Items with on-tap action
struct CommandListItem: View {
    var title: String
    var icon: Image
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                icon
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(hexString: "3C6E71"))
                
                Text(title)
                    .foregroundColor(Color(hexString: "3C6E71"))
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hexString: "E0E0E0"))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle()) // Removes button animation for a non-clickable look
    }
}

// Preview
struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommandView()
        }
    }
}

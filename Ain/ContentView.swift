import SwiftUICore
import SwiftUI
struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var moveGradient = false

    var body: some View {
        Group {
            if isAuthenticated {
                // Navigate directly to the main app view if token exists
                VisuallyImpairedView()
            } else {
                // Show the welcome screen for user navigation
                welcomeScreen
            }
        }
        .onAppear {
            checkAuthenticationToken()
        }
    }
    
    private var welcomeScreen: some View {
        NavigationView {
            ZStack {
                // Moving gradient background
                LinearGradient(gradient: Gradient(colors: [Color(hex: "#3C6E71"), Color.white]),
                               startPoint: moveGradient ? .topLeading : .bottomTrailing,
                               endPoint: moveGradient ? .bottomTrailing : .topLeading)
                    .edgesIgnoringSafeArea(.all)
                    .animation(Animation.linear(duration: 4.0).repeatForever(autoreverses: true))
                    .onAppear {
                        moveGradient.toggle()  // Starts the gradient animation
                    }
                
                // Top left curved shape
                TopLeftCurveShape()
                    .fill(Color(hex: "#3C6E71"))
                    .frame(width: 200, height: 200)
                    .position(x: 0, y: 0)
                
                // Bottom right curved shape
                BottomRightCurveShape()
                    .fill(Color(hex: "#3C6E71"))
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height)
                
                VStack {
                    Spacer()

                    // Logo centered, bigger, and moved slightly lower
                    Image("icon") // Replace with your logo
                        .resizable()
                        .frame(width: 150, height: 150) // Increased size
                        .padding(.bottom, 20) // Moves the image a bit lower
                    
                    // Welcome text with white fill color and colored border
                    Text("Welcome To Ain")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white) // Main text color
                        .padding(.bottom, 20)
                        .overlay(
                            Text("Welcome To Ain")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#3C6E71"))
                                .opacity(0.2)
                        )

                    Spacer()

                    // Buttons for Visually Impaired and Guardian
                    VStack(spacing: 20) {
                        // Navigate to VISignUpSignInView
                        NavigationLink(destination: VISignUpSignInView().navigationBarBackButtonHidden(true)) {
                            VStack {
                                Image(systemName: "person.fill") // Replace with your custom icon if needed
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 10)
                                Text("Visually Impaired")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 236, height: 167) // Set button size
                            .background(Color(hex: "#3C6E71"))
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                        
                        // Navigate to SignUpSignInView
                        NavigationLink(destination: SignUpSignInView().navigationBarBackButtonHidden(true)) {
                            VStack {
                                Image(systemName: "person.fill") // Replace with your custom icon if needed
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 10)
                                Text("Guardian")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 236, height: 167) // Set button size
                            .background(Color(hex: "#3C6E71"))
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    private func checkAuthenticationToken() {
        if let token = KeychainHelper.shared.getToken(forKey: "AuthToken") {
            print("Token found: \(token)")
            isAuthenticated = true
        } else {
            print("No token found. User needs to log in.")
            isAuthenticated = false
        }
    }
}

// MARK: - Supporting Shapes and Extensions

struct TopLeftCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height),
                          control: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

struct BottomRightCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: 0),
                          control: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

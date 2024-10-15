import SwiftUI

struct ContentView: View {
    @State private var moveGradient = false

    var body: some View {
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
                    // Logo at the top right
                    HStack {
                        Spacer()
                        Image("icon") // Replace with your logo if you have one
                            .resizable()
                            .frame(width: 80, height: 80)
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    // Welcome text
                    Text("Welcome To Ain")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    Spacer()
                    
                    // Buttons for Visually Impaired and Guardian
                    VStack(spacing: 20) {
                        // Navigate to VISignUpSignInView
                        NavigationLink(destination: VISignUpSignInView()) {
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
                        NavigationLink(destination: SignUpSignInView()) {
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
}

// Custom shape for the top left corner
struct TopLeftCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height),
                          control: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path;
    }
}

// Custom shape for the bottom right corner
struct BottomRightCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: 0),
                          control: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path;
    }
}

// Extension to use hex colors
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

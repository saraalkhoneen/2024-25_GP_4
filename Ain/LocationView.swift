//  LocationView.swift
//  Ain
//  Created by Sara alkhoneen and joud alhussain

import SwiftUI
import MapKit

struct LocationView: View {
    // Define a region for the map
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.603722, longitude: -58.381592), // Sample coordinates (Buenos Aires)
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        NavigationView { // Ensure NavigationView is at the top level
            ZStack {
                // Background color
                Color(hexString: "3C6E71") // Use the custom hex initializer defined in SharedComponents.swift
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Navigation bar with back button and settings button
                    HStack {
                        Button(action: {
                            // Handle back navigation (you can add a dismiss or pop action here if needed)
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .padding()
                        }
                        .navigationBarBackButtonHidden(true) // Hide the default back button
                        .onTapGesture {
                            // Handle back action here
                        }

                        Spacer()
                        
                        Text("Badr Location")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal)

                    // Map with a marker
                    Map(coordinateRegion: $region, annotationItems: [Marker(coordinate: CLLocationCoordinate2D(latitude: -34.603722, longitude: -58.381592))]) { marker in
                        MapMarker(coordinate: marker.coordinate, tint: .orange)
                    }
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarHidden(true) // Ensure the default navigation bar is hidden
        }
    }
}

// Marker struct for the map annotation
struct Marker: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView()
    }
}

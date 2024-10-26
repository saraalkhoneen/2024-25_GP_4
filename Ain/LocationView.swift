//  LocationView.swift
//  Ain
//  Created by Sara alkhoneen and joud alhussain
import SwiftUI
import MapKit

struct LocationView: View {
    // Define a region for the map
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.603722, longitude: -58.381592), // Sample coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // Dummy properties to simulate the two conditions
    @State private var hasLinkedVIUser = false // Simulates check for linked VI ID
    @State private var isLocationSharingEnabled = false // Simulates VI's location sharing status
    @State private var showInfoAlert = false // Controls the display of the info alert

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(hexString: "F2F2F2")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Navigation bar with title
                    HStack {
                        Spacer()
                        
                        Text("Location")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hexString: "3C6E71"))
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.horizontal)

                    // Information message if location sharing is disabled or VI user not linked
                    if !hasLinkedVIUser || !isLocationSharingEnabled {
                        HStack(spacing: 8) {
                            Text("The VI user’s location is currently unavailable.")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hexString: "3C6E71"))
                                .cornerRadius(10)
                            
                            // Hint button with alert
                            Button(action: {
                                showInfoAlert.toggle()
                            }) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(Color(hexString: "3C6E71"))
                                    .font(.title2)
                            }
                            .alert(isPresented: $showInfoAlert) {
                                Alert(
                                    title: Text("Info"),
                                    message: Text("The other party should share their location with you for you to safely watch them."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Map placeholder
                    Map(coordinateRegion: $region, annotationItems: hasLinkedVIUser && isLocationSharingEnabled ? [Marker(coordinate: region.center)] : []) { marker in
                        MapMarker(coordinate: marker.coordinate, tint: .orange)
                    }
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding(.horizontal, 20)
                    .padding(.top, hasLinkedVIUser && isLocationSharingEnabled ? 0 : 10)
                    
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


import SwiftUI
import MapKit

struct PostDetailsView: View {
    @State private var lookAroundScene:MKLookAroundScene?
    @State private var showReviews = false
    var post: Post
    
    
    
    var body: some View {
        VStack{
            HStack{
                VStack(alignment: .leading) {
                    if post.locationTag != nil {
                    }
                }
                
                Spacer()
            }
           
            if let scene = lookAroundScene {
                LookAroundPreview(initialScene: scene)
                    .frame(height: 210)
                    .frame(width: 360)
                    .cornerRadius(12)
                    .padding(.leading,-2)
            } else {
                ContentUnavailableView("No preview available", systemImage: "eye.slash")
            }
            
//            HStack {
//                Button("Rlystate Reviews") {
//                    showReviews = true
//                }
//                .frame(maxWidth: .infinity) // Makes the button full width
//                .padding(.vertical, 14) // Sets the vertical padding inside the button
//                .background(Color.black) // Sets the background color of the button
//                .foregroundColor(.white) // Sets the text color of the button
//                .cornerRadius(12) // Rounds the corners of the button
//                .padding(.horizontal, 10) // Sets the horizontal padding outside the button
//            }
//            .padding(.top, 10) // Sets the padding below the HStack or button if necessary

        }
        .onAppear{
            print("DEBUG: Did call on appear")
            fetchLookAroundPreviewInPost()
        }
        .onChange(of: post.locationTag) { oldValue, newValue in
                  print("DEBUG: Selected location changed")
                  fetchLookAroundPreviewInPost()
              }
        .padding()
    }
}

extension PostDetailsView {
    func fetchLookAroundPreviewInPost() {
            if let latitude = post.latitude, let longitude = post.longitude {
                DispatchQueue.main.async {
                    self.lookAroundScene = nil
                }
                Task {
                    do {
                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let request = MKLookAroundSceneRequest(coordinate: coordinate)
                        let scene = try await request.scene
                        DispatchQueue.main.async {
                            self.lookAroundScene = scene
                        }
                    } catch {
                        print("Error loading Look Around scene: \(error)")
                    }
                }
            }
        }
    }

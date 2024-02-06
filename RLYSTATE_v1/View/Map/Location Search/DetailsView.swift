import SwiftUI
import MapKit
import Firebase

struct DetailsView: View {
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @State private var lookAroundScene:MKLookAroundScene?
    @State private var showReviews = false
    @State private var fetchedPosts: [Post] = []
    @State private var selectedPost: Post? = nil
    

    
    
    
    var body: some View {
        VStack{
            HStack{
                VStack(alignment: .leading) {
                    if let location = locationViewModel.selectedLocation {
                        Text(location.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.leading,3)
                    }
                    if let location = locationViewModel.selectedLocation{
                        Text(location.name)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                            .padding(.trailing)
                            .padding(.leading,3)
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
            
            HStack {
                Button("Rlystate Reviews") {
                    Task {
                        await fetchPosts()
                        showReviews = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 10)
            }
            .padding(.top, 10)
            .sheet(isPresented: $showReviews) {
                if let postToShow = selectedPost {
                    AnnotationPostView(post: postToShow, isShowing: $showReviews)
                } else {
                    CreateNewPost { newPost in
                        fetchedPosts.insert(newPost, at: 0)
                        // ... need to add the location data to auto populate here in CreateNewPost...automate
                    }
                }
            }
        }
        .onAppear{
            print("DEBUG: Did call on appear")
            fetchLookAroundPreview()
        }
        .onChange(of: locationViewModel.selectedLocation) { oldValue, newValue in
                  print("DEBUG: Selected location changed")
                  fetchLookAroundPreview()
              }
        .padding()
    }
    func fetchPosts() async {
        do {
            guard let selectedLocation = locationViewModel.selectedLocation else { return }

            // Use the full precision of the coordinates
            let latitude = selectedLocation.coordinate.latitude
            let longitude = selectedLocation.coordinate.longitude

            print("DEBUG: Fetching posts for coordinates: \(latitude), \(longitude)")

            // Fetch posts with the exact same coordinates
            let query = Firestore.firestore().collection("Posts")
                .whereField("latitude", isEqualTo: latitude)
                .whereField("longitude", isEqualTo: longitude)

            let documents = try await query.getDocuments()
            
            print("DEBUG: Number of posts fetched: \(documents.count)")

            let matchedPosts = documents.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }

            DispatchQueue.main.async {
                if let firstPost = matchedPosts.first {
                    self.selectedPost = firstPost
                    self.showReviews = true
                }
            }
             } catch {
                 print(error.localizedDescription)
             }
         }
    }

extension DetailsView {
    func fetchLookAroundPreview() {
        if (locationViewModel.selectedLocation?.coordinate) != nil {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(coordinate: locationViewModel.selectedLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
                lookAroundScene = try? await request.scene
                print("WE GOT THE SCENE")
            }
        }
    }
}


#Preview {
    DetailsView()
}

//
//  PostsAnnotationsViewModel.swift
//  RLYSTATE_v1
//
//  Created by Jarmar Ledesma on 1/8/24.
//
import MapKit
import FirebaseFirestore
import FirebaseFirestoreSwift

// Define your annotation type if it doesn't exist yet
class PostAnnotation: NSObject, MKAnnotation {
    let post: Post
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0)
    }
    
    init(post: Post) {
        self.post = post
    }
}

// ViewModel to handle the fetching and managing of post annotations
class PostsAnnotationsViewModel: ObservableObject {
    @Published var annotations: [PostAnnotation] = []
    
    init() {
        fetchAndCreateAnnotations()
    }
    
    private func fetchAndCreateAnnotations() {
        Firestore.firestore().collection("Posts").getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let snapshot = snapshot else {
                print("Error fetching posts: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let posts: [Post] = snapshot.documents.compactMap { document in
                try? document.data(as: Post.self)
            }
            
            print("Fetched \(posts.count) posts")
            
            DispatchQueue.main.async {
                self.annotations = posts.map(PostAnnotation.init)
                print("Created \(self.annotations.count) annotations")
            }
        }
    }
}

//
//  Notification.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/26/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NotificationView: View {
    @State private var fetchedComments: [Comment] = []
    @State private var fetchedPosts: [Post] = []
    @State private var notifications: [Notification] = []
    var onNotificationSelected: (Notification) -> Void
    @State private var selectedPost: Post? = nil
    @State private var isNavigatingToPost: Bool = false
    @State private var navigateToCommentView = false
    
    
    
    var userUID: String {
           Auth.auth().currentUser?.uid ?? ""
       }

    var body: some View {
        NavigationStack {
            VStack {
                ReusableNotificationView(
                    userUID: userUID,
                    onDelete: { /* Handle deletion */ },
                    onNotificationSelected: { selectedNotification in
                        
                        print("Notification selected: \(selectedNotification.postId)")
                        
                        fetchPost(byId: selectedNotification.postId) { fetchedPost in
                            DispatchQueue.main.async {
                                self.selectedPost = fetchedPost
                                self.isNavigatingToPost = true
                                if let post = fetchedPost {
                                               self.fetchedPosts = [post]
                                           } else {
                                               // If the post is nil, ensure you handle this case, such as displaying an error message
                                               // or logging that the post couldn't be found.
                                           }
                                       }
                                   }
                               })
                
                // Trigger navigation directly based on selectedPost's presence
                .navigationDestination(isPresented: $navigateToCommentView) {
                               if let post = selectedPost {
                                   CommentView(post: post, isShowing: $navigateToCommentView)
                               }
                           }
                
            }
        }
        
        .navigationTitle("Notifications")
                    .fullScreenCover(isPresented: $isNavigatingToPost) { // ✅ Correctly triggers when post is selected
                        if let post = selectedPost {
                            CommentView(post: post, isShowing: $isNavigatingToPost)
                        } else {
                            Text("Error loading post. Please try again.")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
        
    }

       // Now, fetchPost is a member function of NotificationView
    func fetchPost(byId postId: String, completion: @escaping (Post?) -> Void) {
        let db = Firestore.firestore()
        db.collection("Posts").document(postId).getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching post: \(error)")
                completion(nil)
                return
            }
            guard let document = documentSnapshot, document.exists, let post = try? document.data(as: Post.self) else {
                print("Document does not exist or could not be decoded.")
                completion(nil)
                return
            }
            completion(post)
        }
    }
    func destinationView(post: Post) -> some View {
        CommentWrapperView(post: post)
    }

    func fetchComments(forPostId postId: String?) {
        guard let postId = postId else { return }
        // Implement the fetching of comments based on the postId
        // Update fetchedComments state variable accordingly
        let db = Firestore.firestore()
        db.collection("Comments").whereField("postId", isEqualTo: postId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching comments: \(error)")
                return
            }
            if let documents = snapshot?.documents {
                self.fetchedComments = documents.compactMap { document -> Comment? in
                    try? document.data(as: Comment.self)
                }
            }
        }
    }
    
   }

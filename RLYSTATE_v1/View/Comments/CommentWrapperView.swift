//
//  CommentWrapperView.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 4/5/24.
//

import SwiftUI
import FirebaseFirestore

struct CommentWrapperView: View {
    var post: Post
    @State private var showingCommentView = true 
    @State private var fetchedComments: [Comment] = []

    var body: some View {
        CommentView(post: post, isShowing: $showingCommentView)
            .onAppear {
                fetchComments(forPostId: post.id)
            }
    }

    func fetchComments(forPostId postId: String?) {
        guard let postId = postId else { return }
        // Implement the fetching of comments based on the postId
        let db = Firestore.firestore()
        db.collection("Posts").document(postId).collection("Comments").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching comments: \(error)")
            } else if let snapshot = snapshot {
                self.fetchedComments = snapshot.documents.compactMap { doc -> Comment? in
                    try? doc.data(as: Comment.self)
                }
            }
        }
    }
}

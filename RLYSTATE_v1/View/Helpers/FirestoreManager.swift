//
//  FirestoreManager.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/20/24.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()

    private init() {}

    func addCommentToPost(postID: String, comment: Comment) async throws {
        let db = Firestore.firestore()
        let postRef = db.collection("Posts").document(postID)
        let commentsRef = postRef.collection("Comments")
        
        do {
            _ = try commentsRef.addDocument(from: comment)
            print("Comment successfully added to Firestore under Post ID: \(postID)")
        } catch {
            print("Error adding comment to Firestore: \(error.localizedDescription)")
            throw error
        }
    }

    // Include other shared Firestore operations here, such as creating posts.
}

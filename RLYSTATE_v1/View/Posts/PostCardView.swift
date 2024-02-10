//
//  PostCardView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/28/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    // Callbacks
    var onUpdate: (Post)->()
    var onDelete: ()->()
    var onHidePost: (_ postID: String) -> Void
    // View Properties
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListener: ListenerRegistration?
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                if let locationTag = post.locationTag {
                    let components = locationTag.components(separatedBy: ",")
                    let shortenedLocation = components.prefix(1).joined(separator: ",")
                    
                    Text(post.userName)
                        .font(.callout)
                        .fontWeight(.semibold)
                    HStack{
                        Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("at \(shortenedLocation)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.leading,-5)
                    }
                    Text(post.text)
                        .textSelection(.enabled)
                        .padding(.vertical, 8)
                    
                    // Post Image if available
                    if let postImageURL = post.imageURL{
                        GeometryReader{
                            let size = $0.size
                            WebImage(url: postImageURL)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .frame(height:200)
                    }
                    PostInteraction()
                }
            }
        }
        
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            // Displaying Delete Button (if it's AUther of that Post)
                Menu {
                    if post.userUID == userUID{
                        
                        Button("Delete Post",role: .destructive, action: deletePost)
                    }else{
                        Button("Hide Post", action: hidePost)
                        
                        Button("Report", action:reportPost)
                    }
                }label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
        })
        
        .onAppear {
            // when the post is visible on the screen, the doc listener is added, otherwise listener is removed
            if docListener == nil {
                guard let postID = post.id else {return}
                docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                    if let snapshot{
                        if snapshot.exists{
                            // Document Updated
                            // Fetching Updated Document
                            if let updatedPost = try? snapshot.data(as: Post.self){
                                onUpdate(updatedPost)
                            }
                        }else{
                            /// Document Deleted
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear {
            // Applying Snapshot listener only when the post is available on the screen
            // else removing the listener (it saves unwanted live updated from the posts which was swipeed away from the screen)
            
            if let docListener{
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    // Like, Dislike & Share Interaction
    @ViewBuilder
    func PostInteraction()->some View{
        HStack(spacing: 6){
            Button (action: likePost){
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button (action: dislikePost){
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading,25)
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.trailing,25)
            
            // Share Button
            let shareText = "Check out this post on Rlystate: \(post.text)\n\nFor more info: rlystate://post"
            ShareLink(items: [shareText]) {
                Label("", systemImage: "square.and.arrow.up")
            }
        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
    }
    /// Liking Post
    func likePost(){
        Task{
            guard let postID = post.id else{return}
            if post.likedIDs.contains(userUID){
                /// Removing Likes
                try await Firestore.firestore().collection("Post").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            }else{
                /// Adding User ID to liked array and removing our ID from disliked Array (if added)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    /// Dislike Post
    func dislikePost(){
        Task{
            guard let postID = post.id else{return}
            if post.dislikedIDs.contains(userUID){
                /// Removing Likes
                try await Firestore.firestore().collection("Post").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }else{
                /// Adding User ID to liked array and removing our ID from disliked Array (if added)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    ///  Deleting Post
    func deletePost(){
        Task{
            /// Step 1: Delete Image from Firebase Storage if present
            do{
                if post.imageReferenceID != ""{
                    try await  Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
                }
                /// Step 2 Delete Firestore Document
                guard let postID = post.id else{return}
                try await Firestore.firestore().collection("Posts").document(postID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    func hidePost() {
        Task {
            guard let postID = post.id else { return }
            
            let userID = self.userUID
            let db = Firestore.firestore()
            let postRef = db.collection("Posts").document(postID)

            do {
                // Hide the post for the current user
                try await postRef.updateData([
                    "hiddenFor": FieldValue.arrayUnion([userID])
                ])
                print("Post hidden successfully for user: \(userID)")
                
                // Call the callback to signal that the post should be removed from the visible list
                DispatchQueue.main.async {
                    self.onHidePost(postID)
                }
            } catch {
                print("Error hiding post: \(error.localizedDescription)")
            }
        }
    }
    
    func reportPost(){
        print("Post reported")
    }
    
    func removeFromVisiblePosts(postID: String) {
        // This is a placeholder function. You'll need to implement the actual logic
        // that filters out or removes the given postID from the 'posts' array in your view model or view.
    }
}

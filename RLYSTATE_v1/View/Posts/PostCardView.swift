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
import UIKit
import MessageUI
import SafariServices

struct PostCardView: View {
    var post: Post
    // Callbacks
    var onUpdate: (Post)->()
    var onDelete: ()->()
    var onHidePost: (_ postID: String) -> Void
    // View Properties
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var showingMailComposer = false
    @State private var docListener: ListenerRegistration?
    @State private var showSafari = false
    //comment view
    @State private var showingCommentView = false
    @State private var commentCount: Int = 0
    var isSinglePostMode: Bool
    
    
//    @State private var safariURL = URL(string: "https://www.rlystate.com/contact-us")!
    
    
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
                    
                    Button("Report", action: {
                        if MFMailComposeViewController.canSendMail() {
                            self.showingMailComposer = true
                        } else {
                            if let url = URL(string: "https://www.rlystate.com/contact-us"), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    })
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
        .sheet(isPresented: $showingMailComposer) {
            MailComposeViewController(subject: "Report Post",
                                      recipients: ["shervin@rlystate.com"],
                                      messageBody: """
                                      <html>
                                      <head>
                                      <style>
                                        body {
                                          font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
                                          color: #444;
                                          max-width: 600px;
                                          margin: auto;
                                          padding: 20px;
                                          background-color: #F9F9F9;
                                          border-radius: 10px;
                                          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                                        }
                                        h2 {
                                          color: #5371FF; /* Updated color */
                                          font-size: 24px;
                                          margin-bottom: 20px;
                                        }
                                        p {
                                          font-size: 16px;
                                          line-height: 1.6;
                                          color: #555;
                                        }
                                        ul {
                                          background-color: #FFF;
                                          padding: 20px;
                                          border: 1px solid #DDD;
                                          border-radius: 8px;
                                          list-style: none;
                                        }
                                        li {
                                          margin-bottom: 10px;
                                          font-size: 16px;
                                          line-height: 1.6;
                                        }
                                        li span {
                                          font-weight: bold;
                                          color: #333;
                                        }
                                        .footer {
                                          margin-top: 20px;
                                          font-size: 14px;
                                          color: #999;
                                          text-align: center;
                                        }
                                        .button {
                                          display: inline-block;
                                          background-color: #5371FF; /* Updated color */
                                          color: #ffffff;
                                          padding: 10px 20px;
                                          border-radius: 5px;
                                          text-decoration: none;
                                          font-weight: bold;
                                          margin-top: 20px;
                                        }
                                      </style>
                                      </head>
                                      <body>
                                      <h2>We're Listening</h2>
                                      <p>Thank you for bringing this to our attention. Your experience and safety are our top priorities. Here's a summary of your report:</p>
                                      <ul>
                                        <li><span>Post:</span> \(post.text)</li>
                                        <li><span>User:</span> \(post.userName)</li>
                                      </ul>
                                      <p>We're on it! Our team will review the details and take appropriate action. We're here to support you.</p>
                                      <p class="footer">Need further assistance? <a href="https://www.rlystate.com/contact-us" class="button">Contact Us</a></p>
                                      </body>
                                      </html>
                                      """,
                                      isHTML: true)
        }
        
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
            
            if let docListener{
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    // Like, Dislike & Share Interaction
    @ViewBuilder
    func PostInteraction()->some View {
        HStack(spacing: 6) {
            Button(action: likePost) {
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }

            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)

            Button(action: dislikePost) {
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading, 25)

            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.trailing, 25)

            // Share Button
            let shareText = "Check out this post on Rlystate: \(post.text)\n\nFor more info: rlystate://post"
            ShareLink(items: [shareText]) {
                Label("", systemImage: "square.and.arrow.up")
            }
            .padding(.bottom, 2)

            // Conditional Comment Button based on isSinglePostMode
            if !isSinglePostMode { // Only show the comment button if not in single post mode
                Button(action: {
                    self.showingCommentView = true
                }) {
                    Image(systemName: "rectangle.3.group.bubble")
                        .foregroundColor(.black) // Adjust color as needed
                }
                .padding(.leading, 20)

                Text("\(commentCount)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.trailing, 20)
                    .onAppear {
                        fetchCommentCount(for: post.id ?? "")
                    }
            }
        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
        // .sheet modifier to present CommentView
        .sheet(isPresented: $showingCommentView) {
            CommentView(post: post, isShowing: $showingCommentView)
        }
    }

    
    /// Liking Post
    func likePost(){
        Task{
            guard let postID = post.id else{return}
            
            do {
                guard let liker = try await fetchUserDetails(by: userUID) else {
                    print("Failed to fetch user details for the liker.")
                    return
                }
            
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
                
                let notification = Notification(
                    postId: postID,
                    type: .likedpost,
                    isRead: false,
                    timestamp: Date(),
                    triggerUserId: liker.userUID, // User who liked the comment
                    triggerUserName: liker.userName, // Replace with actual username if available
                    triggerUserProfileURL: liker.userProfileURL,
                    userName: post.userName,
                    userUID: post.userUID,
                    hiddenFor: []
                )
                
                // Save the notification to Firestore
                await saveNotificationToFirebase(notification: notification)
            }
        } catch {
            print("Error fetching user or saving notification: \(error.localizedDescription)")
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
    
    func saveNotificationToFirebase(notification: Notification) async {
        let firestore = Firestore.firestore()
        let notificationsRef = firestore.collection("Notifications")
        
        do {
            // Convert the Notification model to a dictionary
            let notificationDict = try Firestore.Encoder().encode(notification)
            
            // Add a new document with a generated ID
            let ref = try await notificationsRef.addDocument(data: notificationDict)
            print("Notification saved with ID: \(ref.documentID)")
        } catch {
            print("Error saving notification: \(error.localizedDescription)")
        }
    }
    
    func fetchUserDetails(by userUID: String) async throws -> User? {
        let firestore = Firestore.firestore()
        let userDocRef = firestore.collection("Users").document(userUID)
        
        let documentSnapshot = try await userDocRef.getDocument()
        let user = try documentSnapshot.data(as: User.self)
        return user
    }
    
    
    func fetchCommentCount(for postID: String) {
        let db = Firestore.firestore()
        db.collection("Posts").document(postID).collection("Comments")
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    // Set the comment count
                    DispatchQueue.main.async {
                        // Assuming `self.commentCount` is a property that holds the count
                        self.commentCount = querySnapshot?.documents.count ?? 0
                    }
                }
            }
    }
}

// MARK: - Mock Preview

//struct PostCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockPost = Post(
//            text: "This is a test post for preview editing. 7 Park Ave is where I live. And I like where I live. Living is like nice.",
//            imageURL: URL(string: "https://via.placeholder.com/150"),
//            imageReferenceID: "mockImageRefID",
//            publishedDate: Date(),
//            likedIDs: ["user1", "user2"],
//            dislikedIDs: ["user3"],
//            locationTag: "Mock Location, Earth",
//            latitude: 37.7749,
//            longitude: -122.4194,
//            userName: "Mock User",
//            userUID: "mockUserUID",
//            userProfileURL: URL(string: "https://via.placeholder.com/50")!,
//            hiddenFor: [],
//            tags: ["SwiftUI", "Firebase"]
//        )
//        
//       
//        PostCardView(
//            post: mockPost,
//            onUpdate: { _ in },
//            onDelete: { },
//            onHidePost: { _ in }
//        )
//        .padding()
//        .previewLayout(.sizeThatFits)
//    }
//}

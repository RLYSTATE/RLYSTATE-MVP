//
//  CommentCardView.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/21/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage
import UIKit
import MessageUI
import SafariServices


struct CommentNotification: Codable {
    let commentID: String
    let likedByUserID: String
    let timestamp: Date
}

struct CommentCardView: View {
    var comment: Comment
    var postID: String
    // Callbacks
    var onUpdate: (Comment)->()
    var onDelete: ()->()
    var onHidePost: (_ commentID: String) -> Void
    // View Properties
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var showingMailComposer = false
    @State private var docListener: ListenerRegistration?
    @State private var showSafari = false
    //comment view
    @State private var showingCommentView = false
    //    @State private var safariURL = URL(string: "https://www.rlystate.com/contact-us")!
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: comment.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text(comment.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                    
                HStack{
                    Text(comment.publishedDate.formatted(date: .numeric, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    //                        Text("at \(shortenedLocation)")
                    //                            .font(.caption2)
                    //                            .foregroundColor(.gray)
                    //                            .padding(.leading,-5)
                    
                }
                
                getFormattedCommentText(comment.text)
                                   .textSelection(.enabled)
                                   .padding(.vertical, 8)
                
                
                
                // Post Image if available
                if let postImageURL = comment.imageURL{
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
        
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            // Displaying Delete Button (if it's AUther of that Post)
            Menu {
                if comment.userUID == userUID{
                    
                    Button("Delete Comment",role: .destructive, action: deletePost)
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
                                        <li><span>Post:</span> \(comment.text)</li>
                                        <li><span>User:</span> \(comment.userName)</li>
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
                guard let commentID = comment.id else {return}
                docListener = Firestore.firestore().collection("Posts").document(postID).collection("Comments").document(commentID).addSnapshotListener({ snapshot, error in
                    if let snapshot{
                        if snapshot.exists{
                            // Document Updated
                            // Fetching Updated Document
                            if let updatedComment = try? snapshot.data(as: Comment.self){
                                onUpdate(updatedComment)
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
    func PostInteraction()->some View{
        HStack(spacing: 6){
            Button (action: likeComment){
                Image(systemName: comment.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            .foregroundColor(.black)
            
            Text("\(comment.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button (action: dislikeComment){
                Image(systemName: comment.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .foregroundColor(.black)
            .padding(.leading,25)
            Text("\(comment.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.trailing,25)
                    
        }
    }

    
    /// Liking Comment
    func likeComment() {
        Task {
            guard let commentID = comment.id, !commentID.isEmpty else {
                print("Error: Comment ID is nil or empty")
                return
            }
            
            do {
                guard let liker = try await fetchUserDetails(by: userUID) else {
                    print("Failed to fetch user details for the liker.")
                    return
                }


            if comment.likedIDs.contains(userUID) {
                // Remove like
                try await Firestore.firestore()
                    .collection("Posts").document(postID)
                    .collection("Comments").document(commentID)
                    .updateData(["likedIDs": FieldValue.arrayRemove([userUID])])
            } else {
                // Add like and remove dislike
                try await Firestore.firestore()
                    .collection("Posts").document(postID)
                    .collection("Comments").document(comment.id ?? "")
                    .updateData([
                        "likedIDs": FieldValue.arrayUnion([userUID]),
                        "dislikedIDs": FieldValue.arrayRemove([userUID])
                    ])
                
                // Create a notification object for the user who posted the comment
                
                let notification = Notification(
                    postId: postID,
                    commentId: commentID,
                    type: .likedcomment,
                    isRead: false,
                    timestamp: Date(),
                    triggerUserId: liker.userUID, // User who liked the comment
                    triggerUserName: liker.userName,
                    triggerUserProfileURL: liker.userProfileURL,
                    userName: comment.userName, // User who gets notification
                    userUID: comment.userUID,
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

    /// Disliking Comment
    func dislikeComment() {
        Task {
                guard let commentID = comment.id, !commentID.isEmpty else {
                    print("Error: Comment ID is nil or empty")
                    return
                }
       
            if comment.dislikedIDs.contains(userUID) {
                // Remove dislike
                try await Firestore.firestore()
                    .collection("Posts").document(postID)
                    .collection("Comments").document(comment.id ?? "")
                    .updateData(["dislikedIDs": FieldValue.arrayRemove([userUID])])
            } else {
                // Add dislike and remove like
                try await Firestore.firestore()
                    .collection("Posts").document(postID)
                    .collection("Comments").document(comment.id ?? "")
                    .updateData([
                        "likedIDs": FieldValue.arrayRemove([userUID]),
                        "dislikedIDs": FieldValue.arrayUnion([userUID])
                    ])
            }
        }
    }
    
    ///  Deleting Post
    func deletePost(){
        Task{
            do{
                /// Step 2 Delete Firestore Document
                guard let commentID = comment.id else{return}
                try await Firestore.firestore().collection("Posts").document(postID).collection("Comments").document(commentID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    func hidePost() {
        Task {
            guard let commentID = comment.id else { return }
            
            let userID = self.userUID
            let db = Firestore.firestore()
            let postRef = db.collection("Posts").document(postID).collection("Comments").document(commentID)
            
            do {
                // Hide the post for the current user
                try await postRef.updateData([
                    "hiddenFor": FieldValue.arrayUnion([userID])
                ])
                print("Post hidden successfully for user: \(userID)")
                
                // Call the callback to signal that the post should be removed from the visible list
                DispatchQueue.main.async {
                    self.onHidePost(commentID)
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
    
    
}

func getFormattedCommentText(_ text: String) -> Text {
    var result = Text("")
    let components = text.components(separatedBy: "@")

    if components.count > 1 {
        for (index, component) in components.enumerated() {
            if index == 0 {
                if !component.isEmpty {
                    result = result + Text(component)
                }
            } else {
               
                let subcomponents = component.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                if let firstWord = subcomponents.first {
                    let restOfComponent = component.dropFirst(firstWord.count)
                  
                    let formattedUsername = Text("@").foregroundColor(Color(red: 83 / 255, green: 113 / 255, blue: 255 / 255)) + Text(String(firstWord)).foregroundColor(Color(red: 83 / 255, green: 113 / 255, blue: 255 / 255))
                    let restOfText = Text(String(restOfComponent))
                    result = result + formattedUsername + restOfText
                } else {
                    
                    result = result + Text("@").foregroundColor(.blue)
                }
            }
        }
    } else {
       
        result = Text(text)
    }

    return result
}

// MARK: - Mock Preview

struct CommentCardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockComment = Comment(
            id: "mockCommentID",
            text: "This is a test comment.",
            likedIDs: [], dislikedIDs: [], userName: "Mock User",
            userUID: "mockUserUID",
            userProfileURL: URL(string: "https://via.placeholder.com/50")
        )

        let mockPostID = "mockPostID"

        // mock comment and mock post ID
        CommentCardView(
            comment: mockComment,
            postID: mockPostID,
            onUpdate: { _ in },
            onDelete: { },
            onHidePost: { _ in }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}



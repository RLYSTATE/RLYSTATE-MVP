//
//  ReusableCommentView.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/21/24.
//

import SwiftUI
import Firebase

struct ReusableCommentView: View { 
    var basedOnUID: Bool = false
    var uid: String = ""
    var basedOnLocationTag: Bool = false
    var locationtag: String? = ""
    var post: Post
    @Binding var comments: [Comment]
    // View Properties
    @State private var isFetching: Bool = true
    /// Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top,30)
                }else{
                    if comments.isEmpty{
                        //No Post's Found on Firestore
                        Text("No Rlystate's Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top,30)
                    }else{                        
                        Comments()
                    }
                }
            }
            
        }
        .refreshable {
            /// Scroll to Refresh
            /// Disabling Refresh for UID based Posts
            guard !basedOnUID else{return}
            isFetching = true
            comments = []
            /// - Resetting Pagination Doc
            paginationDoc = nil
            await fetchComments()
        }
        .task {
            // Fetching for One time
            guard comments.isEmpty else{return}
            await fetchComments()
        }
    }
    
    // Displaying Fetched Comments's
    @ViewBuilder
    func Comments() -> some View {
        ForEach(comments) { comment in
            CommentCardView(
                comment: comment,
                postID: post.id ?? "",
                onUpdate: { updatedComment in
                    // Updating Post in the Array
                    if let index = self.comments.firstIndex(where: { $0.id == updatedComment.id }) {
                        self.comments[index].likedIDs = updatedComment.likedIDs
                        self.comments[index].dislikedIDs = updatedComment.dislikedIDs
                    }
                },
                onDelete: {
                    // Removing Comment from the Array
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.comments.removeAll { $0.id == comment.id }
                    }
                },
                onHidePost: { commentIDToRemove in
                    // Removing hidden comment from the Array
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.comments.removeAll { $0.id == commentIDToRemove }
                    }
                })
            .onAppear {
                // Fetch more posts when the last post appears
                if comment.id == self.comments.last?.id && self.paginationDoc != nil {
                    Task {
                        await self.fetchComments()
                    }
                }
            }
            Divider().padding() // Add padding for better visibility
        }
    }
 
    //Fetching Comments
    func fetchComments() async {
        do {
            // Define the base collection reference
            let postCommentsRef = Firestore.firestore().collection("Posts").document(post.id ?? "").collection("Comments")
            
            // Initialize query
            var query: Query!
            print("Starting to fetch comments...") // Initial fetch statement
            
            // Implementing Pagination
            if let paginationDoc = paginationDoc {
                print("Fetching with pagination document...")
                query = postCommentsRef
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            } else {
                print("Fetching without pagination document...")
                query = postCommentsRef
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            
            // Executing the query
            let docsSnapshot = try await query.getDocuments()
            print("Fetched \(docsSnapshot.documents.count) documents.")
            
            // Decoding the fetched documents into Comment models
            let fetchedComments = docsSnapshot.documents.compactMap { queryDocumentSnapshot -> Comment? in
                do {
                
                    let comment = try queryDocumentSnapshot.data(as: Comment.self)
                    print("Fetched comment ID: \(comment.id ?? "nil")")
                    return comment
                    
                } catch {
                    print("Error decoding comment: \(error)")
                    return nil
                }
            }
            
            print("Successfully decoded \(fetchedComments.count) comments.")
            
            // Update the state with the fetched comments
            await MainActor.run {
                self.comments.append(contentsOf: fetchedComments)
                self.paginationDoc = docsSnapshot.documents.last
                self.isFetching = false
            }
        } catch {
            print("Failed to fetch comments with error: \(error.localizedDescription)")
            // Update the state to indicate that fetching has finished
            await MainActor.run {
                self.isFetching = false
            }
        }
    }
    
    
}
    
struct ReusableCommentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

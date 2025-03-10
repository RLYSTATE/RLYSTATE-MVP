//
//  ReusablePostView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/28/23.
//

import SwiftUI
import Firebase

struct ReusablePostView: View {
    var basedOnUID: Bool = false
    var uid: String = ""
    var basedOnLocationTag: Bool = false
    var locationtag: String? = ""
    @Binding var posts: [Post]
    // View Properties
    @State private var isFetching: Bool = true
    /// Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    /// comment post view
    var isSinglePostMode: Bool = false
    var singlePost: Post? = nil // Optional single post for detailed view
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top,30)
                }else{
                    if posts.isEmpty{
                        //No Post's Found on Firestore
                        Text("No Rlystate's Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top,30)
                    }else{
                        // Displaying Posts
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            /// Scroll to Refresh
            /// Disabling Refresh for UID based Posts
            guard !basedOnUID else{return}
            isFetching = true
            posts = []
            /// - Resetting Pagination Doc
            paginationDoc = nil
            await fetchPosts()
        }
        .task {
            // Check if we're in single post mode and have a valid singlePost
            if isSinglePostMode, let singlePost = singlePost {
                // Directly set the posts array to contain only the singlePost
                // This ensures the view immediately has the correct data to render
                await MainActor.run {
                    self.posts = [singlePost]
                    isFetching = false
                }
                print("Single post mode, displaying the provided post.")
            } else if posts.isEmpty {
                // If not in single post mode and posts array is empty, fetch posts
                await fetchPosts()
            }
        }
    }
    
    // Displaying Fetched Post's
    @ViewBuilder
    func Posts() -> some View {
        if isSinglePostMode {
            // When in single post mode, we expect `singlePost` to be non-nil.
            if let post = singlePost {
                // Display details for the single post.
                PostCardView(post: post,
                             onUpdate: { updatedPost in
                                 // Updating Post in the Array.
                                 if let index = self.posts.firstIndex(where: { $0.id == updatedPost.id }) {
                                     self.posts[index].likedIDs = updatedPost.likedIDs
                                     self.posts[index].dislikedIDs = updatedPost.dislikedIDs
                                 }
                             },
                             onDelete: {
                                 // Removing Post from the Array.
                                 withAnimation(.easeInOut(duration: 0.25)) {
                                     self.posts.removeAll { $0.id == post.id }
                                 }
                             },
                             onHidePost: { postIDToRemove in
                                 // Removing hidden post from the Array.
                                 withAnimation(.easeInOut(duration: 0.25)) {
                                     self.posts.removeAll { $0.id == postIDToRemove }
                                 }
                             }, isSinglePostMode: isSinglePostMode)
            } else {
                // Fallback text if for some reason `singlePost` is nil.
                Text("Post not found")
            }
        } else {
            // Handle multiple posts case.
            ForEach(posts) { post in
                PostCardView(post: post,
                             onUpdate: { updatedPost in
                                 if let index = self.posts.firstIndex(where: { $0.id == updatedPost.id }) {
                                     self.posts[index].likedIDs = updatedPost.likedIDs
                                     self.posts[index].dislikedIDs = updatedPost.dislikedIDs
                                 }
                             },
                             onDelete: {
                                 withAnimation(.easeInOut(duration: 0.25)) {
                                     self.posts.removeAll { $0.id == post.id }
                                 }
                             },
                             onHidePost: { postIDToRemove in
                                 withAnimation(.easeInOut(duration: 0.25)) {
                                     self.posts.removeAll { $0.id == postIDToRemove }
                                 }
                             }, isSinglePostMode: isSinglePostMode)
                .onAppear {
                    if post.id == self.posts.last?.id && self.paginationDoc != nil {
                        Task {
                            await self.fetchPosts()
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal, -15)
            }
        }
    }
 
    //Fetching Posts
func fetchPosts()async{
    print("Starting to fetch posts...")
    do{
        var query: Query!
        /// - Implementing Pagination
        if let paginationDoc{
            query = Firestore.firestore().collection("Posts")
                .order(by:"publishedDate", descending: true)
                .start(afterDocument: paginationDoc)
                .limit(to: 20)
        }else{
            query = Firestore.firestore().collection("Posts")
                .order(by:"publishedDate", descending: true)
                .limit(to: 20)
        }
        
        /// - New Query For UID Based Document Fetch
        /// - Filter the Posts Which is not beloning to this UID
        if basedOnUID{
            query = query
                .whereField("userUID", isEqualTo: uid)
        }
        
        ///New Query for Location Tag Docs
        ///Filter posts which do not belong to this Location Tag
        if basedOnLocationTag{
            query = query
                .whereField("locationTag", isEqualTo: locationtag ?? "location")
        }
        

        let docs = try await query.getDocuments()
        let fetchedPosts = docs.documents.compactMap { doc -> Post? in
            try? doc.data(as: Post.self)
        }

        let currentUserUID = self.uid
        let postsToShow = fetchedPosts.filter { post in
            !(post.hiddenFor?.contains(currentUserUID) ?? false)
        }

        await MainActor.run {
            self.posts.append(contentsOf: postsToShow)
            paginationDoc = docs.documents.last
            isFetching = false
        }
        print("Fetched posts count: \(fetchedPosts.count)")
    }catch{
        print(error.localizedDescription)
        }
    }
}
    
struct ReusablePostView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

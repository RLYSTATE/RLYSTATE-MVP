//
//  PostsView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/27/23.
//

import SwiftUI
import FirebaseAnalytics

struct PostsView: View {
    @State private var recentPosts: [Post] = []
    @State private var createNewPost: Bool = false
    var body: some View {
        NavigationStack{
            ReusablePostView(posts: $recentPosts)
                .hAlign(.center).vAlign(.center)
                .overlay(alignment: .bottomTrailing) {
                    Button(action: {
                        // Log the button click with Firebase Analytics
                        Analytics.logEvent("create_post_button_clicked", parameters: [
                            "screen": "PostsView",
                            "time": Date().description
                        ])
                        // Toggle the state to show create post view
                        createNewPost.toggle()
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(13)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .black, radius: 4)
                    }
                    .padding(15)
                }
                .navigationTitle("Post's")
        }
        .fullScreenCover(isPresented: $createNewPost) {
            CreateNewPost { post in
                /// adding created posts at the top of recent posts
                recentPosts.insert(post, at: 0)
            }
        }
    }
}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}

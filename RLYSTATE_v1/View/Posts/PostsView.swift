//
//  PostsView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/27/23.
//

import SwiftUI
import FirebaseAnalytics
import FirebaseFirestore
import FirebaseAuth

struct PostsView: View {
    @State private var recentPosts: [Post] = []
    @State private var createNewPost: Bool = false
    //tags
    @State private var topTags: [String] = []
    @State private var selectedTag: String?
    //Notificaitons
    @State private var notificationsCount: Int = 0
    @State private var navigateToNotifications = false
    @State private var docListener: ListenerRegistration?
    
    
    
    var notificationIconWithCount: some View {
          ZStack(alignment: .topTrailing) {
              Image(systemName: "person.wave.2")
                  .foregroundColor(.primary)
              
              if notificationsCount > 0 {
                  Text("\(notificationsCount)")
                      .font(.caption2)
                      .padding(5)
                      .foregroundColor(.white)
                      .background(Color.red)
                      .clipShape(Circle())
                      .offset(x: 10, y: -10)
              }
          }
      }
      
    
    
    
    var body: some View {
        NavigationStack{
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(topTags, id: \.self) { tag in
                            Text("\(tag)")
                            .font(.system(size: 14))
                           .padding(.vertical, 4)
                           .padding(.horizontal, 8)
                           .foregroundColor(selectedTag == tag ? .black : .gray)
                           .background(Capsule().fill(Color.clear))
                           .overlay(
                               Capsule().stroke(selectedTag == tag ? Color.blue : Color.gray, lineWidth: 1)
                           )
                           .onTapGesture {
                               if selectedTag == tag {
                                  
                                   selectedTag = nil
                                   fetchAllPosts()
                               } else {
                          
                                   selectedTag = tag
                                   fetchPostsByTag(tag)
                               }
                           }
                        }
                    }
                    .padding(.leading, 22)
                }
                .padding(.vertical)
                
                
                ReusablePostView(posts: $recentPosts)
                    .hAlign(.center).vAlign(.center)
                    .overlay(alignment: .bottomTrailing) {
                        Button(action: {
                            Analytics.logEvent("create_post_button_clicked", parameters: [
                                "screen": "PostsView",
                                "time": Date().description
                            ])
                           
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
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // Call the function to mark notifications as read and navigate
                                markNotificationsAsReadAndNavigate()
                            }) {
                                notificationIconWithCount
                            }
                        }
                    }
                    .navigationTitle("Post's")
                    .onAppear {
                            fetchTopTags()
                            fetchAllPosts()
                            fetchNotificationCount()
                            
                        }
            }
            .fullScreenCover(isPresented: $navigateToNotifications) {
                NavigationView {
                    NotificationView()
                        .navigationBarItems(leading: Button("Back") {
                            navigateToNotifications = false
                        })
                }
                .transition(.move(edge: .trailing)) // Custom transition: slide from right to left
            }
            .fullScreenCover(isPresented: $createNewPost) {
                CreateNewPost { post in
                    /// adding created posts at the top of recent posts
                    recentPosts.insert(post, at: 0)
                    fetchTopTags()
                }
            }
        }
    }
    func fetchTopTags() {
        // tag fetch
        Firestore.firestore().collection("Posts").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("No documents in Firestore match the query.")
                return
            }
            let tags: [String] = documents.compactMap { document in
                let post = try? document.data(as: Post.self)
                return post?.tags
            }.flatMap { $0 }
            
            let tagCounts = Dictionary(grouping: tags, by: { $0 }).mapValues { $0.count }
            let sortedTags = tagCounts.sorted { $0.value > $1.value }.map { $0.key }
            topTags = Array(sortedTags.prefix(5))
        }
    }
    
    func fetchPostsByTag(_ tag: String) {
            Firestore.firestore().collection("Posts")
                .whereField("tags", arrayContains: tag)
                .order(by: "publishedDate", descending: true)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("Error fetching posts by tag: \(error)")
                        return
                    }

                    // Update recentPosts with posts containing the selected tag
                    let postsByTag = snapshot?.documents.compactMap { document -> Post? in
                        try? document.data(as: Post.self)
                    }
                    if let postsByTag = postsByTag {
                        self.recentPosts = postsByTag
                    }
                }
        }
    
    func fetchAllPosts() {
        Firestore.firestore().collection("Posts")
            .order(by: "publishedDate", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching all posts: \(error)")
                    return
                }
                
                let allPosts = snapshot?.documents.compactMap { document -> Post? in
                    try? document.data(as: Post.self)
                }
                
                DispatchQueue.main.async {
                    if let allPosts = allPosts, allPosts.isEmpty {
                        print("Fetched all posts but the array is empty")
                    } else {
                        self.recentPosts = allPosts ?? []
                    }
                }
            }
    }
    
    func fetchNotificationCount() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        docListener = db.collection("Notifications")
          .whereField("userUID", isEqualTo: userUID)
          .whereField("isRead", isEqualTo: false) // Add this condition to fetch only unread notifications
          .addSnapshotListener { snapshot, error in
              if let error = error {
                  print("Error getting notifications count: \(error)")
                  return
              }
              let count = snapshot?.documents.count ?? 0
              DispatchQueue.main.async {
                  self.notificationsCount = count
              }
          }
    }
    
    func markNotificationsAsReadAndNavigate() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        
        // Start updating the notifications as read in Firestore
        let db = Firestore.firestore()
        db.collection("Notifications")
            .whereField("userUID", isEqualTo: userUID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error marking notifications as read: \(error)")
                    return
                }
                
                // Update each notification as read
                for document in snapshot!.documents {
                    db.collection("Notifications").document(document.documentID).updateData(["isRead": true])
                }
                
                // After marking notifications, reset the count and trigger navigation
                DispatchQueue.main.async {
                    self.notificationsCount = 0
                    self.navigateToNotifications = true
                }
            }
        }
    }

    struct PostsView_Previews: PreviewProvider {
        static var previews: some View {
            PostsView()
        }
    }

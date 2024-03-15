//
//  AnnotationPostView.swift
//  RLYSTATE_v1
//
//  Created by Jarmar Ledesma on 1/8/24.
//

import SwiftUI

struct AnnotationPostView: View {
    var post: Post
    @State private var fetchedPosts: [Post] = []
    @Binding var isShowing: Bool
    @State private var showingCreateNewPostView = false
    
    
    
    var body: some View {
        VStack{
            HStack{
                VStack (alignment: .leading) {
                    if let locationTag = post.locationTag {
                        let components = locationTag.components(separatedBy: ",")
                        let shortenedLocation = components.prefix(1).joined(separator: ",")
                        let shortenedLocationName = components.dropFirst().joined(separator: ",")
                        
                        Text(shortenedLocation)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.leading,15)
                        
                        Text(shortenedLocationName)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                            .padding(.trailing)
                            .padding(.leading,15)
                        }
                    }
                Spacer ()
                
                Button(action: {
                    withAnimation {
                        print("Dismiss button tapped")
                        self.isShowing = false // Dismiss AnnotationPostView Return to Map
                    }
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(Color(UIColor.black))
                        .padding()
                }
                    }
            PostDetailsView(post:post)
            
            ReusablePostView(basedOnLocationTag: true, locationtag: post.locationTag, posts: $fetchedPosts)
            
            Button(action: {
                       self.showingCreateNewPostView = true
                   }) {
                       HStack {
                           Text("Got something to add? Rlystate...")
                               .foregroundStyle(.gray)
                           
                           Spacer()
                           
                           Image(systemName: "arrow.up.left.and.arrow.down.right")
                               .padding(.trailing,10)
                       }
                       .padding(10)
                       .background(RoundedRectangle(cornerRadius: 45).strokeBorder(Color.gray.opacity(0.5), lineWidth: 2))
                       .padding(.horizontal,10)
                   }
                   .buttonStyle(PlainButtonStyle())
        

                }
        .background(Color.white)
        .sheet(isPresented: $showingCreateNewPostView) {
            CreateNewPost(onPost: { newPost in
                self.fetchedPosts.append(newPost)
                self.showingCreateNewPostView = false
            }, initialLocationTag: post.locationTag) // passing the locationTag
        }
                 }
             }
       



struct AnnotationPostView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock post object with the necessary details
        let mockPost = Post(id: "1", text: "Test Post", locationTag: "7 Park Ave, New York, NY, United States", userName: "User", userUID: "UID", userProfileURL: URL(string: "https://example.com")!)

        // Use a .constant binding for the preview
        AnnotationPostView(post: mockPost, isShowing: .constant(true))
    }
}

//
//  ReusableProfileContent.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/27/23.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReusableProfileContent: View {
    @State private var fetchedPosts: [Post] = []
    var user: User
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                HStack(spacing: 12){
                    WebImage(url: user.userProfileURL).placeholder{
                        // Placeholder image
                        Image("NullProfile")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height:100)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading,spacing: 6) {
                        Text(user.userName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(user.userBio)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                        }
                    .hAlign(.leading)
                     }
                
                Text("Post's")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .hAlign(.leading)
                    .padding(.vertical,15)
                
                ReusablePostView(basedOnUID: true, uid: user.userUID, posts: $fetchedPosts)
                
                }
                .padding(15)
            }
        }
    }

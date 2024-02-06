//
//  TabBar.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 2/5/24.
//

import SwiftUI

enum Tab {
    case posts
    case search
    case profile
}

struct TabBar: View {
    @State private var selectedTab: Tab = .posts

    var body: some View {
        TabView(selection: $selectedTab) {
            PostsView()
                .tabItem {
                    Label("Posts", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
                }
                .tag(Tab.posts)
            
            MapView()
                .environmentObject(LocationSearchViewModel())
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(.black) // Changing Tab Label Tint to Black
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}



// Preview for TabBar
struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar()
    }
}

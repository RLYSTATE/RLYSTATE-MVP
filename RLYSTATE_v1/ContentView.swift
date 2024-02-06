//
//  ContentView.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 12/8/23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    @State private var shouldShowPostsView = false

    var body: some View {
        Group {
            if logStatus {
                if shouldShowPostsView {
                    PostsView() // Navigate to PostsView
                } else {
                    MainView() // Default view
                }
            } else {
                LandingView()
            }
        }
        .onOpenURL { url in
            // Just check if the URL is of the expected format
            if url.scheme == "rlystate" && url.host == "post" {
                shouldShowPostsView = true
            }
        }
    }
}

// Preview Provider
struct ContentView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

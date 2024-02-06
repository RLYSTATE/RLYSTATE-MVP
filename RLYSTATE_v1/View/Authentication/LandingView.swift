//
//  LandingView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/19/23.
//

import SwiftUI

struct LandingView: View {
    @State private var isActive = false
    @State private var isLoggedIn = false // This should be determined by your authentication logic
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        Group {
            if isActive {
                if isLoggedIn {
                    MainView() // User is logged in, show the main view
                } else {
                    LoginView() // User is not logged in, show the login view
                }
            } else {
                ZStack {
                    Color.white.edgesIgnoringSafeArea(.all)
                    VStack {
                        Image("Rlystate")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 330, height: 205)
                            .padding(.bottom,120)
                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                }
                .onAppear {
                    withAnimation(.easeIn(duration: 0.6)) {
                        self.size = 1
                        self.opacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation{
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}


// Preview
struct LandingView_Preview: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}

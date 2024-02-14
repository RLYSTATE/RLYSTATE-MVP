//
//  RLYSTATE_v1App.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 12/8/23.
//

// RLYSTATE_v1App.swift
import SwiftUI
import Firebase

@main
struct Rlystate_V2App: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Track app open
                    Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
                }
        }
    }
}

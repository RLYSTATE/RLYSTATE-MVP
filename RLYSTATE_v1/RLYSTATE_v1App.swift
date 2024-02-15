//
//  RLYSTATE_v1App.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 12/8/23.
//

// RLYSTATE_v1App.swift
import SwiftUI
import UIKit
import Firebase
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct Rlystate_V2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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

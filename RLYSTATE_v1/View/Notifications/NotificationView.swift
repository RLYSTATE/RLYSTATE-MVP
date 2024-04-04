//
//  Notification.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/26/24.
//

import SwiftUI
import FirebaseAuth

struct NotificationView: View {
    @State private var fetchedComments: [Comment] = []
    @State private var fetchedPosts: [Post] = []
    @State private var notifications: [Notification] = []
    
    
    var userUID: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    var body: some View {
           ReusableNotificationView(userUID: userUID) {
//               withAnimation(.easeInOut(duration: 0.25)) {
//                   self.notifications.removeAll { $0.id == $0.id }
               }
           }
       }

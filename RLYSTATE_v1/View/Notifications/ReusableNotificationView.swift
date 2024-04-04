//
//  ReusableNotificationView.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/26/24.
//

import SwiftUI
import Firebase

struct ReusableNotificationView: View {
    var basedOnUID: Bool = false
    // View Properties
    @State private var isFetching: Bool = true
    /// Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    @State private var docListener: ListenerRegistration?
    //notificaitons
    var userUID: String
    @State private var notifications: [Notification] = []
    var onDelete: ()->()
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top,30)
                }else{
                    if notifications.isEmpty {
                        //No Post's Found on Firestore
                        Text("No Notifications Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top,30)
                    }else{
                        NotificationFeed()
                    }
                }
            }
            
        }
        .refreshable {
            /// Scroll to Refresh
            /// Disabling Refresh for UID based Posts
            guard !basedOnUID else{return}
            isFetching = true
            notifications = []
            /// - Resetting Pagination Doc
            paginationDoc = nil
            await fetchNotifications(for: userUID)
        }
        .task {
            // Fetching for One time
            guard notifications.isEmpty else{return}
            await fetchNotifications(for: userUID)
        }
    }
    
    // Displaying Fetched Mentions in Comments's
    @ViewBuilder
    func NotificationFeed() -> some View {
        ForEach(notifications) { notification in
            NotificationCardView(
                notification: notification, 
                onMenuSelect: {menuOption in
                    switch menuOption{
                    case.delete:
                        print("Delete Notification")
                    case.hide:
                        print("Hide Notification")
                    case.report:
                        print("Report Notification")
                    }},
                onUpdate: { updatednotification in
                    //need to add update logic
                },
                onDelete:  {
                    // Removing Comment from the Array
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.notifications.removeAll { $0.id == notification.id }
                    }
                })
            .onAppear {
                if docListener == nil {
                    
                    // Fetch more notifications when the last one appears
                    if notification.id == self.notifications.last?.id && self.paginationDoc != nil {
                        Task {
                            await self.fetchNotifications(for: userUID)
                        }
                    } else {
                        onDelete()
                    }
                }
            }
        }
    }
    
    func fetchNotifications(for userUID: String) async {
        guard !userUID.isEmpty else {
            print("User UID is empty")
            return
        }

        isFetching = true
        let notificationsRef = Firestore.firestore().collection("Notifications")
        let query = notificationsRef
                            .whereField("userUID", isEqualTo: userUID)
                            .order(by: "timestamp", descending: true)
                            .limit(to: 20)

        do {
            let querySnapshot = try await query.getDocuments()
            let fetchedNotifications = querySnapshot.documents.compactMap { document -> Notification? in
                try? document.data(as: Notification.self)
            }
            await MainActor.run {
                self.notifications = fetchedNotifications
                isFetching = false
            }
        } catch {
            print("Error fetching notifications: \(error)")
            isFetching = false
        }
    }
    
}


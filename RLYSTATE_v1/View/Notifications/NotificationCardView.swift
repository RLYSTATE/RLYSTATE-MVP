//
//  NotificationCardView.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/26/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage
import UIKit
import MessageUI
import SafariServices

struct NotificationCardView: View {
    var notification: Notification
    var onMenuSelect: (MenuOption) -> Void
    var onUpdate: (Notification)->()
    var onDelete: ()->()
    @State private var docListener: ListenerRegistration?
    
    
    enum MenuOption {
        case delete
        case hide
        case report
    }
    
    enum NotificationType: String, Codable {
        case likedcomment
        case likedpost
    }

    var notificationMessage: String {
           switch notification.type {
           case .likedcomment:
               return "\(notification.triggerUserName) liked your comment!"
           case .likedpost:
               return "\(notification.triggerUserName) liked your post!"
           default:
               return "\(notification.triggerUserName) mentioned you!"// Fallback message
           }
       }
    
    var body: some View {
            HStack {
                WebImage(url: notification.triggerUserProfileURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                Text(notificationMessage) // Adjusted to use the message or a placeholder
                    .font(.caption)
                    .foregroundColor(.primary)

                Spacer()

                Menu {
                    Button("Delete Notification", role: .destructive) {
                        deleteNotification()
                    }
                   
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
                .onAppear {
                    // when the post is visible on the screen, the doc listener is added, otherwise listener is removed
                    if docListener == nil {
                        guard let notificationID = notification.id else {return}
                        docListener = Firestore.firestore().collection("Notifications").document(notificationID).addSnapshotListener({ snapshot, error in
                            if let snapshot{
                                if snapshot.exists{
                                    // Document Updated
                                    // Fetching Updated Document
                                    if let updatedNotification = try? snapshot.data(as: Notification.self){
                                        onUpdate(updatedNotification)
                                    }
                                }else{
                                    /// Document Deleted
                                    onDelete()
                                }
                            }
                        })
                    }
                }
                .onDisappear {
                    
                    if let docListener{
                        docListener.remove()
                        self.docListener = nil
                    }
                }
                
                
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 2)
        }
    
    
    func deleteNotification() {
        guard let notificationID = notification.id else {
            print("Notification ID is missing")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Notifications").document(notificationID).delete { error in
            if let error = error {
                print("Error deleting notification: \(error.localizedDescription)")
            } else {
                print("Notification successfully deleted")
                
                // Call the onDelete closure to trigger UI update
                onMenuSelect(.delete)
            }
        }
    }
   }

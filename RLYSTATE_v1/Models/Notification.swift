//
//  Notification.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 4/2/24.
//

import SwiftUI
import FirebaseFirestoreSwift
import Foundation

enum NotificationType: String, Codable {
    case mention
    case likedcomment
    case likedpost
}

struct Notification: Identifiable, Codable, Equatable {
    @DocumentID var id: String? 
    var postId: String // ID of the post related to notification
    var commentId: String?
    var type: NotificationType // type of notification
    var isRead: Bool // whether the notification has been read
    var timestamp: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    // user who triggered the notification
    var triggerUserId: String
    var triggerUserName: String
    var triggerUserProfileURL: URL
    // message or context for the notification
    var message: String?
    // User profile
    var userName: String
    var userUID: String
    var hiddenFor: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId
        case commentId
        case type
        case isRead
        case timestamp
        case likedIDs
        case dislikedIDs
        case triggerUserId
        case triggerUserName
        case triggerUserProfileURL
        case message
        case userName
        case userUID
        case hiddenFor
    }
}

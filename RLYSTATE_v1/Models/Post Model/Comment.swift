//
//  Comment.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/20/24.
//

import SwiftUI
import FirebaseFirestoreSwift
import Foundation

struct Comment: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String? // Firestore document ID
    var text: String
    var imageURL: URL? // Store as String for Firestore
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    var locationTag: String?
    var latitude: Double?
    var longitude: Double?
    // User profile
    var userName: String
    var userUID: String
    var userProfileURL: URL?
    var hiddenFor: [String]?
    /// Tags
    var tags: [String]?
    // Mentions
    var mentions: [String]?
    

    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case imageURL
        case publishedDate
        case likedIDs
        case dislikedIDs
        case locationTag
        case latitude
        case longitude
        case userName
        case userUID
        case userProfileURL
        case hiddenFor
        case tags
        case mentions
    }
}

import SwiftUI
import FirebaseFirestoreSwift
import Foundation

struct Post: Identifiable, Codable, Equatable,Hashable {
    @DocumentID var id: String?
    var text: String
    var imageURL: URL? 
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    var locationTag: String?
    var latitude: Double?
    var longitude: Double?
    // User profile
    var userName: String
    var userUID: String
    var userProfileURL: URL
    var hiddenFor: [String]?
    /// Tags
    var tags: [String]?
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case imageURL
        case imageReferenceID 
        case publishedDate
        case likedIDs
        case dislikedIDs
        case locationTag
        case longitude
        case latitude
        case userName
        case userUID
        case userProfileURL
        case hiddenFor
        case tags
    }
}



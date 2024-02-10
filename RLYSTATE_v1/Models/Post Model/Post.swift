import SwiftUI
import FirebaseFirestoreSwift

struct Post: Identifiable, Codable, Equatable,Hashable {
    @DocumentID var id: String?
    var text: String
    var imageURL: URL? // Store as String for Firestore
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case imageURL
        case imageReferenceID // Make sure this matches the property name
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
    }
}


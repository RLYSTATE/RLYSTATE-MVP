//
//  User.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/26/23.
//

import SwiftUI
import FirebaseFirestoreSwift

struct User: Identifiable,Codable {
    @DocumentID var id: String?
    var userName: String
    var userBio: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey {
        case id
        case userName
        case userBio
        case userUID
        case userEmail
        case userProfileURL
    }
}

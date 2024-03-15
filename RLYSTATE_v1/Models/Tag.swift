//
//  Tag.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/11/24.
//

import SwiftUI

// Tag Model
struct Tag: Codable, Identifiable, Hashable {
    var id: UUID = .init()
    var value: String
    var isInitial: Bool = false
}

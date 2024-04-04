//
//  LoginIntro.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 1/11/24.
//

import SwiftUI

struct LoginIntro: Identifiable {
    var id: UUID = .init()
    var text: String
    var textColor: Color
    var lineColor: Color
    var bgColor: Color
    var lineOffset: CGFloat = 0
    var textOffset: CGFloat = 0
}

/// Sample Intro
var authIntros: [LoginIntro] = [
    .init(
        text: " RLYSTATE Reality   ",
        textColor: .color2,
        lineColor: .color1,
        bgColor: .color3
    ),
    .init(
        text: " RLYSTATE It Loud   ",
        textColor: .color3,
        lineColor: .color2,
        bgColor: .color1
    ),
    .init(
        text: " RLYSTATE Your Space   ",
        textColor: .color1,
        lineColor: .color3,
        bgColor: .color2
    ),
    .init(
        text: " RLYSTATE Reality   ",
        textColor: .color2,
        lineColor: .color1,
        bgColor: .color3
    ),
]

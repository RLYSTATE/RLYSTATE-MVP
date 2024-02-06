//
//  MainView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/27/23.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        // TabView with Recent Posts and Profile Tabs
        TabBar()
        // Changing Tab Label Tint to Black
        .tint(.black)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

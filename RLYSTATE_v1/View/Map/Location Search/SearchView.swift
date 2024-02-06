//
//  SearchView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/20/23.
//

import SwiftUI

struct SearchView: View {
    
    var body: some View {
        // Search bar container
        HStack {
            Text("Search for a location...")
                .foregroundColor(.gray) // Set text color
                .padding(.leading)
            
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width - 64, height: 50)
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: .black, radius: 6)
        )
    }
}
        
struct SearchView_Previews: PreviewProvider{
    static var previews: some View {
        SearchView()
    }
}

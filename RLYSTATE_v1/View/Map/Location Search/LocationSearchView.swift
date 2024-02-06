//
//  LocationSearchView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/19/23.
//

import SwiftUI

struct LocationSearchView: View {
    @EnvironmentObject var viewModel: LocationSearchViewModel
    @Binding var mapState: MapViewState
    
    var body: some View {
        VStack {
            // Search bar container
            HStack {
                TextField("Search for a location...", text:
                $viewModel.queryFragment)
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
            .padding(.top, 75) // Add top padding here
            
            Divider()
                .padding(.vertical)
            
            // List view
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(viewModel.results, id: \.self) { result in
                        LocationSearchResultsCell(title: result.title, subtitle: result.subtitle)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    viewModel.selectLocation(result)
                                    mapState = .locationSelected
                                }
                                
                            }
                    }
                }
            }
        }
        .background(.white)
    }
}


struct LocationSearchView_Previews: PreviewProvider{
    static var previews: some View {
        LocationSearchView(mapState: .constant(.searchingForLocation))
    }
}

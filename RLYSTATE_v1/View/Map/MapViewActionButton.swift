//
//  MapViewActionButton.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/20/23.
//

import SwiftUI

struct MapViewActionButton: View {
    @Binding var mapState: MapViewState
    
    var body: some View {
            Button {
                withAnimation(.spring()) {
                    actionForState(mapState)
                }
            } label: {
                if imageNameForState(mapState) != nil {
                    // Render image only if image name is not nill
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding()
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .black, radius: 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    func actionForState(_ state: MapViewState) {
        switch state {
        case .noInput:
            print("DEBUG: No input")
        case.searchingForLocation:
            mapState = .noInput
        case.locationSelected:
            mapState = .noInput
            print("DEBUG: Clear Map View..")
           
        }
    }
    func imageNameForState(_ state: MapViewState) -> String? {
        switch state {
        case .noInput:
            return nil
        case .searchingForLocation, .locationSelected:
            return "arrow.left"
        }
    }
}

struct MapViewActionButton_Preview: PreviewProvider {
    static var previews: some View {
        MapViewActionButton(mapState: .constant(.noInput))
    }
}

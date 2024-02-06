//
//  MapView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/19/23.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var mapState = MapViewState.noInput
    @State private var selectedPost: Post? = nil // To hold the selected post
    @State private var showingDetail = false     // To control the visibility of the detail view
    
    var body: some View {
        ZStack (alignment: .bottom) {
            ZStack (alignment: .top) {
                MapViewRepresentable(mapState: $mapState, onAnnotationSelected: { post in
                                  print("DEBUG: Post selected: \(post.text)")
                                  self.selectedPost = post
                                  self.showingDetail = true
                              })
                    .ignoresSafeArea()
                
                if mapState == .searchingForLocation {
                    LocationSearchView(mapState: $mapState)
                } else if mapState == .noInput {
                    SearchView()
                        .padding(.top, 75)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                mapState = .searchingForLocation
                            }
                        }
                }
                MapViewActionButton(mapState: $mapState)
                                   .padding(.leading)
                                   .padding(.top,4)
                               if showingDetail, let post = selectedPost {
                                   Group {
                                       // Use a side effect to print the message
                                       EmptyView().onAppear {
                                           print("DEBUG: Showing detail for post: \(post.text)")
                                       }
                                       
                                       // Display the AnnotationPostView
                                       AnnotationPostView(post: post, isShowing: $showingDetail) // <-- Pass the binding here
                                                   .transition(.move(edge: .bottom))
                                           .onTapGesture {
                                               print("DEBUG: Hiding detail view")
                                               self.showingDetail = true
                                           }
                                   }
                                   .onDisappear {
                                       print("DEBUG: Detail view for post \(post.text) has disappeared.")
                                   }
                               }

                           }
            
            if mapState == .locationSelected {
                DetailsView()
                    .frame(maxWidth: .infinity, maxHeight: 330)
                                     .background(Color.white) // Semi-transparent background
                                     .transition(.move(edge: .bottom)) // Animation for the transition
                                     .zIndex(1)
            }
        }
        
    }
}
    
    struct MapView_Previews: PreviewProvider {
        static var previews: some View {
            MapView()
        }
    }

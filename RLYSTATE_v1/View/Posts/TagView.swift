//
//  TagView.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/11/24.
//

import SwiftUI

struct TagView: View {
    @Binding var tags: [Tag]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    TagField(tags: $tags)
                }
                .padding()
            }
            .navigationTitle("Add Tag")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
            // No need for .onAppear to load tags as they are now directly managed and passed in
        }
    }
}
//#Preview {
//    TagView()
//}

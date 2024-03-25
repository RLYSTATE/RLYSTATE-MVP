//
//  CommentView.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/20/24.
//

import SwiftUI
import FirebaseFirestore


struct CommentView: View {
    var post: Post
    @State private var fetchedPosts: [Post] = []
    @State private var fetchedComments: [Comment] = []
    @Binding var isShowing: Bool
    // Stored User Data From UserDefaults(AppStorage)
    @AppStorage("user_profile_url") private var userProfileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    // comments
    @State private var newCommentText: String = ""
    @State var text = ""
    @State var height : CGFloat = 0
    @State private var isShowingUserSearch = false
    
    
    
    
    var body: some View {
        VStack{
            HStack{
                VStack (alignment: .leading) {
                    if let locationTag = post.locationTag {
                        let components = locationTag.components(separatedBy: ",")
                        let shortenedLocation = components.prefix(1).joined(separator: ",")
                        let shortenedLocationName = components.dropFirst().joined(separator: ",")
                        
                        Text(shortenedLocation)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.leading,15)
                        
                        Text(shortenedLocationName)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                            .padding(.trailing)
                            .padding(.leading,15)
                    }
                }
                Spacer ()
                
                Button(action: {
                    withAnimation {
                        print("Dismiss button tapped")
                        self.isShowing = false // Dismiss AnnotationPostView Return to Map
                    }
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(Color(UIColor.black))
                        .padding()
                }
                
            }
//            PostDetailsView(post:post)
            ScrollView{
                ReusablePostView(posts: $fetchedPosts, isSinglePostMode: true, singlePost: post)
                
                ReusableCommentView(post: post, comments: $fetchedComments)
                    .padding(.horizontal,12)
            }
            
            //comment box - to UPDATE
            HStack(spacing: 8){
                ResizableTextView(onAtSymbolDetected: {
                    self.isShowingUserSearch = true
                }, text: $newCommentText, height: self.$height)
                    .frame(height: 30)
                    .padding(.horizontal)
//                    .background(Color.gray)
                    .cornerRadius(15)
                    .overlay(
                             Capsule().stroke(Color.black, lineWidth: 1) // Black line stroke
                         )
                         .padding(.horizontal, 4) // Optional: Adjust for external padding
                         
                            
                
                Button("Post") {
                    Task {
                        do {
                            // Ensure user details are not nil or empty
                            guard !userUID.isEmpty, !userName.isEmpty, let profileURL = userProfileURL else {
                                print("User details are incomplete")
                                return
                            }

                            // Create a reference for a new comment, Firestore generates the ID at this point
                            let newCommentRef = Firestore.firestore().collection("Posts").document(post.id ?? "").collection("Comments").document()

                            // Create a new comment object with the necessary data, including the generated document ID
                            let newComment = Comment(id: newCommentRef.documentID, text: newCommentText, userName: userName, userUID: userUID, userProfileURL: profileURL)

                            // Set the comment data in Firestore
                            try newCommentRef.setData(from: newComment)

                            DispatchQueue.main.async {
                                        self.fetchedComments.insert(newComment, at: 0) // Insert at the start
                                        self.newCommentText = "" // Reset comment text field
                                    }

                            print("Comment successfully added with ID: \(newCommentRef.documentID)")
                        } catch {
                            print("Failed to add comment: \(error.localizedDescription)")
                        }
                        endEditing()
                    }
                }
                .font(.callout)
                .foregroundColor(.white)
                .padding(.horizontal,15)
                .padding(.vertical,2)
                .background(.black,in: Capsule())
                .opacity(newCommentText.isEmpty ? 0.5 : 1) // Adjust opacity based on newCommentText
                .disabled(newCommentText.isEmpty)
//                    .padding()
            }
                .padding(.horizontal)
            
            if isShowingUserSearch {
                UserSearchResultsView(searchText: $newCommentText, onUserSelected: { selectedUsername in
                    insertUsernameIntoComment(selectedUsername)  // Call this function when a username is selected
                    isShowingUserSearch = false  // Dismiss the search results view
                })
                .frame(height: 200)
                // Set the desired height
            }
        }
//        .background(Color.black.opacity(0.06).edgesIgnoringSafeArea(.bottom))
    }
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func insertUsernameIntoComment(_ username: String) {
        // Detect the position of the last "@" to replace the query with the selected username
        if let rangeOfLastAtSymbol = newCommentText.range(of: "@", options: .backwards) {
            let prefixText = String(newCommentText[..<rangeOfLastAtSymbol.lowerBound])
            let suffix = newCommentText[rangeOfLastAtSymbol.lowerBound...]
            let suffixText = suffix.contains(" ") ? String(suffix[suffix.range(of: " ")!.lowerBound...]) : " "
            newCommentText = "\(prefixText)@\(username)\(suffixText)"
        }
    }
        
}



struct ResizableTextView: UIViewRepresentable {
    let placeholderText = "Got something to add? Rlystate..."
    var onAtSymbolDetected: (() -> Void)?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent1: self, placeholder: self.placeholderText)
    }
    
    @Binding var text: String
    @Binding var height : CGFloat

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.text = placeholderText
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .clear
        textView.textColor = .gray
        textView.delegate = context.coordinator
        return textView
        
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
              // Only set placeholder if text is empty and text view is not focused
              if text.isEmpty && !uiView.isFirstResponder {
                  uiView.text = placeholderText
                  uiView.textColor = .placeholderText
              } else {
                  uiView.text = text
                  uiView.textColor = .label // Or any color you use for normal text
              }
              // Update the height if needed
              context.coordinator.parent.height = uiView.contentSize.height
          }
      }


    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ResizableTextView
        var placeholder: String

        init(parent1: ResizableTextView, placeholder: String) {
                self.parent = parent1
                self.placeholder = placeholder
            }

        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.height = textView.contentSize.height
                self.parent.text = textView.text
                
                // Detecting if "@" is part of a new word (following a space or at the start of the text)
                if let lastWord = textView.text.split(separator: " ").last,
                   lastWord.hasPrefix("@") && lastWord.count > 1 {
                    self.parent.onAtSymbolDetected?()
                }
            }
        }

        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.text == self.placeholder {
                textView.text = ""
                textView.textColor = .black// Or any preferred color
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = self.placeholder // Use the placeholder passed to the Coordinator
                textView.textColor = .placeholderText
            }
        }
    }
    
    func dismissKeyboard(uiView: UITextView) {
        uiView.resignFirstResponder()
    }
}

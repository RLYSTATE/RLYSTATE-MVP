//
//  CreateNewPost.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/26/23.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import MapKit
import CoreML

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchResults = [MKLocalSearchCompletion]()
    private var searchCompleter: MKLocalSearchCompleter
    
    override init() {
        self.searchCompleter = MKLocalSearchCompleter()
        super.init()
        self.searchCompleter.delegate = self
    }
    
    func updateSearch(query: String) {
        self.searchCompleter.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle errors
    }
}


struct LocationInputView: View {
    @Binding var addressInput: String
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var locationTag: String?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var searchCompleter = SearchCompleter()
    
    var body: some View {
        VStack(spacing: 0) { // Set spacing to 0 to remove gaps
            TextField("Enter address", text: $addressInput)
                .textContentType(.emailAddress)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
                .padding(.horizontal, 15) // Apply horizontal padding to align with the list
                .onChange(of: addressInput) {
                    searchCompleter.updateSearch(query: addressInput)
                }
                .padding(.top,10)
            
            
            
            
        ScrollView {
            VStack(spacing: 0) { // Remove spacing between elements
                ForEach(searchCompleter.searchResults, id: \.self) { result in
                    Button(action: {
                        self.addressInput = "\(result.title), \(result.subtitle)"
                        validateAddress()
                        dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text("\(result.title), \(result.subtitle)")
                                .foregroundColor(.black)
                                .padding()
                            Divider()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(15)
    }
    .background(Color.white)
    }
    
    private func validateAddress() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressInput) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }

            if let firstPlacemark = placemarks?.first, let coordinate = firstPlacemark.location?.coordinate {
                self.selectedLocation = coordinate
                self.locationTag = addressInput
                print("Address selected: \(addressInput), Location: \(coordinate)")
                dismiss()
            }
        }
    }
}




struct CreateNewPost: View {
    @State private var showingTagView = false
    @State private var tagsForNewPost: [Tag] = [.init(value: "#rlystate", isInitial: false)]

    // - Callbacks
    var onPost: (Post)->()
    // Post Properties
    @State private var postText: String = ""
    @State private var postImageData: Data?
    
    // Stored User Data From UserDefaults(AppStorage)
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    
    // View Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    @State private var labelPrediction = "" // Content Moderation ML
    
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var showLocationInput = false
    @State private var taggedLocation: CLLocationCoordinate2D?
    @State private var addressInput: String = ""
    
    @State private var locationTag: String? = nil // Declare locationTag as part of your state
    
    init(onPost: @escaping (Post) -> (), initialLocationTag: String? = nil) {
        self.onPost = onPost
        self._locationTag = State(initialValue: initialLocationTag)
          // Reset tags for a new post
          TagManager.shared.sessionTags = [.init(value: "#rlystate", isInitial: false)]
      }

    
    
    var body: some View {
        VStack{
            HStack{
                Menu {
                    Button("Cancel",role: .destructive){
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                }
                .hAlign(.leading)
                
                Button(action: createPost){
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,20)
                        .padding(.vertical,6)
                        .background(.black,in: Capsule())
                }
                .disabled(postText == "")
                .opacity(postText == "" ? 0.5 : 1.0)
            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    TextField("Rlystate what's up?", text: $postText, axis: .vertical)
                        .focused($isTextFieldFocused)
                    
                    
                    if let postImageData, let image = UIImage(data: postImageData) {
                        GeometryReader{
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            /// Delete Button
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)){
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
                
              ///tags in post
                HStack {
                    ForEach(tagsForNewPost, id: \.self) { tag in
                        Text(tag.value)
                            .padding(5)
                            .font(.system(size: 14))
                            .background(Capsule().stroke(Color.blue,lineWidth: 1))
                            .lineLimit(1)                    }
                }
            }
            
            
            Divider()
            
            HStack{
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                Spacer()
                
                Button(action: {
                    showLocationInput.toggle()
                }) {
                    Image(systemName: taggedLocation == nil ? "mappin.circle" : "mappin.circle.fill")
                        .font(.title3)
                        .foregroundColor(taggedLocation == nil ? .black : .black)
                        .padding()
                }
                
                .sheet(isPresented: $showLocationInput) {
                    LocationInputView(addressInput: $addressInput, selectedLocation: $taggedLocation, locationTag: $locationTag)
                }

                
                Spacer()
                
                Button(action: {
                    showingTagView.toggle()
                }) {
                    Image(systemName: tagIconName())
                        .font(.title3)
                        .foregroundColor(.black)
                }
                .sheet(isPresented: $showingTagView) {
                    TagView(tags: $tagsForNewPost) 
                }

            }
            .foregroundColor(.black)
            .padding(.horizontal,15)
            .padding(.vertical,10)
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem, initial: false) { oldPhotoItem, newPhotoItem in
            if let newPhotoItem {
                Task {
                    if let rawImageData = try? await newPhotoItem.loadTransferable(type: Data.self), let image = UIImage(data: rawImageData), let compressedImageData = image.jpegData(compressionQuality: 0.5){
                        // UI Must be done on main thread
                        await MainActor.run(body: {
                            postImageData = compressedImageData
                            photoItem = nil
                            isTextFieldFocused = true
                        })
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
        
        /// Loading View 11.10 - resume
        .overlay {
            LoadingView(show: $isLoading)
        }
    }
    // Post Content to Firebase
    func createPost() {
        analyzePost()

           // If the post is negative, show an error message a
           if labelPrediction == "BAD" {
               errorMessage = "Take a chill pill. Let's rephrase that and keep the good vibes."
               showError = true
               return
           }

        if locationTag == nil {
              // Set error message prompting user to select a location
              errorMessage = "Please select a location to Rlystate."
              showError = true
              return 
          }

          isLoading = true
          showKeyboard = false
        Task {
            do {
                guard let profileURL = profileURL else { return }
                let imageReferenceID = "\(userUID)\(Date())"
                let storageRef = Storage.storage().reference().child("Post_Images").child(imageReferenceID)

                // Location data should be set regardless of photo
                let locationData = (locationTag: locationTag, latitude: taggedLocation?.latitude, longitude: taggedLocation?.longitude)

                if let postImageData {
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    
                    //tags
                    let tags = tagsForNewPost.map { $0.value }
                    
                    let post = Post(
                        text: postText,
                        imageURL: downloadURL,
                        imageReferenceID: imageReferenceID,
                        locationTag: locationData.locationTag,
                        latitude: locationData.latitude,
                        longitude: locationData.longitude,
                        userName: userName,
                        userUID: userUID,
                        userProfileURL: profileURL,
                        // tags
                        tags: tags
                    )
                    try await createDocumentAtFirebase(post)
                } else {
                    //post without tags
                    let tags = tagsForNewPost.map { $0.value }
                    
                    let post = Post(
                        text: postText,
                        locationTag: locationData.locationTag,
                        latitude: locationData.latitude,
                        longitude: locationData.longitude,
                        userName: userName,
                        userUID: userUID,
                        userProfileURL: profileURL,
                        tags: tags
                    )
                    try await createDocumentAtFirebase(post)
                }
            } catch {
                await setError(error)
            }
        }
    }



    
    func createDocumentAtFirebase(_ post: Post) async throws {
        /// Writing Document to Firebase Firestore
        let doc = Firestore.firestore().collection("Posts").document()
        print("Attempting to save post to Firestore: \(post)") // Log the post details

        do {
            try doc.setData(from: post) { error in
                if let error = error {
                    // If there's an error, print it
                    print("Error saving post to Firestore: \(error.localizedDescription)")
                } else {
                    // Log success message
                    print("Post successfully saved to Firestore with ID: \(doc.documentID)")
                    isLoading = false
                    var updatedPost = post
                    updatedPost.id = doc.documentID
                    onPost(updatedPost)
                    dismiss()
                }
            }
        } catch {
            // Catch any exceptions during the write operation and print them
            print("Exception occurred while saving post to Firestore: \(error.localizedDescription)")
            throw error
        }
    }

    
    // Displaying errors as alerts
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
    
    
    // Content Moderation Creating Post
    private func analyzePost() {
        do {
            let configuration = MLModelConfiguration()
            let model = try RlystateContentModeration(configuration: configuration)
            let input = RlystateContentModerationInput(text: postText)
            
            let output = try model.prediction(input: input)
         
            print("Sentiment analysis result: \(output.label)") // Print result of sentiment analysis
            
            switch output.label {
            case "positive":
                print("The post is positive.")
                labelPrediction = "GOOD"
                
            case "negative":
                print("The post is negative.")
                labelPrediction = "BAD"
                
            case "neutral":
                print("The post is neutral.")
                labelPrediction = "NEUTRAL"
                
            default:
                print("Unexpected label: \(output.label)")
                labelPrediction = "Error"
            }
        } catch {
        
            print("Error in model prediction: \(error.localizedDescription)")
            labelPrediction = "Error"
        }
    }
    
    class TagManager {
        static let shared = TagManager()
        var sessionTags: [Tag] = [.init(value: "#rlystate", isInitial: false)]

        private init() {}
    }
    
    
    func tagIconName() -> String {
        // default tag to be "rlystate"
        let hasTags = tagsForNewPost.contains(where: { $0.value != "#rlystate" && !$0.value.isEmpty })
        return hasTags ? "tag.fill" : "tag"
    }

}

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost{_ in
        }
    }
}

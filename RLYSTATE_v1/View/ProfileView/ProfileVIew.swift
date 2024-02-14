//
//  ProfileVIew.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/27/23.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics

struct ProfileView: View {
    // Profile Data
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    // View Properties
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile{
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            // Refresh User Data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                }else{
                    ProgressView()
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            // Log the button click with Firebase Analytics
                            Analytics.logEvent("feedback_button_clicked", parameters: [
                                "screen": "ProfileView",
                                "time": Date().description
                            ])
                            
                            // Open the feedback link
                            if let url = URL(string: "https://forms.gle/LgbCRi6hPDZo2eYRA") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Provide Feedback")
                        }
                        
                        Button("Logout", action: logOutUser)
                        
                        Button("Delete Account", role: .destructive, action: deleteAccount)
                    }
                label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.init(degrees: 90))
                        .tint(.black)
                        .scaleEffect(0.8)
                }
                }
            }
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) {
        }
        .task {
            // This Modifier is like onAppear
            // So Fetching for the first time only
            if myProfile != nil{return}
            // Initial Fetch
            await fetchUserData()
        }
    }
    // Fetching User Data
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else{return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self)
        else{return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    
    // Logging User Out
    func logOutUser(){
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    // Deleting User
    func deleteAccount(){
        isLoading = true
        Task{
            do{
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                
                // Query and delete all posts by this user
                let postsRef = Firestore.firestore().collection("Posts")
                let querySnapshot = try await postsRef.whereField("userUID", isEqualTo: userUID).getDocuments()
                for document in querySnapshot.documents {
                    // Delete each post
                    try await postsRef.document(document.documentID).delete()
                    // Optionally delete associated images from Storage if they exist
                }
                
                // Delete Profile Image from Storage
                let profileImageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await profileImageRef.delete()
                
                // Delete User Document from Firestore
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                
                // Delete User from Firebase Authentication
                try await Auth.auth().currentUser?.delete()
                
                // Update log status
                logStatus = false
            } catch {
                await setError(error)
            }
        }
    }
    // Setting Error
    func setError(_ error: Error)async{
        // UI must be run on Main Thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}
// Preview provider
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

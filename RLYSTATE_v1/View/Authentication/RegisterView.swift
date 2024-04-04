//
//  RegisterView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/27/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

// Register View
struct RegisterView: View{
        // User Details
        @State var emailID: String = ""
        @State var password: String = ""
        @State var userName: String = ""
        @State var userBio: String = ""
        @State var confirmPassword: String = ""
        @State var userProfilePicData: Data?
    
    
        // View Properties
        @Environment(\.dismiss) var dismiss
        @State var showImagePicker: Bool = false
        @State var photoItem: PhotosPickerItem?
        @State var showError: Bool = false
        @State var errorMessage: String = ""
        @State var isLoading: Bool = false
        // User Defaults
        @AppStorage ("log_status") var logStatus: Bool = false
        @AppStorage ("user_profile_url") var profileURL: URL?
        @AppStorage ("user_name") var userNameStored: String = ""
        @AppStorage ("user_UID") var userUID: String = ""
        var body: some View{
        VStack(spacing: 10) {
            Text("Register Account")
                .font(.largeTitle.bold())
                .hAlign(.leading)
                .keyboardResponsive()
            
            Text("Let's RLYSTATE now")
                .font(.title3)
                .hAlign(.leading)
                
            
            //Smaller Size Optimization
            ViewThatFits{
                ScrollView(.vertical, showsIndicators: false){
                    HelperView()
                }
                HelperView()
            }
            
            // Register Button
            HStack{
                Text("Already have an account?")
                    .foregroundColor(.gray)
                
                Button("Login Now"){
                    dismiss()
                    
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
            .vAlign(.bottom)
            }
        .vAlign(.top)
        .padding(15)
        .onTapGesture {
                endEditing() // Dismiss the keyboard
            }

        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
            .onChange(of: photoItem) {
                // Access 'photoItem' directly instead of using 'newValue'
                // Extracting UI image from PhotoItem
                if let photoItem = photoItem {
                    Task {
                        do {
                            guard let imageData = try await photoItem.loadTransferable(type: Data.self) else { return }
                            // UI Must Be Updated on Main Thread
                            await MainActor.run {
                                userProfilePicData = imageData
                            }
                        } catch {
                            // Handle error appropriately
                        }
                    }
                }
            }
            // Displaying Alert
            .alert(errorMessage, isPresented: $showError, actions: {})
    }
    @ViewBuilder
    func HelperView()-> some View{
        VStack(spacing: 12){
            ZStack{
                if let userProfilePicData,let image = UIImage(data: userProfilePicData){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }else{
                    Image("NullProfile")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    
                }
            }
            .frame(width: 85, height: 85)
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .contentShape(Circle())
                .onTapGesture {
                    showImagePicker.toggle()
                }
                .padding(.top,25)
            
            
            TextField("Username", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .onChange(of: userName) {
        userName = userName.replacingOccurrences(of:        " ", with: "")
                }
                
            
            TextField("Email", text: $emailID)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
       
            
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            ZStack (alignment: .trailing) {
                           SecureField("Confirm your password", text: $confirmPassword)
                               .textContentType(.emailAddress)
                               .border(1, .gray.opacity(0.5))
                           
                           if !password.isEmpty && !confirmPassword.isEmpty{ // creates UI for red or green chech mark to ensure password = confirmPassword
                               if password == confirmPassword{
                                   Image(systemName: "checkmark.circle.fill")
                                       .imageScale(.large)
                                       .fontWeight(.bold)
                                       .foregroundColor(Color(.systemGreen))
                               } else {
                                   Image(systemName: "xmark.circle.fill")
                                       .imageScale(.large)
                                       .fontWeight(.bold)
                                       .foregroundColor(Color(.systemRed))
                               }
                           }
                       }
            
            
            TextField("About You", text: $userBio, axis:.vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
       
            
            
            Button(action:registerUser){
                // Register Button
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
                }
            .disabledWithOpacity(userName == "" || userBio == "" || !emailID.contains("@") || password == "" || confirmPassword != password || userProfilePicData == nil)
                        .padding(.top,10)
            }
    }
    
    func registerUser(){
        isLoading = true
        closeKeyBoard()
        Task{
            do{
                // Step 1: Creating Firebase Account
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                // Step 2: Uploading Profile Photo Into FIrebase Storage
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                guard let imageData = userProfilePicData else{return}
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
               let _ = try await storageRef.putDataAsync(imageData)
                    // Step 3 Downloading Photo URL
                let downloadURL = try await storageRef.downloadURL()
                    // Step 4 Creating a user Firestore Object
                let user = User(userName: userName, userBio: userBio, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL)
                    // Step 5 Saving USer Doc into FIrebase Database
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: {
                    error in
                    if error == nil{
                        // Print Saved Successfully
                        print("Saved Successfully")
                        userNameStored = userName
                        self.userUID = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
            }catch{
                // Deleting Created Account In Case of Failure
                try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
    }
    // Displaying Errors via Alert
    func setError(_ error: Error)async{
        // UI Must Be updated on Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

#if canImport(UIKit)
extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif


struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}

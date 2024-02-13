//
//  LoginView.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/18/23.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage


struct LoginView: View {
    // User Details
    @State var emailID: String = ""
    @State var password: String = ""
    // View Properties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    /// Animation View Properties
    @State private var intros: [LoginIntro] = authIntros
    @State private var activeIntro: LoginIntro?
    @State var isAnimating: Bool = true
    @State private var capsuleOffset: CGFloat = 10
    
    // User Defaults
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        GeometryReader {_ in 
            //          _ze = $0.size
//            let safeArea = $0.safeAreaInsets
            
            VStack(spacing:0) {
                if let activeIntro {
                    Rectangle()
                        .fill(activeIntro.bgColor)
                        .padding(.bottom, -20)
                    
                    /// Rectangle And Text (change to Rectangle/Line)
                        .overlay {
                            Rectangle()
                                .fill(activeIntro.lineColor)
                                .frame(width: 50, height: 6)
                                .padding(.top, 80)
                            
                                // Offset moves line within the overlay
                                .offset(x: 0)
                                .background(alignment: .trailing, content: {
                                    Rectangle()
                                        .fill(activeIntro.bgColor)
                                        .frame(width: 300, height: 50)
                                        .offset(x: -58)
                                })
                                .background(alignment: .trailing) {
                                    Text(activeIntro.text)
                                        .font(.largeTitle)
                                        .foregroundStyle(activeIntro.textColor)
                                        .frame(width: textSize(activeIntro.text))
                                        .offset(x: -40)
                                        .offset(x: -activeIntro.textOffset)
                                    
                                }
                                .offset(x: activeIntro.lineOffset)
                        }
                }
              
                    /// Login Buttons
                    LoginButtons(backgroundColor: activeIntro?.bgColor ?? Color.gray)
                    .padding(.top, 10)
                    .shadow(color: .black.opacity(0.1), radius: 5, x:0, y:8)
                
            }
            .ignoresSafeArea()
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        
        
        .vAlign(.top)
       
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
//        // Register View VIA Sheets
        .fullScreenCover(isPresented:$createAccount) {
            RegisterView()
        }
//        // Displaying Alert
        .alert(errorMessage, isPresented: $showError, actions: {})
        .task {
            if activeIntro == nil {
                activeIntro = authIntros.first
                /// Delaying 0.15s and Starting Animaition
                let oneSecond = UInt64(1_000_000_000)
                try? await Task.sleep(nanoseconds: oneSecond * UInt64(0.15))
                animate(0)
            }
        }
    }
    /// Login Buttons
    @ViewBuilder
    func LoginButtons(backgroundColor: Color) -> some View {
        VStack(spacing:12) {
            TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .border(1, .gray.opacity(0.5))
                    .background(.color3)
                    .padding(.top,25)
            
            SecureField("Password", text: $password)
                       .textContentType(.emailAddress)
                       .border(1, .gray.opacity(0.5))
                       .background(.color3)

            Button("Reset password?", action: resetPassword)
                            .font(.callout)
                            .fontWeight(.medium)
                            .tint(.black)
                            .hAlign(.trailing)
            
            Button(action: loginUser) {
                Text("Sign in")
                    .foregroundColor(.white)
                    .fillButton(.black)
                    .shadow(color:.white, radius: 1)
            }
            
            HStack{
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                

                    Button("Register Now"){
                        createAccount.toggle()

                    }
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                }
                .font(.callout)
                .vAlign(.bottom)
                .padding(.bottom,35)
            /// adjust padding ^^ for log in
        }
        .padding(15)
        .padding(.top,40)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 5))
        .keyboardResponsive()
    }
    
    
    func loginUser(){
          isLoading = true
          isAnimating = false
          closeKeyBoard()
        Task{
            do{
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
                try await fetchUser()
            }catch{
                await setError(error)
                
            }
        }
    }
    
 //    If user if found then fetching user data from firestore
    func fetchUser()async throws{
        guard let userID = Auth.auth().currentUser?.uid else {return}
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        
        // UI updating must be run on main thread
        await MainActor.run(body: {
            
            // Setting UserDefaults data and changing App's Auth Status
            userUID = userID
            userNameStored = user.userName
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    
    func resetPassword(){
        Task{
            do{
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Link Sent")
            }catch{
                await setError(error)
            }
        }
    }
    
    // Displaying Error VIA Alert
    func setError(_ error: Error)async{
        isAnimating = true
        //UI Must be Updated on Main Thread
        await MainActor.run(body: {
            errorMessage = "Opps! We couldn't find your account. Please try again or sign up for a fresh start!"
            showError.toggle()
            isLoading = false
        })
    }
    
    /// Animating Intros
    func animate(_ index: Int, _ loop: Bool = true) {
        guard isAnimating else { return }
        if intros.indices.contains(index + 1) {
            /// Updating Text and Text Color
            activeIntro?.text = intros[index].text
            activeIntro?.textColor = intros[index].textColor
            
            /// Animating Offset
            withAnimation(.snappy(duration: 1), completionCriteria: .removed) {
                activeIntro?.textOffset = -(textSize(intros[index].text) - 20)
                activeIntro?.lineOffset = -(textSize(intros[index].text) - 90) / 2
            } completion: {
                /// Resetting the Offset with Next Slide Color Change
                withAnimation(.snappy(duration: 0.8), completionCriteria: .logicallyComplete) {
                    activeIntro?.textOffset = 0
                    activeIntro?.lineOffset = 0
                    activeIntro?.lineColor = intros[index + 1].lineColor
                    activeIntro?.bgColor = intros[index + 1].bgColor
                } completion: {
                    /// Going to Next Slide
                    animate(index + 1, loop)
                }
            }
        } else {
            /// Looping
            if loop {
                animate(0, loop)
            }
        }
    }
    
    /// Fetching Text Size based on Fonts
    func textSize(_ text: String) -> CGFloat {
        return NSString(string: text).size(withAttributes: [.font: UIFont.preferredFont(forTextStyle: .largeTitle)]).width
    }
}

// Preview
struct LoginView_Preview: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

/// Custome Modifer
extension View {
    @ViewBuilder
    func fillButton(_ color: Color) -> some View {
        self
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical,15)
            .background(color, in: .rect(cornerRadius: 15))
    }
}

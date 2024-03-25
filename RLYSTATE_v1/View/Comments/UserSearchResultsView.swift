import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct UserSearchResultsView: View {
    @State private var fetchedUsers: [User] = []
    @Binding var searchText: String  
    @Environment(\.dismiss) private var dismiss
    var onUserSelected: ((String) -> Void)?

    var body: some View {
        List{
            ForEach(fetchedUsers) { user in
                   Button(action: {
                       print("User selected: \(user.userName)")
                       self.onUserSelected?(user.userName)
                   }) {
                       HStack(alignment: .center, spacing: 8) { // Add alignment and spacing
                           WebImage(url: user.userProfileURL)
                               .resizable()
                               .aspectRatio(contentMode: .fill)
                               .frame(width: 25, height: 25)
                               .clipShape(Circle())
                           
                           Text(user.userName)
                               .font(.callout)
//                               .foregroundColor(Color(red: 83 / 255, green: 113 / 255, blue: 255 / 255))
                       }
                   }
               }
            }
        .listStyle(.plain)
        .searchable(text: $searchText)
        .onChange(of: searchText, initial: false) {
            print("searchText changed: \(searchText)")
            Task {
                await searchUsers()
            }
        }

        .onChange(of: searchText, initial: false) {
            Task {
                fetchedUsers = []
            }
        }

    }
    
    func searchUsers() async {
        // Extract the part of searchText that follows the last "@"
        let lastAtSymbolRange = searchText.range(of: "@", options: .backwards)
        let queryText = lastAtSymbolRange != nil ? String(searchText[lastAtSymbolRange!.upperBound...]) : ""

        // Clean the queryText by trimming whitespaces and newlines
        let cleanedSearchText = queryText.trimmingCharacters(in: .whitespacesAndNewlines)

        print("Starting user search with cleaned searchText: '\(cleanedSearchText)'")

        guard !cleanedSearchText.isEmpty else {
            print("Cleaned search text is empty. Clearing fetched users.")
            await MainActor.run { fetchedUsers = [] }
            return
        }

        do {
            let querySnapshot = try await Firestore.firestore().collection("Users")
                .whereField("userName", isGreaterThanOrEqualTo: cleanedSearchText)
                .whereField("userName", isLessThanOrEqualTo: "\(cleanedSearchText)\u{f8ff}")
                .getDocuments()
            print("Query executed. Documents fetched: \(querySnapshot.documents.count)")

            let users = querySnapshot.documents.compactMap { document -> User? in
                let result = Result { try document.data(as: User.self) }
                switch result {
                case .success(let user):
                    return user
                case .failure(let error):
                    print("Error decoding user: \(error.localizedDescription)")
                    return nil
                }
            }

            print("Users parsed and ready to display: \(users.count)")
            await MainActor.run {
                fetchedUsers = users
            }
        } catch {
            print("An error occurred while fetching users: \(error.localizedDescription)")
        }
    }

}

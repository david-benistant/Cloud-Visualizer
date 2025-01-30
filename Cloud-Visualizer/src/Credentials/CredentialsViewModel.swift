import SwiftUI

class CredentialsViewModel: ObservableObject {
    @Published var credentials: [CredentialItem] = []

    init(type: String?) {
        if let savedItems = UserDefaults.standard.data(forKey: "credentials"),
           let decodedItems = try? JSONDecoder().decode([CredentialItem].self, from: savedItems) {
            if type != nil {
                credentials = decodedItems.filter { $0.type == type }
            } else {
                credentials = decodedItems
            }
        }
    }

    func setCurrent(credential: CredentialItem) {
        for cred in credentials {
            cred.current = credential == cred
        }

        if let encoded = try? JSONEncoder().encode(credentials) {
            UserDefaults.standard.set(encoded, forKey: "credentials")
        }
    }
}

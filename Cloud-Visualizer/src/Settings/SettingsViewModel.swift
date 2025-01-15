import SwiftUI

let cloudProviders = ["AWS"/*, "Azure", "Google"*/]

class SettingsViewModel: ObservableObject {
    @Published var credentials: [CredentialItem] = []

    init() {
        loadCredentials()
    }

    func loadCredentials() {
        if let savedItems = UserDefaults.standard.data(forKey: "credentials"),
           let decodedItems = try? JSONDecoder().decode([CredentialItem].self, from: savedItems) {
            credentials = decodedItems
        }
    }

    func saveCredentials() {
        if let encoded = try? JSONEncoder().encode(credentials) {
            UserDefaults.standard.set(encoded, forKey: "credentials")
        }
    }

    func addCredential(newItem: CredentialItem) {
        credentials.append(newItem)
        saveCredentials()
    }

    func updateCredential(updatedItem: CredentialItem) {
        if let index = credentials.firstIndex(where: { $0.id == updatedItem.id }) {
            credentials[index] = updatedItem
        }
        saveCredentials()
    }

    func deleteCredential(itemToDelete: CredentialItem) {
        if let index = credentials.firstIndex(where: { $0.id == itemToDelete.id }) {
            credentials.remove(at: index)
            saveCredentials()
        }
    }

    func convertCredentialsToCSV(_ item: CredentialItem) -> String {
        var csvString = ""
        if (item.type == "AWS") {
            csvString = """
            \(item.name),\(item.AWSKeyId),\(item.AWSSecretAccessKey),\(item.endpoint)
            """
        }
        return csvString
    }

    func copyCredentialToPasteboard(_ item: CredentialItem) {
        let csvString = convertCredentialsToCSV(item)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(csvString, forType: .string)
    }
}


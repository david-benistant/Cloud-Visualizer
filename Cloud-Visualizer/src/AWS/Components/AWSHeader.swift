import SwiftUI
import Combine

struct AWSHeader: View {

    let callback: (CredentialItem, AWSRegionItem) -> Void

    @StateObject private var authItem: AWSAuthItem = AWSAuthItem()
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        HStack {
            AccountPicker(selectedOption: $authItem.credential, type: "AWS")
            AWSRegionPicker(selectedOption: $authItem.region)
        }
//        .frame(minWidth: 150, alignment: .trailing)
//        .padding()
        .onAppear {
            observeAuthItemChanges()
        }
    }

    private func observeAuthItemChanges() {
        let localCallback = self.callback
        authItem.$credential
            .combineLatest(authItem.$region)
            .sink { (credential, region) in
                if let cred = credential,  let reg = region {
                    localCallback(cred, reg)
                }
            }
            .store(in: &cancellables)
    }
}

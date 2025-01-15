import SwiftUI

struct AWSSettingsView: View {
    @ObservedObject var item: CredentialItem
    @State private var keyId: String
    @State private var secretKey: String
    @State private var endpoint: String

    init(item: CredentialItem) {
        self.item = item
        self._keyId = State(initialValue: item.AWSKeyId)
        self._secretKey = State(initialValue: item.AWSSecretAccessKey)
        self._endpoint = State(initialValue: item.endpoint)
    }

    var body: some View {
        VStack {
            accessKeyIdSection
            Divider()
            secretAccessKeySection
            if !endpoint.isEmpty {
                Divider()
                endpointSection
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .onReceive(item.$AWSKeyId) { newKeyId in
            self.keyId = newKeyId
        }
        .onReceive(item.$AWSSecretAccessKey) { newSecretKey in
            self.secretKey = newSecretKey
        }
        .onReceive(item.$endpoint) { newEndpoint in
            self.endpoint = newEndpoint
        }
    }

    private var accessKeyIdSection: some View {
        TextInput(label: "Access Key Id", disabled: true, field: $keyId)
    }

    private var secretAccessKeySection: some View {
        PasswordInput(label: "Secret Access Key", disabled: true, field: $secretKey)
    }

    private var endpointSection: some View {
        TextInput(label: "Endpoint", disabled: true, field: $endpoint)
    }
}

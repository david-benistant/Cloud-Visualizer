import SwiftUI

struct AWSEditView: View {
    @Binding var keyId: String
    @Binding var secretKey: String
    @Binding var endpoint: String

    @State private var more: Bool = false

    var body: some View {
        Divider()
        VStack {
            TextInput(label: "Access Key Id", disabled: false, field: $keyId)
            .frame(width: 350)
            Divider()

            PasswordInput(label: "Secret Access Key", disabled: false, field: $secretKey)
            .padding(.bottom, 20)
            .frame(width: 350)

            Section {
                Button(action: {
                    more.toggle()
                }) {
                    HStack {
                        Text(more ? "Less" : "More")
                    }
                }
            }
            .frame(width: 350, alignment: .leading)
            .padding(.bottom, 15)

            if more {
                TextInput(label: "Endpoint", disabled: false, field: $endpoint)
            }
        }
    }
}

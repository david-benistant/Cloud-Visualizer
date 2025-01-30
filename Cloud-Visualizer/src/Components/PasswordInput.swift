import SwiftUI

struct PasswordInput: View {
    let label: String
    let disabled: Bool
    @Binding var field: String

    var body: some View {
        HStack {
            Text(label)
                .frame(minWidth: 0, alignment: .leading)
                .padding(.trailing, 10)
            SecureField(label, text: $field)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.trailing)
                .disabled(disabled)
        }
        .padding(.vertical, 5)
    }
}

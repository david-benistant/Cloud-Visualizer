import SwiftUI

struct TextInput: View {
    let label: String
    let disabled: Bool
    @Binding var field: String
    var foregroundColor: Color? = nil

    var body: some View {
        HStack {
            Text(label)
                .frame(minWidth: 0, alignment: .leading)
                .padding(.trailing, 10)

            TextField(label, text: $field)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.trailing)
                .disabled(disabled)
                .foregroundColor(foregroundColor ?? .primary)
        }
        .padding(.vertical, 5)
    }
}

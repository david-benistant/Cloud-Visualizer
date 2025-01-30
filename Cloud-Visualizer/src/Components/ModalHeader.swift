import SwiftUI

struct ModalHeader: View {
    let title: String
    @Binding var errorMessage: String?

    var body: some View {
        HStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .layoutPriority(0)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(width: 200, alignment: .trailing)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

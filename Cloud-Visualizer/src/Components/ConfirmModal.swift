
import SwiftUI

struct ConfirmModal: View {
    @Binding var isOpen: Bool
    var onConfirm: () async -> Void

    var body: some View {
        VStack {
            ModalHeader(title: "Warning", errorMessage: .constant(nil))
            
            Spacer()
            Image("Warning")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
                .padding(.top)
            Text("Are you sure you want to perform this action?")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 75, alignment: .center)
            Spacer()
            
            HStack {
                Button(action: {
                    isOpen = false
                }) {
                    Text("Cancel")
                }
                Button(action: {
                    Task {
                        await onConfirm()
                        isOpen = false
                    }
                    
                }) {
                    Text("Confirm")
                }
                .keyboardShortcut(.defaultAction)
                
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 200)
        .padding()
    }
    
}

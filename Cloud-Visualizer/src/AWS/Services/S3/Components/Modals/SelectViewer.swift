
import SwiftUI
import AWSS3



struct SelectViewer: View {
    @EnvironmentObject var navModel: NavModel
    @Binding var isOpen: Bool
    let callback: ((Viewer) -> Void)?
    
    
    @State var errorMessage: String?
    @State var selectedOption: Viewer = .text
    
    

    var body: some View {
        VStack {
            ModalHeader(title: "Select Viewer", errorMessage: $errorMessage)
            
            Spacer()
    
            Picker("", selection: $selectedOption) {
                Text("Text").tag(Viewer.text)
                
                Text("PDF").tag(Viewer.pdf)
                
                Text("Html").tag(Viewer.html)
                
                Text("Image").tag(Viewer.image)
            }
            Spacer()
            HStack {
                Button(action: {
                    isOpen = false
                }) {
                    Text("Cancel")
                }
                Button(action: {
                    isOpen = false
                    if let cb = callback {
                        cb(selectedOption)
                    }
                }) {
                    Text("Select")
                }
                .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}

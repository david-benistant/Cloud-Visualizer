import SwiftUI

struct EditCredsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var editItem: CredentialItem

    @State private var selectedOption = ""
    @State private var name: String = ""
    @State private var AWSKeyId: String = ""
    @State private var AWSSecretAccessKey: String = ""
    @State private var endpoint: String = ""
    
    init(isPresented: Binding<Bool>, viewModel: SettingsViewModel, editItem: Binding<CredentialItem>) {
        _isPresented = isPresented
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _editItem = editItem
        
        _selectedOption = State(initialValue: editItem.wrappedValue.type)
        _name = State(initialValue: editItem.wrappedValue.name)
        _AWSKeyId = State(initialValue: editItem.wrappedValue.AWSKeyId)
        _AWSSecretAccessKey = State(initialValue: editItem.wrappedValue.AWSSecretAccessKey)
        _endpoint = State(initialValue: editItem.wrappedValue.endpoint)
    }
    
    var body: some View {
        VStack {
            ModalHeader(title: "Edit credentials", errorMessage: .constant(nil))
                .padding(.bottom)
        
            
            Section {
                VStack {
                    HStack {
                        Text("Name")
                            .frame(width: 130, alignment: .leading)
                        TextField("Name", text: $name)
                            .textFieldStyle(PlainTextFieldStyle())
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 5)
                    
                    Section {
                        switch selectedOption {
                        case "AWS":
                            AWSEditView(keyId: $AWSKeyId, secretKey: $AWSSecretAccessKey, endpoint: $endpoint)
                        default:
                            Text("Not implemented")
                        }
                    }
                }
                .frame(width: 350, height: 300, alignment: .top)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            
            Section {
                HStack {

                    HStack {
                        Button(action: {
                            viewModel.deleteCredential(itemToDelete: editItem)
                            editItem.type = "None"
                            isPresented = false
                        }) {
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                        
                    }
                    .frame(width: 200, alignment: .leading)
                    
                    
                    HStack {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text("Cancel")
                        }
                        Button(action: {
                            
                            editItem.name = name
                            editItem.AWSKeyId = AWSKeyId
                            editItem.AWSSecretAccessKey = AWSSecretAccessKey
                            editItem.endpoint = endpoint
                            
                            viewModel.updateCredential(updatedItem: editItem)
                            
                            isPresented = false
                        }) {
                            Text("Save")
                        }
                        .disabled(name.isEmpty)
                        .keyboardShortcut(.defaultAction)
                    }
                    .frame(width: 200, alignment: .trailing)
                }
            }
            .padding(.top)
        }
        .padding()
    }
}

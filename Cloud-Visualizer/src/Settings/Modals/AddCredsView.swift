import SwiftUI

struct AddCredsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SettingsViewModel
    
    @State private var selectedOption = "AWS"
    @State private var name: String = ""
    @State private var AWSKeyId: String = ""
    @State private var AWSSecretAccessKey: String = ""
    @State private var endpoint: String = ""

    var body: some View {
        VStack {
            ModalHeader(title: "Add credentials", errorMessage: .constant(nil))
                .padding(.bottom)

            Section {
                VStack {
                    Picker("", selection: $selectedOption) {
                        ForEach(cloudProviders, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.bottom)
                        
                    TextInput(label: "Name", disabled: false, field: $name)

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
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                    }
                    Button(action: {
                        
                        let item = CredentialItem(type: selectedOption, name: name, AWSKeyId: AWSKeyId, AWSSecretAccessKey: AWSSecretAccessKey, endpoint: endpoint)
                        viewModel.addCredential(newItem: item)
                        isPresented = false
                    }) {
                        Text("Save")
                    }
                    .disabled(name.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
                .frame(width: 400, alignment: .trailing)
            }
            .padding(.top)
        }
        .padding()
    }
}

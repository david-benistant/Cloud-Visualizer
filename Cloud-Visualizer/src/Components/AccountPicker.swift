import SwiftUI

struct AccountPicker: View {
    @StateObject private var viewModel: CredentialsViewModel
    @Binding var selectedOption: CredentialItem?
    
    init(selectedOption: Binding<CredentialItem?>, type: String? = nil) {
        self._selectedOption = selectedOption
        self._viewModel = StateObject(wrappedValue: CredentialsViewModel(type: type))
    }
    
    var body: some View {
        
        Picker("Account", selection: $selectedOption) {
            if selectedOption == nil {
                Text("Select an account").tag(nil as CredentialItem?)
            }
            ForEach(viewModel.credentials, id: \.self) { option in
                Text(option.name).tag(option)
            }
        }
        .id(selectedOption)
        .pickerStyle(MenuPickerStyle())
        
        .frame(width: 140)
        
        .onAppear {
            if selectedOption == nil {
                for credential in viewModel.credentials {
                    if credential.current {
                        selectedOption = credential
                        break
                    }
                }
            }
        }
        .onChange(of: selectedOption) {
            if selectedOption != nil {
                viewModel.setCurrent(credential: selectedOption!)
            }
        }
    }
}

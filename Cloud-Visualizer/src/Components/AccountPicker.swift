import SwiftUI

struct AccountPicker: View {
    @StateObject private var viewModel: CredentialsViewModel
    @Binding var selectedOption: CredentialItem

    init(selectedOption: Binding<CredentialItem>, type: String? = nil) {
        self._selectedOption = selectedOption
        self._viewModel = StateObject(wrappedValue: CredentialsViewModel(type: type))
    }

    var body: some View {
        Picker("Account", selection: $selectedOption) {
            ForEach(viewModel.credentials, id: \.self) { option in
                Text(option.name).tag(option)
            }
        }
        .id(selectedOption)
        .pickerStyle(MenuPickerStyle())
        .onAppear {
            if selectedOption.name.isEmpty {
                for credential in viewModel.credentials {
                    if credential.current {
                        selectedOption = credential
                        break
                    }
                }
            }
            if selectedOption.name.isEmpty {
                selectedOption = viewModel.credentials.first!
            }
        }
        .onChange(of: selectedOption) {
            if !selectedOption.name.isEmpty {
                viewModel.setCurrent(credential: selectedOption)
            }
        }
        .frame(width: 140)
    }
}

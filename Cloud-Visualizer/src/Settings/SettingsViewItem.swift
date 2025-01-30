import SwiftUI

struct SettingsViewItem: View {
    @State private var isEditModalOpen = false
    @Binding var selectedItem: CredentialItem
    let geometry: GeometryProxy
    let viewModel: SettingsViewModel

    var body: some View {
        Section {
            if selectedItem.type != "None" {
                Section {
                    VStack {
                        HStack {
                            HStack {
                                SettingsItemImageView(item: selectedItem, size: 60, imageSize: 50)
                                    .padding(.trailing)
                                Text(selectedItem.name)
                                    .frame(minWidth: 150, maxWidth: .infinity, alignment: .leading)
                                    .font(.title)
                            }
                            .frame(height: 60, alignment: .leading)

                            Spacer()

                            HStack {
                                Button(action: {
                                    isEditModalOpen = true
                                }) {
                                    Image(systemName: "pencil")

                                }
                                .buttonStyle(.borderless)

                                Button(action: {
                                    viewModel.copyCredentialToPasteboard(selectedItem)
                                }) {
                                    Text("Copy")
                                        .font(.body)

                                }
                                .buttonStyle(.borderless)
                            }
                        }

                        switch selectedItem.type {
                        case "AWS":
                            AWSSettingsView(item: selectedItem)
                        default:
                            Text("Not implemented")
                        }
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .frame(width: max(0, geometry.size.width - 300))
            } else {
                Text("No item selected")
                    .font(.body)
                    .padding()
            }
        }
        .frame(width: max(0, geometry.size.width - 250))
        .sheet(isPresented: $isEditModalOpen) {
            EditCredsView(isPresented: $isEditModalOpen, viewModel: viewModel, editItem: $selectedItem)

        }

    }

}

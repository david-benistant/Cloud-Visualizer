import SwiftUI

struct SettingsItemImageView: View {
    let item: CredentialItem
    let size: CGFloat
    let imageSize: CGFloat

    var body: some View {
        ZStack {
            Color.white
                .opacity(0.9)
                .cornerRadius(10)
                .shadow(radius: 5)

            let imageName: String = {
                switch item.type {
                case "AWS":
                    return "AWS-logo"
                case "Azure":
                    return "Azure-logo"
                case "GoogleCloud":
                    return "GoogleCloud-logo"
                default:
                    return "default-logo"
                }
            }()

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize)
        }
        .frame(width: size, height: size)
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var isAddModalOpen = false
    @State private var searchText = ""
    @State private var selectedItem: CredentialItem = CredentialItem(type: "None", name: "")

    var filteredItems: [CredentialItem] {
        if searchText.isEmpty {
            return viewModel.credentials
        } else {
            return viewModel.credentials.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        Section {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    List {
                        ForEach(filteredItems, id: \.id) { item in
                            Button(action: {
                                selectedItem = item
                            }) {
                                HStack {
                                    SettingsItemImageView(item: item, size: 35, imageSize: 30)

                                    Text(item.name)
                                        .font(.body)
                                        .foregroundColor(item == selectedItem ? .blue : .white)
                                        .padding(.leading, 10)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 5)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .frame(width: 250)
                    Divider()
                           .background(Color.black)
                    SettingsViewItem(selectedItem: $selectedItem, geometry: geometry, viewModel: viewModel)

                }
            }
            .frame(minWidth: 650)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    isAddModalOpen = true
                }) {
                    Label("add", systemImage: "plus")
                }
            }

        }
        .searchable(text: $searchText)
        .sheet(isPresented: $isAddModalOpen) {
            AddCredsView(isPresented: $isAddModalOpen, viewModel: viewModel)
        }

    }

}

#Preview {
    SettingsView()
}

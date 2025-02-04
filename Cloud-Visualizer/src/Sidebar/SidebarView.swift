import SwiftUI
let homeItem = SidebarItem(id: UUID(), title: "Home", destination: AnyView(HomeView()), icon: "house")
let settingsItem = SidebarItem(id: UUID(), title: "Settings", destination: AnyView(SettingsView()), icon: "gearshape.fill")

struct SidebarView: View {
    @StateObject private var viewModel = SidebarViewModel()
    @State private var searchText = ""
    @State private var selectedItem: SidebarItem? = homeItem

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selectedItem) {
                    Section {
                        NavigationLink(value: homeItem) {
                            HStack {

                                Image(systemName: homeItem.icon)

                                Text(homeItem.title)
                            }
                        }
                    }
                }
                .scrollDisabled(true)
                .searchable(text: $searchText, placement: .sidebar)
                .listStyle(SidebarListStyle())
                .frame(minHeight: 80, maxHeight: 80)
                .onChange(of: searchText) {
                    viewModel.search(query: searchText)
                }

                Divider()
                    .padding(.bottom, 10)

                List(selection: $selectedItem) {
                    ForEach(viewModel.displayedItems, id: \.id) { item in
                        NavigationLink(value: item) {
                            HStack {
                                Image(item.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(3)

                                Text(item.title)
                            }
                        }
                    }
                }
                .listStyle(SidebarListStyle())

                Spacer()

                Divider()
                    .padding(.vertical, 10)

                List(selection: $selectedItem) {
                    NavigationLink(value: settingsItem) {
                        HStack {

                            Image(systemName: settingsItem.icon)

                            Text(settingsItem.title)
                        }
                    }
                }
                .scrollDisabled(true)
                .frame(minHeight: 40, maxHeight: 40)
                .onChange(of: selectedItem) {
                    if let item = selectedItem {
                        viewModel.selectItem(selectedItem: item)
                    }
                }

            }
          
        } detail: {
            if let selectedItem = selectedItem {
                selectedItem.destination
            } else {
                Text("Sélectionnez un élément")
            }
        }
        .navigationSplitViewStyle(.balanced)

        
    }
}

#Preview {
    SidebarView()
}

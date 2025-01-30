import SwiftUI

class NavItem: Identifiable, ObservableObject {
    private let _id: UUID = UUID()
    var label: String
    var component: AnyView

    var id: UUID {
        return _id
    }

    init(component: AnyView, label: String) {
        self.label = label
        self.component = component
    }
}

class NavModel: ObservableObject {
    @Published var navItems: [NavItem]

    @Published var history: [NavItem] = []

    init(_ root: NavItem) {
        self.navItems = [root]
    }

    var current: AnyView {
        if let out =  navItems.last {
            return out.component
        } else {
            return AnyView(Text("No view initialized"))
        }
    }

    func navigate(_ component: AnyView, label: String) {
        navItems.append(NavItem(component: component, label: label))
    }

    func goTo(_ item: NavItem) {
        if let index = navItems.firstIndex(where: { $0.id == item.id }) {
            navItems = Array(navItems.prefix(upTo: index + 1))
        }
        history = []
    }

    func goBack() {
        if navItems.count > 1 {
            history.append(navItems.last!)
            navItems.removeLast()
        }
    }

    func goForward() {
        if let last = history.last {
            history.removeLast()
            navItems.append(last)
        }
    }
}

private struct NavButton: View {
    let item: NavItem
    @StateObject var navModel: NavModel

    var body: some View {
        Button(action: {
            navModel.goTo(item)
        }) {

            Text(item.label)
                .frame(minHeight: 20)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(Color.blue)
        }
        .buttonStyle(.borderless)
    }
}

struct Nav: View {
    let navBar: Bool = true
    @StateObject var navModel: NavModel

    init(_ root: AnyView, rootLabel: String) {
        _navModel = StateObject(wrappedValue: NavModel(NavItem(component: root, label: rootLabel)))
    }

    var body: some View {
        VStack(spacing: 0) {
            if navBar {

                HStack {
                    Button(action: {
                        navModel.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.borderless)
                    .disabled(navModel.navItems.count <= 1)
                    .padding(.leading, 2)
                    Button(action: {
                        navModel.goForward()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.borderless)
                    .disabled(navModel.history.count <= 0)

                    Divider()
                        .frame(height: 15)

                    if navModel.navItems.count <= 5 {
                        ForEach(navModel.navItems, id: \.id) { item in
                            NavButton(item: item, navModel: navModel)

                            if item.id != navModel.navItems.last?.id {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                            }
                        }
                    } else {
                        NavButton(item: navModel.navItems.first!, navModel: navModel)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))

                        Text("...")

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                        NavButton(item: navModel.navItems.last!, navModel: navModel)
                    }

                }
                .padding(5)
                .frame(minWidth: 600, maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(Color.black)
            }
            navModel.current
                .environmentObject(navModel)
        }
    }
}

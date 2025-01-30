import SwiftUI
import AWSS3

struct TableSideBarItem {
    var name: String
    var icon: String = "star"
    var action: () -> Void = {}
    var disabled: Bool = false
}

struct TableSidebar: View {
    let items: [TableSideBarItem]

    var body: some View {
        VStack(spacing: 20) {
            ForEach(items, id: \.name) { item in
                Button(action: item.action) {
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                }
                .buttonStyle(.borderless)
                .help(item.name)
                .disabled(item.disabled)
            }
        }
        .padding(.vertical, 10)
        .frame(minWidth: 40, maxHeight: .infinity, alignment: .top)

    }
}

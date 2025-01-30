import SwiftUI
import AWSS3

private struct TableField: View {
    let config: TableConfig
    let item: TableItem
    let index: Int

    private func formatBytes(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(bytes)
        var unitIndex = 0

        while size >= 1000 && unitIndex < units.count - 1 {
            size /= 1000
            unitIndex += 1
        }

        let formattedSize = String(format: size.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", size)
        return "\(formattedSize) \(units[unitIndex])"
    }

    private func render(type: FieldTypes, value: Any?) -> String {

        guard let itemValue = value else { return "-" }

        switch type {
        case .string:
            if let str = itemValue as? String {
                return "\(str)"
            }
        case .number:
            if let nb = itemValue as? Int {
                return String(nb)
            }
        case .null:
            return "NULL"
        case .date:
            if let date = (itemValue as? Date) {
                return DateFormat.string(from: date)
            }
        case .size:
            if let size = (itemValue as? Int) {
                return formatBytes(size)
            }
        case .boolean:
            if let bool = (itemValue as? Bool) {
                return bool ? "True" : "False"
            }
        case .binary:
            if let data = (itemValue as? Data) {
                return data.base64EncodedString()
            }
        case .list:
            if let list = (itemValue as? [TableItem]) {
                return "[" + list.map { item in return render(type: item.type, value: item.value ) }.joined( separator: ", ") + "]"
            }
        case .map:
            if let map = (itemValue as? [(key: String, value: TableItem)]) {
                return "{" + map.map { key, value in return "\"\(key)\": \(render(type: value.type, value: value.value ))"  }.joined( separator: ", ") + "}"
            }
        case .string_set, .binary_set, .boolean_set, .number_set, .size_set, .date_set:
            if let set = (itemValue as? [TableItem]) {
                return "(" + set.map { item in return render(type: getSetPrimitiveType(type), value: item.value ) }.joined( separator: ", ") + ")"
            }
        }
        return "-"
    }

    var body: some View {
        Text(render(type: item.type, value: item.value))
            .lineLimit(1)
            .truncationMode(.tail)
            .layoutPriority(Double(index))
            .frame(minWidth: config.minWidth, maxWidth: (config.maxWidth ?? .infinity), alignment: config.alignment)
            .padding(.trailing, 10)
    }

}

private struct TableLineView: View {
    @EnvironmentObject var tableModel: TableModel
    @Binding var line: TableLine
    @State private var hover = false

    var hoverColor: Color {
        if !line.disabled {
            if line.isSelected {
                return Color.gray.opacity(0.2)
            }
            if hover {
                return Color.gray.opacity(0.1)
            }
        }
        return Color.clear
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tableModel.tableConfig.enumerated()), id: \.element.id) { (index, item) in
                if index < line.items.count {
                    TableField(config: item, item: line.items[index], index: index)
                } else {
                    TableField(config: item, item: TableItem(type: .string), index: index)
                }
                if index != line.items.count - 1 {
                    Spacer()
                }
            }
        }
        .frame(height: 25)
        .padding(.horizontal, 10)
        .opacity(line.disabled ? 0.5 : 1)
        .background(hoverColor)
        .cornerRadius(3)
        .onHover { hovering in
            hover = hovering
        }
        .gesture(TapGesture(count: 2).onEnded {
            if !line.disabled {
                line.action(line)
            }
        })
        .simultaneousGesture(TapGesture().onEnded {
            if !line.disabled {
                if !NSEvent.modifierFlags.contains(.command) {
                    tableModel.clearSelected()
                }
                line.isSelected.toggle()
                tableModel.objectWillChange.send()
            }
        })
    }
}

private struct TableHeader: View {
    @EnvironmentObject var items: TableModel
    var body: some View {
        HStack(spacing: 0) {

            ForEach(Array(items.tableConfig.enumerated()), id: \.element.hashValue) { (index, item) in
                Text(item.label)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(Double(index))
                    .frame(minWidth: item.minWidth, maxWidth: (item.maxWidth ?? .infinity), alignment: item.alignment)

                if item.id != items.tableConfig.last?.id {
                    Divider()
                    Spacer()
                }
            }
        }
        .frame(height: 25)
        .padding(.horizontal, 10)
        .cornerRadius(7)

    }
}

private struct TableContent: View {
    @State private var searchText: String = ""
    @EnvironmentObject var tableModel: TableModel
    let searchBarFunction: ((TableLine, String) -> Bool)?
    let isSidebar: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if searchBarFunction != nil {
                    TextField("Search...", text: $searchText)
                        .frame(minHeight: 40, alignment: .leading)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 5)
                }

                HStack {
                    Button(action: {
                        tableModel.currentPage -= 1
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    .disabled(tableModel.currentPage == 1)

                    Text(String(tableModel.currentPage))

                    Button(action: {
                        tableModel.currentPage += 1
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                    .disabled(tableModel.currentPage == tableModel.nbPages)
                }
                .frame(minHeight: 40, alignment: .trailing)
                .padding(.horizontal)
                .onAppear {
                    if let loadContent = tableModel.loadContentFunction {
                        loadContent(tableModel.currentPage)
                    }
                }
                .onChange(of: tableModel.currentPage) {
                    if let loadContent = tableModel.loadContentFunction {
                        loadContent(tableModel.currentPage)
                    }
                }

            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            Divider()
                .background(Color.black)

            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    VStack(spacing: 0) {
                        TableHeader()
                        Divider()
                            .padding(.vertical, 5)
                        ScrollView(.vertical) {
                            VStack(spacing: 0) {
                                ForEach($tableModel.items) { $item in
                                    if let sf = searchBarFunction {
                                        if searchText.isEmpty || sf(item, searchText) {
                                            TableLineView(line: $item)
                                                .padding(.vertical, 2)
                                            Divider()
                                        }
                                    } else {
                                        TableLineView(line: $item)
                                            .padding(.vertical, 2)
                                        Divider()

                                    }
                                }
                            }
                        }
                    }
                    .frame(minWidth: geometry.size.width - 32, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(16)
                }
            }
        }
    }
}

struct Table: View {
    @StateObject var tableModel: TableModel
    let sideBarItems: [TableSideBarItem]?
    let searchBarFunction: ((TableLine, String) -> Bool)?

    @State var isSideBar: Bool

    init(tableModel: TableModel, sideBarItems: [TableSideBarItem]? = nil, searchBarFunction: ((TableLine, String) -> Bool)? = nil) {
        self._tableModel = StateObject(wrappedValue: tableModel)
        self.sideBarItems = sideBarItems
        self.searchBarFunction = searchBarFunction
        if let sb = sideBarItems, !sb.isEmpty {
            self.isSideBar = true
        } else {
            self.isSideBar = false
        }
//        self.loadContentFunction = loadContentFunction
    }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                if let sideBar = sideBarItems {
                    if !sideBar.isEmpty {
                        TableSidebar(items: sideBar)
                        Divider()
                            .background(Color.black)
                    }
                }
                TableContent(searchBarFunction: searchBarFunction, isSidebar: isSideBar)
                    .environmentObject(tableModel)
            }

        }
        .frame(minWidth: 600)
    }
}

import SwiftUI
import AWSS3

fileprivate struct TableField: View {
    let config: TableConfigItem
    let item: TableFieldItem
    let index: Int
    
    var body: some View {
        if (config.type == .text) {
            let str = (item.value as? String) ?? "bad format";
            Text(str)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(Double(index))
                .frame(minWidth: config.minWidth, maxWidth: (config.maxWidth ?? .infinity), alignment: config.alignment)
        }
        if (config.type == .date) {
            let date = (item.value as? Date);
            let dateStr = date != nil ? DateFormat.string(from: date!) : "bad format";
            Text(dateStr)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(Double(index))
                .frame(minWidth: config.minWidth, maxWidth: (config.maxWidth ?? .infinity), alignment: config.alignment)
        }
    }
}

fileprivate struct TableLine: View {
    @EnvironmentObject var items: TableItemsModel
    @Binding var line: TableItem
    @State private var hover = false
    
    
    var hoverColor: Color {
        if (!line.disabled) {
            if (line.isSelected) {
                return Color.gray.opacity(0.2)
            }
            if (hover) {
                return Color.gray.opacity(0.1)
            }
        }
        return Color.clear
    }
    
    var body: some View {
        HStack (spacing: 0) {
            ForEach(Array(line.fields.enumerated()), id: \.element.hashValue) { (index, item) in
                
                TableField(config: items.tableConfig[index], item: item, index: index)
                    .frame(maxWidth: .infinity)
                if (item.id != line.fields.last?.id) {
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
            if (!line.disabled) {
                line.action(line)
            }
        })
        .simultaneousGesture(TapGesture().onEnded {
            if (!line.disabled) {
                if !NSEvent.modifierFlags.contains(.command) {
                    items.clearSelected()
                }
                line.isSelected.toggle()
                items.objectWillChange.send()
            }
        })
    }
}

fileprivate struct TableHeader: View {
    @EnvironmentObject var items: TableItemsModel
    var body: some View {
        HStack (spacing: 0) {
            
            
            ForEach(Array(items.tableConfig.enumerated()), id: \.element.hashValue) { (index, item) in
                Text(item.label)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(Double(index))
                    .frame(minWidth: item.minWidth, maxWidth: (item.maxWidth ?? .infinity), alignment: item.alignment)
                

                if (item.id != items.tableConfig.last?.id) {
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

fileprivate struct TableContent: View {
    @State private var searchText: String = ""
    @EnvironmentObject var items: TableItemsModel
    let searchBarFunction: ((TableItem, String) -> Bool)?
    let isSidebar: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if searchBarFunction != nil {
                TextField("Search...", text: $searchText)
                    .frame(minHeight: 40)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 5)
                Divider()
                    .background(Color.black)
            }
            
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    VStack(spacing: 0)  {
                        TableHeader()
                        Divider()
                            .padding(.vertical, 5)
                        ScrollView(.vertical) {
                            VStack(spacing: 0)  {
                                if (!items.items.isEmpty) {
                                    ForEach($items.items) { $item in
                                        if let sf = searchBarFunction {
                                            if (searchText.isEmpty || sf(item, searchText)) {
                                                
                                                TableLine(line: $item)
                                                    .padding(.vertical, 2)
                                                Divider()
                                            }
                                        } else {
                                            TableLine(line: $item)
                                                .padding(.vertical, 2)
                                            Divider()
                                            
                                        }
                                        
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
    @StateObject var tableItems: TableItemsModel
    let sideBarItems: [TableSideBarItem]?
    let searchBarFunction: ((TableItem, String) -> Bool)?
    @State var isSideBar: Bool

    init(tableItems: TableItemsModel, sideBarItems: [TableSideBarItem]? = nil, searchBarFunction: ((TableItem, String) -> Bool)? = nil) {
        self._tableItems = StateObject(wrappedValue: tableItems)
        self.sideBarItems = sideBarItems
        self.searchBarFunction = searchBarFunction
        if let sb = sideBarItems, !sb.isEmpty {
            self.isSideBar = true
        } else {
            self.isSideBar = false
        }
    }

    var body: some View {
        VStack {
            HStack (spacing: 0){
                if let sideBar = sideBarItems {
                    if (!sideBar.isEmpty) {
                        TableSidebar(items: sideBar)
                        Divider()
                            .background(Color.black)
                    }
                }
                TableContent(searchBarFunction: searchBarFunction, isSidebar: isSideBar)
                    .environmentObject(tableItems)
            }
            
        }
        .frame(minWidth: 600)
    }
}

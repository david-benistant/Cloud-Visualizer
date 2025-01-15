import SwiftUI

struct FileExplorer<Content: View>: View {
    @Binding var files: [FilesModel]
    
    var canChooseFiles: Bool = true
    var canChooseDirectories: Bool = false
    var allowsMultipleSelection: Bool = false
    let buttonContent: Content
    
    init(
        files: Binding<[FilesModel]>,
        canChooseFiles: Bool = true,
        canChooseDirectories: Bool = false,
        allowsMultipleSelection: Bool = false,
        @ViewBuilder buttonContent: () -> Content
    ) {
        self._files = files
        self.canChooseFiles = canChooseFiles
        self.canChooseDirectories = canChooseDirectories
        self.allowsMultipleSelection = allowsMultipleSelection
        self.buttonContent = buttonContent()
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = canChooseFiles
        panel.canChooseDirectories = canChooseDirectories
        panel.allowsMultipleSelection = allowsMultipleSelection

        if panel.runModal() == .OK {
            for url in panel.urls {
                files.append(FilesModel(rootUrl: url))
            }
        }
    }
    
    var body: some View {
        Button(action: {
            openFilePicker()
        }) {
            buttonContent
        }
    }
}

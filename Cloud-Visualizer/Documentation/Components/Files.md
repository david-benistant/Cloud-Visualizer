# Files

## FileExplorer Component

The `FileExplorer` component is a SwiftUI view that allows users to select files or directories using a native file picker dialog. It provides flexibility in terms of whether files, directories, or both can be selected, and whether multiple selections are allowed.

### Initialization

The `FileExplorer` component is initialized with the following parameters:

- **`files`**: A binding to an array of `FilesModel` objects.
- **`canChooseFiles`**: A boolean value that determines whether files can be selected.
- **`canChooseDirectories`**: A boolean value that determines whether directories can be selected.
- **`allowsMultipleSelection`**: A boolean value that determines whether multiple files or directories can be selected.
- **`buttonContent`**: A view builder closure that provides the content for the button.

### Example Usage

```swift
struct ContentView: View {
    @State private var files: [FilesModel] = []

    var body: some View {
        FileExplorer(files: $files) {
            Text("Select Files")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

```
In this example, the `FileExplorer` component is used to allow the user to select files. The selected files will be added to the `files` array, and the button will display the text "Select Files" with a blue background.

### Notes

- The `FilesModel` type should be defined elsewhere in your project. It should have an initializer that accepts a `rootUrl` parameter of type `URL`.
- This component is designed for macOS, as it uses `NSOpenPanel`, which is part of AppKit.



## DropZone Component

The `DropZone` component is a SwiftUI view designed to handle file drops and display the list of dropped files. It provides a visual area where users can drag and drop files, and it dynamically updates to show the list of files that have been dropped. The component also allows users to remove individual files from the list.

### Features
- **Drag and Drop Support**: Users can drag files from their file system and drop them into the designated area.
- **File List Display**: The component displays a list of dropped files, showing their names.
- **File Removal**: Users can remove individual files from the list.

### Example

To use the `DropZone` component, simply include it in your SwiftUI view hierarchy and bind it to an array of `FilesModel` objects.

```swift
struct ContentView: View {
    @State private var files: [FilesModel] = []

    var body: some View {
        DropZone(files: $files)
            .frame(width: 300, height: 200)
    }
}
```


### Notes
- Ensure that the `FilesModel` type is properly defined in your project to handle file URLs and their display names.
- The component uses `NSItemProvider` to handle file drops, so it is compatible with macOS and iOS platforms that support drag and drop functionality.



## FilesModel Struct

The `FilesModel` struct is designed to manage and organize file URLs, including directories and their contents. It provides functionality to explore directories, retrieve file information, and manage file lists. This struct is used in conjunction with the `DropZone` component to handle dropped files and directories.

### Features
- **Directory Exploration**: Automatically explores directories and includes their contents in the file list.
- **File Management**: Allows adding, removing, and retrieving file URLs.
- **Pretty File Names**: Generates user-friendly file names for display purposes.
- **Directory Handling**: Differentiates between files and directories, ensuring proper handling of nested structures.

### Usage

To use the `FilesModel` struct, initialize it with a root URL. The struct will automatically determine if the URL points to a directory and explore its contents if necessary.

```swift
let url = URL(fileURLWithPath: "/path/to/directory")
var filesModel = FilesModel(rootUrl: url)

// Get pretty file names for display
let fileNames = filesModel.getPrettyFilesName()
print(fileNames)

// Remove a file by index
filesModel.removeFile(index: 0)

// Check if the model is empty
if filesModel.isEmpty() {
    print("No files remaining")
}
```


### Notes
- The `FilesModel` struct uses `URL` to represent file paths, ensuring compatibility with macOS and iOS file systems.
- Directories are explored recursively, and their contents are included in the file list.
- The `getPrettyFilesName()` method generates display-friendly names, including relative paths for nested files and directories.
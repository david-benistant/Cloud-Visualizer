import SwiftUI
import UniformTypeIdentifiers

struct DropZone: View {
    @Binding var files: [FilesModel]
    @State private var isHighlighted: Bool = false

    private func deleteFile(i: Int, j: Int) {
        guard i >= 0, i < files.count else {
            return
        }
        files[i].removeFile(index: j)
        if files[i].isEmpty() {
            files.remove(at: i)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, _) in
                    DispatchQueue.main.async {
                        if let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil) {
                            files.append(FilesModel(rootUrl: url))
                        }
                    }
                }
            }
        }
        return true
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if files.isEmpty {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 40))
                } else {
                    List {
                        ForEach(Array(files.enumerated()), id: \.element) { index, file in
                            ForEach(Array(file.getPrettyFilesName().enumerated()), id: \.element) { subIndex, f in
                                HStack {
                                    Text("\(f)")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .frame(maxWidth: geometry.size.width - 10, alignment: .leading)
                                    Spacer()
                                    Divider()
                                    Button(action: {
                                        deleteFile(i: index, j: subIndex)
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 15))
                                            .frame(height: 15)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .onDrop(of: [UTType.fileURL], isTargeted: $isHighlighted) { providers in
                handleDrop(providers: providers)
            }
        }
    }
}

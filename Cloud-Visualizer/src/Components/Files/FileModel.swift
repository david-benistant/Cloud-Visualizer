import SwiftUI

struct FilesModel: Hashable {
    private let _id: UUID = UUID()
    private var files: [URL] = []
    private var _isDirectory: Bool = false
    
    init(rootUrl: URL) {
        if (rootUrl.hasDirectoryPath) {
            self._isDirectory = true
            self.explore(url: rootUrl)
        } else {
            self._isDirectory = false
            files.append(rootUrl)
        }
    }
    
    func getRootDir() -> URL? {
        if (self._isDirectory) {
            return files.first
        }
        return nil
    }
    
    func isDirectory() -> Bool {
        return self._isDirectory
    }
    
    func getFiles() -> [URL] {
        return files
    }
    
    func isEmpty() -> Bool {
        return files.isEmpty
    }
    
    func getPrettyFilesName() -> [String] {
        var out: [String] = []
        if let originUrl = files.first {
            var originTmpName = originUrl.lastPathComponent
            if (originUrl.hasDirectoryPath) {
                originTmpName += "/"
            }
            out.append(originTmpName)

            var remainsUrls = files
            remainsUrls.removeFirst()

            for url in remainsUrls {
                let relativePath = String(url.path.replacingOccurrences(of: originUrl.path + "/", with: "").dropLast(url.lastPathComponent.count))
                var tmpName = originTmpName + relativePath + url.lastPathComponent
                if (url.hasDirectoryPath) {
                    tmpName += "/"
                }
                out.append(tmpName)
            }
        }
        return out;
    }

    mutating func removeFile(url: URL) -> Void {
        files.removeAll { $0 == url }
    }
    
    mutating func removeFile(index: Int) -> Void {
        guard index < files.count else {
            print("Index hors limites")
            return
        }
        
        let fileURL = files[index]
        if (fileURL.hasDirectoryPath) {
            files = files.filter { file in
                !file.path.hasPrefix(fileURL.path)
            }
        } else {
            files.remove(at: index)
        }
    }

    private mutating func explore(url: URL) -> Void {
        files.append(url)
        if (url.hasDirectoryPath) {
            let fileManager = FileManager.default
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    files.append(fileURL)
                }
            }
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self._id)
    }
    
}

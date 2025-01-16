import SwiftUI

// https://en.wikipedia.org/wiki/List_of_file_signatures

fileprivate func nonBinaryTypes(_ data: Data) -> MimeType {
    guard let content = String(data: data, encoding: .utf8) else {
        return .unknown
    }
    
    let isPrintable = content.allSatisfy { character in
        if let scalar = character.unicodeScalars.first {
            return scalar.isASCII
        }
        return false
    }
    
    if !isPrintable {
        return .unknown
    }
    
    if content.starts(with: "<svg") {
        return .svg
    } else if content.contains("<html") || content.contains("<!DOCTYPE html>") || content.contains("<div") || content.contains("<span") {
        return .html
    } else {
        return .txt
    }
}

func getDataMimeType(from data: Data) -> MimeType {    
    if data.prefix(4) == Data([0xFF, 0xD8, 0xFF, 0xE0]) {
        return .jpg
    }
    if data.prefix(4) == Data([0xFF, 0xD8, 0xFF, 0xEE]) {
        return .jpg
    }
    if data.prefix(4) == Data([0xFF, 0xD8, 0xFF, 0xE1]) && data.subdata(in: 6..<12) == Data([0x45, 0x78, 0x69, 0x66, 0x00, 0x00]) {
        return .jpg
    }
    if data.prefix(12) == Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01]) {
        return .jpg
    }
    if data.prefix(8) == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
        return .png
    }
    if data.prefix(6) == Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) {
        return .gif
    }
    if data.prefix(6) == Data([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) {
        return .gif
    }
    if data.prefix(5) == Data([0x25, 0x50, 0x44, 0x46, 0x2D]) {
        return .pdf
    }
    if data.prefix(4) == Data([0x52, 0x49, 0x46, 0x46]) && data.subdata(in: 8..<12) == Data([0x57, 0x45, 0x42, 0x50]) {
        return .webp
    }

    return nonBinaryTypes(data)
}

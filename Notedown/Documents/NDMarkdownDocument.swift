//
//  NDMarkdownDocument.swift
//  Notedown
//
//  Created by Aaron on 5/12/23.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }
}

struct NDMarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.markdown] }
    static var writableContentTypes: [UTType] { [.markdown] }
    
    var page: NDDocument.Page
    
    init() {
        self.page = NDDocument.Page(contents: "", fileName: "Untitled.md")
    }
    
    init(configuration: ReadConfiguration) throws {
        guard
            let contentsData = configuration.file.regularFileContents,
            let contentsString = String(data: contentsData, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.page = NDDocument.Page(contents: contentsString, fileName: configuration.file.filename ?? "file.md")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = page.contents.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

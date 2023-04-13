//
//  NotedownDocument.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var noteBundle: UTType {
        UTType(exportedAs: "com.byteduck.notebundle")
    }
}

struct NDConfig: Codable {
    let version: Int
}

struct NDDocument: FileDocument {
    static let INFO = "info.json"
    static let DOCUMENT = "document.md"
    
    var config: NDConfig
    var documentContents: String

    init(text: String = "# Hello, world!") {
        self.documentContents = text
        self.config = NDConfig(version: 1)
    }

    static var readableContentTypes: [UTType] { [.noteBundle] }

    init(configuration: ReadConfiguration) throws {
        // First, read in the configuration and main document
        guard let infoData = configuration.file.fileWrappers?[NDDocument.INFO]?.regularFileContents,
              let info = try? JSONDecoder().decode(NDConfig.self, from: infoData),
              let documentData = configuration.file.fileWrappers?[NDDocument.DOCUMENT]?.regularFileContents,
              let contents = String(data: documentData, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        config = info
        documentContents = contents
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let documentData = documentContents.data(using: .utf8)!
        let configData = try JSONEncoder().encode(config)
        return .init(directoryWithFileWrappers: [
            NDDocument.DOCUMENT: FileWrapper(regularFileWithContents: documentData),
            NDDocument.INFO: FileWrapper(regularFileWithContents: configData)
        ])
    }
}

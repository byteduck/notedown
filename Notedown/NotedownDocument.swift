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

struct NotedownConfiguration: Codable {
    let version: Int
}

struct NotedownDocument: FileDocument {
    static let INFO = "info.json"
    static let DOCUMENT = "document.md"
    
    var config: NotedownConfiguration
    var documentContents: String

    init(text: String = "# Hello, world!") {
        self.documentContents = text
        self.config = NotedownConfiguration(version: 1)
    }

    static var readableContentTypes: [UTType] { [.noteBundle] }

    init(configuration: ReadConfiguration) throws {
        // First, read in the configuration and main document
        guard let infoData = configuration.file.fileWrappers?[NotedownDocument.INFO]?.regularFileContents,
              let info = try? JSONDecoder().decode(NotedownConfiguration.self, from: infoData),
              let documentData = configuration.file.fileWrappers?[NotedownDocument.DOCUMENT]?.regularFileContents,
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
            NotedownDocument.DOCUMENT: FileWrapper(regularFileWithContents: documentData),
            NotedownDocument.INFO: FileWrapper(regularFileWithContents: configData)
        ])
    }
}

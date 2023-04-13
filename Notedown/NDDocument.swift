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

class NDDocument: FileDocument {
    static let INFO = "info.json"
    
    var config: Config
    var pages: [Page] = []

    init(text: String = "# Hello, world!") {
        self.config = Config(version: 1)
        self.pages = [Page(document: self, contents: text, fileName: "Hello world.md")]
    }

    static var readableContentTypes: [UTType] { [.noteBundle] }

    required init(configuration: ReadConfiguration) throws {
        // First, read in the configuration
        guard
            let fileWrappers = configuration.file.fileWrappers,
            let infoData = fileWrappers[NDDocument.INFO]?.regularFileContents,
            let info = try? JSONDecoder().decode(Config.self, from: infoData)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.config = info
        
        // Read in the documents
        for documentFile in fileWrappers.filter({ $0.key.hasSuffix(".md") }) {
            guard
                let documentData = documentFile.value.regularFileContents,
                let documentText = String(data: documentData, encoding: .utf8)
            else {
                continue
            }
            pages.append(Page(document: self, contents: documentText, fileName: documentFile.key))
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Write config
        let configData = try JSONEncoder().encode(config)
        var fileWrappers = [
            NDDocument.INFO: FileWrapper(regularFileWithContents: configData)
        ]
        
        // Write dirty markdown files
        pages.filter({ $0.dirty }).forEach({ page in
            let documentData = page.contents.data(using:.utf8)!
            fileWrappers[page.fileName] = FileWrapper(regularFileWithContents: documentData)
        })
        
        return .init(directoryWithFileWrappers: fileWrappers)
    }
}

extension NDDocument {
    struct Config: Codable {
        let version: Int
    }
}

extension NDDocument {
    struct Page {
        weak var document: NDDocument?
        var contents: String
        let fileName: String
        var title: String {
            get {
                let firstLine = contents[contents.lineRange(for: contents.startIndex...contents.startIndex)]
                if let headerRange = firstLine.firstMatch(of: NDSyntaxRegex.header)?.range {
                    return String(firstLine[headerRange.upperBound...firstLine.endIndex])
                }
                return String(firstLine)
            }
        }
        var dirty = false
    }
}

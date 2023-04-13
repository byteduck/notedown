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
        self.pages[0].dirty = true
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
        
        // Then, read in the pages
        for documentFile in fileWrappers.filter({ $0.key.hasSuffix(".md") }) {
            guard
                let documentData = documentFile.value.regularFileContents,
                let documentText = String(data: documentData, encoding: .utf8)
            else {
                continue
            }
            pages.append(Page(document: self, contents: documentText, fileName: documentFile.key, dirty: false))
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var fileWrappers = configuration.existingFile?.fileWrappers ?? [:]
        
        print(Unmanaged.passUnretained(self).toOpaque())
        
        // Write config
        fileWrappers[NDDocument.INFO] = FileWrapper(regularFileWithContents: try JSONEncoder().encode(config))
        
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
        var version: Int
        /// The filename of the page open when the document was saved.
        var openPage: String?
    }
}

extension NDDocument {
    class Page: Identifiable, Hashable {
        weak var document: NDDocument?
        var contents: String
        let fileName: String
        var title: String {
            get {
                let firstLine = contents[contents.lineRange(for: contents.startIndex..<contents.startIndex)]
                if let headerRange = firstLine.firstMatch(of: NDSyntaxRegex.header)?[1].range {
                    return String(firstLine[headerRange.upperBound..<firstLine.endIndex])
                }
                return String(firstLine)
            }
        }
        @Published var dirty = false
        
        init(document: NDDocument, contents: String, fileName: String, dirty: Bool = true) {
            self.document = document
            self.contents = contents
            self.fileName = fileName
        }
        
        // Identifiable, Equatable, Hashable
        
        var id: String {
            get { fileName }
        }
        
        static func ==(lhs: NDDocument.Page, rhs: NDDocument.Page) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

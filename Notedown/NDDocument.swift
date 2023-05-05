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

class NDDocument: ReferenceFileDocument {
    static let INFO = "info.json"
    
    @Published var notebook: Notebook

    init() {
        self.notebook = Notebook(config: Config(version: 1))
    }

    static var readableContentTypes: [UTType] { [.noteBundle] }
    static var writableContentTypes: [UTType] { [.noteBundle] }

    required init(configuration: ReadConfiguration) throws {
        // First, read in the configuration
        guard
            let fileWrappers = configuration.file.fileWrappers,
            let infoData = fileWrappers[NDDocument.INFO]?.regularFileContents,
            let info = try? JSONDecoder().decode(Config.self, from: infoData)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.notebook = Notebook(config: info)
        
        // Then, read in the pages
        for documentFile in fileWrappers.filter({ $0.key.hasSuffix(".md") }) {
            guard
                let documentData = documentFile.value.regularFileContents,
                let documentText = String(data: documentData, encoding: .utf8)
            else {
                continue
            }
            notebook.pages.append(Page(contents: documentText, fileName: documentFile.key, dirty: false))
        }
        
        // Finally, read in the images
        for imageFile in fileWrappers.filter({ !$0.key.hasSuffix(".md") && !$0.key.hasSuffix(".json") }) {
            guard let imageData = imageFile.value.regularFileContents else {
                continue
            }
            notebook.images.append(NDImage(fileName: imageFile.key, data: imageData))
        }
    }
    
    typealias Snapshot = Notebook
    func snapshot(contentType: UTType) throws -> Notebook {
        return notebook
    }
    
    func fileWrapper(snapshot: Notebook, configuration: WriteConfiguration) throws -> FileWrapper {
        var fileWrappers = configuration.existingFile?.fileWrappers ?? [:]
        
        // Remove deleted pages and images from fileWrappers
        fileWrappers = fileWrappers.filter({ wrapper in
            notebook.pages.contains(where: { $0.fileName == wrapper.key }) ||
            notebook.images.contains(where: { $0.fileName == wrapper.key }) ||
            wrapper.key == NDDocument.INFO
        })
        
        // Write config
        fileWrappers[NDDocument.INFO] = FileWrapper(regularFileWithContents: try JSONEncoder().encode(notebook.config))
        
        // Write dirty markdown files
        for i in notebook.pages.indices {
            DispatchQueue.main.async {
                self.notebook.pages[i].dirty = false
            }
            let documentData = notebook.pages[i].contents.data(using:.utf8)!
            fileWrappers[notebook.pages[i].fileName] = FileWrapper(regularFileWithContents: documentData)
        }
        
        // Write dirty images
        for i in notebook.images.indices {
            DispatchQueue.main.async {
                self.notebook.images[i].dirty = false
            }
            fileWrappers[notebook.images[i].fileName] = FileWrapper(regularFileWithContents: notebook.images[i].data)
        }
        
        return .init(directoryWithFileWrappers: fileWrappers)
    }
}

extension NDDocument {
    struct Notebook {
        var config: Config
        var pages: [Page] = []
        var images: [NDImage] = []
    }

    struct Config: Codable {
        /// The spec version of the config file.
        var version: Int
        /// The filename of the page open when the document was saved.
        var openPage: String?
    }

    struct NDImage {
        let fileName: String
        let image: NSImage
        let data: Data
        var dirty: Bool = false
        
        init(fileName: String, data: Data) {
            self.fileName = fileName
            self.image = NSImage(data: data) ?? NSImage()
            self.data = data
        }
    }
    
    struct Page: Identifiable, Hashable {
        var contents: String
        let fileName: String
        var title: String {
            get {
                var firstLine = contents[contents.lineRange(for: contents.startIndex..<contents.startIndex)]
                if firstLine.last == Character("\n") {
                    firstLine.removeLast()
                }
                if let headerRange = firstLine.firstMatch(of: NDSyntaxRegex.header)?[1].range {
                    return String(firstLine[headerRange.upperBound..<firstLine.endIndex])
                }
                return String(firstLine)
            }
        }
        var dirty = false
        
        init(contents: String, fileName: String, dirty: Bool = true) {
            self.contents = contents
            self.fileName = fileName
            self.dirty = dirty
        }
        
        init() {
            self.contents = ""
            self.fileName = ""
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

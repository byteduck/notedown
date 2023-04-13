//
//  NotedownApp.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import SwiftUI

@main
struct NDApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: NDDocument()) { file in
            NDEditorView(
                document: file.$document,
                configuration: .constant(NDMarkdownEditorConfiguration()),
                selectedPage: file.document.pages.first(where: { $0.fileName == file.document.config.openPage })
            )
        }
    }
}

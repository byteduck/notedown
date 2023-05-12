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
        DocumentGroup(newDocument: { NDDocument() }) { file in
            NDNotebookView(
                document: file.document,
                configuration: .constant(NDMarkdownEditorConfiguration()),
                selectedPage: file.$document.notebook.config.openPage
            )
        }
        .commands {
            CommandGroup(before: .textEditing) {
                Button("TEST") {}
            }
        }
    }
}

//
//  ContentView.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import SwiftUI

struct NDEditorView: View {
    @Binding var document: NDDocument
    @Binding var configuration: NDMarkdownEditorConfiguration

    var body: some View {
        NDMarkdownEditorView(page: $document.pages[0], configuration: $configuration)
    }
}

struct NDEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NDEditorView(document: .constant(NDDocument()), configuration: .constant(NDMarkdownEditorConfiguration()))
    }
}

//
//  NDEditorView.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

import Foundation
import SwiftUI
import AppKit

struct NDEditorView: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    
    @Binding var page: NDDocument.Page
    var document: NDDocument
    var configuration: NDMarkdownEditorConfiguration
    let scrollView = NDTextView.scrollableTextView()
    
    func makeNSView(context: Context) -> NSScrollView {
        let textView = scrollView.documentView as! NDTextView
        textView.document = document
        textView.delegate = context.coordinator
        textView.string = page.contents
        textView.allowsUndo = true
        textView.setup()
        
        updateConfiguration(context: context)
        
        return scrollView
    }
    
    func updateNSView(_ view: NSViewType, context: Context) {
        updateConfiguration(context: context)
    }
    
    func makeCoordinator() -> NDEditorCoordinator {
        NDEditorCoordinator(self)
    }
    
    func updateConfiguration(context: Context) {
        let textView = scrollView.documentView as! NSTextView
        textView.font = configuration.defaultFont
        textView.textColor = configuration.defaultColor
        context.coordinator.applyHighlighting(inRange: NSRange(location: 0, length: textView.string.count), withStorage: textView.textStorage!)
    }
}

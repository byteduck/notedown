//
//  NDEditorView.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

import Foundation
import SwiftUI

#if os(macOS)
import AppKit

struct NDEditorView: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    
    @Binding var page: NDDocument.Page
    var document: NDDocument?
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
        applyHighlighting(inRange: NSRange(location: 0, length: textView.string.count), withStorage: textView.textStorage!, configuration: configuration, document: document)
    }
}

#elseif os(iOS)
import UIKit

struct NDEditorView: UIViewRepresentable {
    typealias UIViewType = UITextView
    
    @Binding var page: NDDocument.Page
    var document: NDDocument?
    var configuration: NDMarkdownEditorConfiguration
    let textView = NDTextView()
    
    func makeUIView(context: Context) -> UITextView {
        textView.delegate = context.coordinator
        textView.text = page.contents
        textView.setup()
        
        updateConfiguration(context: context)
        
        return textView
    }
    
    func updateUIView(_ view: UIViewType, context: Context) {
        updateConfiguration(context: context)
    }
    
    func makeCoordinator() -> NDEditorCoordinator {
        NDEditorCoordinator(self)
    }
    
    func updateConfiguration(context: Context) {
        textView.font = configuration.defaultFont
        textView.textColor = configuration.defaultColor
        
        // Create new NSTextStorage. Things seem to work better this way
        let range = NSRange(location: 0, length: textView.string.count)
        applyHighlighting(inRange: range, withStorage: textView.textStorage, configuration: configuration, document: document)
    }
}

#endif

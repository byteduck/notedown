//
//  NDMarkdownEditor.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import Foundation
import AppKit
import SwiftUI

struct NDMarkdownEditorView: NSViewRepresentable {
    @Binding var page: NDDocument.Page
    var configuration: NDMarkdownEditorConfiguration
    
    let scrollView = NSTextView.scrollableTextView()
    
    func makeNSView(context: Context) -> some NSView {
        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.string = page.contents
        textView.allowsUndo = true
        
        updateConfiguration(context: context)
        
        return scrollView
    }
    
    func updateNSView(_ view: NSViewType, context: Context) {
        updateConfiguration(context: context)
    }
    
    func makeCoordinator() -> NDMarkdownEditorCoordinator {
        NDMarkdownEditorCoordinator(self)
    }
    
    func updateConfiguration(context: Context) {
        let textView = scrollView.documentView as! NSTextView
        textView.font = configuration.defaultFont
        textView.textColor = configuration.defaultColor
        context.coordinator.applyHighlighting(inRange: NSRange(location: 0, length: textView.string.count), withStorage: textView.textStorage!)
    }
}

extension NDMarkdownEditorView {
    class NDMarkdownEditorCoordinator: NSObject, NSTextViewDelegate {
        var parent: NDMarkdownEditorView
        var affectedCharRange: NSRange?

        init(_ parent: NDMarkdownEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let textStorage = textView.textStorage
            else {
                return
            }
            
            // Mark Dirty
            self.parent.page.dirty = true
            self.parent.page.contents = textView.string
            
            // Apply highlighting
            let string = textStorage.string
            guard
                let charRange = self.affectedCharRange,
                let editedRange = Range(charRange, in: string)
            else {
                return
            }
            
            let paragraphRange = string.paragraphRange(for: editedRange)
            textStorage.beginEditing()
            applyHighlighting(inRange: NSRange(paragraphRange, in: string), withStorage: textStorage)
            textStorage.endEditing()
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            self.affectedCharRange = affectedCharRange
            return performSyntaxCompletion(textView: textView, inRange: affectedCharRange, replacementString: replacementString)
        }
        
        func applyHighlighting(inRange range: NSRange, withStorage textStorage: NSTextStorage) {
            if range.length == 0 {
                return
            }
            
            let paragraphRange = textStorage.mutableString.paragraphRange(for: range)
            textStorage.setAttributes([
                .font: parent.configuration.defaultFont,
                .foregroundColor: parent.configuration.defaultColor
            ], range: paragraphRange)
            let string = textStorage.attributedSubstring(from: paragraphRange).string
            
            markdownSyntaxRules.forEach({ rule in
                // TODO: Cache rule attributes so we don't have to calculate them on the fly every time
                let ruleAttributes = rule.attributes(parent.configuration)
                string.matches(of: rule.regex).forEach({ match in
                    for rangeIndex in match.indices {
                        guard
                            rangeIndex < rule.styles.count,
                            let range = match[rangeIndex].range
                        else {
                            continue
                        }
                        
                        let nsRange = NSRange(range, in: string)
                        textStorage.addAttributes(ruleAttributes[rangeIndex], range: NSRange(location: nsRange.lowerBound + paragraphRange.lowerBound, length: nsRange.length))
                    }
                })
            })
        }
        
        func performSyntaxCompletion(textView: NSTextView, inRange range: NSRange, replacementString: String?) -> Bool {
            let viewString = textView.string
            
            guard
                let replacementString = replacementString,
                let stringRange = Range(range, in: viewString)
            else { return true }
            
            let lineRange = viewString.lineRange(for: stringRange)
            let lineString = viewString[lineRange]
            
            for processor in markdownProcessors {
                if !processor(textView, range, replacementString, lineRange, lineString) {
                    return false
                }
            }
            
            return true
        }
    }
}

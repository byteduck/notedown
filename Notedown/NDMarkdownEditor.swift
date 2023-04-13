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
    @Binding var configuration: NDMarkdownEditorConfiguration
    
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
            textStorage.setAttributes([
                .font: parent.configuration.defaultFont,
                .foregroundColor: parent.configuration.defaultColor
            ], range: range)
            let string = textStorage.string
            markdownSyntaxRules.forEach({ rule in
                string.matches(of: rule.regex).forEach({ match in
                    for rangeIndex in match.indices {
                        guard
                            rangeIndex < rule.styles.count,
                            let style = rule.styles[rangeIndex],
                            let range = match[rangeIndex].range
                        else {
                            continue
                        }
                        
                        textStorage.addAttributes(style, range: NSRange(range, in: string))
                    }
                })
            })
        }
        
        func performSyntaxCompletion(textView: NSTextView, inRange range: NSRange, replacementString: String?) -> Bool {
            let viewString = textView.string
            guard let replacementString = replacementString, let stringRange = Range(range, in: viewString) else {
                return true
            }
            let lineRange = viewString.lineRange(for: stringRange)
            let lineString = viewString[lineRange]
            
            // Unordered list completion
            if
                replacementString == "\n",
                let listMatch = lineString.firstMatch(of: NDSyntaxRegex.unorderedList),
                let bulletRange = listMatch[1].range
            {
                let bullet = lineString[bulletRange]
                var indentation = ""
                if let indentationRange = lineString.firstMatch(of: NDSyntaxRegex.whitespace)?.range {
                    indentation = String(lineString[indentationRange])
                }
                textView.replaceCharacters(in: range, with: "\(indentation)\(bullet) ")
            }
            
            // Ordered list completion
            if
                replacementString == "\n",
                let listMatch = lineString.firstMatch(of: NDSyntaxRegex.orderedList),
                let numberRange = listMatch[1].range,
                let number = Int(lineString[numberRange])
            {
                var indentation = ""
                if let indentationRange = lineString.firstMatch(of: NDSyntaxRegex.whitespace)?.range {
                    indentation = String(lineString[indentationRange])
                }
                textView.replaceCharacters(in: range, with: "\(indentation)\(number + 1). ")
            }
            
            // List indentation
            if replacementString == "\t" && (lineString.starts(with: NDSyntaxRegex.orderedList) || lineString.starts(with: NDSyntaxRegex.unorderedList)) {
                textView.replaceCharacters(in: NSRange(lineRange.lowerBound..<lineRange.lowerBound, in: viewString), with: "\t")
                return false
            }
            
            return true
        }
    }
}

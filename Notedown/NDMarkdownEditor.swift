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

class NDTextView: NSTextView {
    weak var document: NDDocument?
    var mousePosition: NSPoint = .zero
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let ret = super.performDragOperation(sender)
        
        // Get the image URL and data
        guard
            let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
            let data = try? Data(contentsOf: urls[0])
        else {
            return ret
        }
        
        // Get rid of the inserted text
        let selectionLocation = self.selectedRange().location
        self.textStorage?.replaceCharacters(in: self.selectedRange(), with: "")

        // Insert the image
        self.textStorage?.beginEditing()
        let imageTag = "<img src=\"\(urls[0].lastPathComponent)\" />"
        self.textStorage?.insert(NSAttributedString(string: imageTag), at: selectionLocation)
        self.textStorage?.endEditing()
        
        // Add the image to the document data
        document?.notebook.images.append(.init(fileName: urls[0].lastPathComponent, data: data))
        sender.draggingPasteboard.data(forType: .fileContents)
        
        return true
    }
    
    override func mouseMoved(with event: NSEvent) {
        self.mousePosition = self.convert(event.locationInWindow, from: nil)
        super.mouseMoved(with: event)
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
                    ?? Range(NSRange(location: charRange.lowerBound, length: 0), in: string) // If we're deleting characters at the very end of the string, then the original range will be out of bounds
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
        
        func applyHighlighting(inRange paragraphRange: NSRange, withStorage textStorage: NSTextStorage) {
            if paragraphRange.length == 0 {
                return
            }
            
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
                    
                    // Call custom action if we have one
                    if let action = rule.action {
                        action(self.parent.document, textStorage, paragraphRange, string, match)
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
            
            textView.textStorage?.beginEditing()
            defer { textView.textStorage?.endEditing() }
            
            for processor in markdownProcessors {
                if !processor(textView, range, replacementString, lineRange, lineString) {
                    return false
                }
            }
            
            return true
        }
        
        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            guard
                let textView = textView as? NDTextView,
                let link = link as? NDTextLink
            else {
                return false
            }
            
            switch(link) {
            case .image(let imageName):
                displayImageLink(textView, imageName: imageName)
            case .latex(let latex):
                displayLatex(textView, latex: latex)
            }
            
            return true
        }
        
        func displayImageLink(_ textView: NDTextView, imageName: String) {
            guard let image = parent.document.notebook.images.first(where: { $0.fileName == imageName }) else {
                return
            }
            
            let popover = NSPopover()
            let popoverController = NDImagePopoverViewController()
            popoverController.image = image.image
            popover.contentViewController = popoverController
            popover.behavior = .transient
            popover.animates = true
            popover.contentSize = image.image.size
            
            // For some reason, merely *accessing* textView.layoutManager causes the ENTIRE TEXT VIEW TO GO BLANK??? So, we do this for now.
            popover.show(relativeTo: NSRect(x: textView.mousePosition.x, y: textView.mousePosition.y, width: 1, height: 1), of: textView, preferredEdge: .minY)
        }
        
        func displayLatex(_ textView: NDTextView, latex: String) {
            renderLatex(latex) { image in
                let popover = NSPopover()
                let popoverController = NDImagePopoverViewController()
                popoverController.image = image
                popover.contentViewController = popoverController
                popover.behavior = .transient
                popover.animates = true
                popover.contentSize = image.size
                popover.show(relativeTo: NSRect(x: textView.mousePosition.x, y: textView.mousePosition.y, width: 1, height: 1), of: textView, preferredEdge: .minY)
            }
        }
    }
}

//
//  NDEditorCoordinator.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

import AppKit
import SwiftUI

class NDEditorCoordinator: NSObject, NSTextViewDelegate {
    var parent: NDEditorView
    var affectedCharRange: NSRange?

    init(_ parent: NDEditorView) {
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
        let mousePosition = textView.mousePosition
        renderLatex(latex) { image in
            let popover = NSPopover()
            let popoverController = NDImagePopoverViewController()
            popoverController.image = image
            popover.contentViewController = popoverController
            popover.behavior = .transient
            popover.animates = true
            popover.contentSize = image.size
            popover.show(relativeTo: NSRect(x: mousePosition.x, y: mousePosition.y, width: 1, height: 1), of: textView, preferredEdge: .minY)
        }
    }
}

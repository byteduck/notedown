//
//  NDEditorCoordinator+iOS.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

#if os(iOS)
import UIKit
import SwiftUI

class NDEditorCoordinator: NSObject, UITextViewDelegate {
    var parent: NDEditorView
    var affectedCharRange: NSRange?

    init(_ parent: NDEditorView) {
        self.parent = parent
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Mark Dirty
        self.parent.page.dirty = true
        self.parent.page.contents = textView.string
        
        // Apply highlighting
        let string = textView.textStorage.string
        guard
            let charRange = self.affectedCharRange,
            let editedRange = Range(charRange, in: string)
                ?? Range(NSRange(location: charRange.lowerBound, length: 0), in: string) // If we're deleting characters at the very end of the string, then the original range will be out of bounds
        else {
            return
        }
        
        let paragraphRange = string.paragraphRange(for: editedRange)
        textView.textStorage.beginEditing()
        applyHighlighting(inRange: NSRange(paragraphRange, in: string), withStorage: textView.textStorage, configuration: parent.configuration, document: parent.document)
        textView.textStorage.endEditing()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        self.affectedCharRange = range
        return performSyntaxCompletion(textView: textView, inRange: range, replacementString: text)
    }
    
//    func textView(_ textView: UITextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
//        guard
//            let textView = textView as? NDTextView,
//            let link = link as? NDTextLink
//        else {
//            return false
//        }
//
//        switch(link) {
//        case .image(let imageName):
//            displayImageLink(textView, imageName: imageName)
//        case .latex(let latex):
//            displayLatex(textView, latex: latex)
//        }
//
//        return true
//    }
    
//    func displayImageLink(_ textView: NDTextView, imageName: String) {
//        guard let image = parent.document.notebook.images.first(where: { $0.fileName == imageName }) else {
//            return
//        }
//
//        let popover = NSPopover()
//        let popoverController = NDImagePopoverViewController()
//        popoverController.image = image.image
//        popover.contentViewController = popoverController
//        popover.behavior = .transient
//        popover.animates = true
//        popover.contentSize = image.image.size
//
//        // For some reason, merely *accessing* textView.layoutManager causes the ENTIRE TEXT VIEW TO GO BLANK??? So, we do this for now.
//        popover.show(relativeTo: NSRect(x: textView.mousePosition.x, y: textView.mousePosition.y, width: 1, height: 1), of: textView, preferredEdge: .minY)
//    }
//
//    func displayLatex(_ textView: NDTextView, latex: String) {
//        let mousePosition = textView.mousePosition
//        renderLatex(latex) { image in
//            let popover = NSPopover()
//            let popoverController = NDImagePopoverViewController()
//            popoverController.image = image
//            popover.contentViewController = popoverController
//            popover.behavior = .transient
//            popover.animates = true
//            popover.contentSize = image.size
//            popover.show(relativeTo: NSRect(x: mousePosition.x, y: mousePosition.y, width: 1, height: 1), of: textView, preferredEdge: .minY)
//        }
//    }
}

#endif


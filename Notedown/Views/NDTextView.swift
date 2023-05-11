//
//  NDTextView.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import Foundation
import AppKit
import SwiftUI

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



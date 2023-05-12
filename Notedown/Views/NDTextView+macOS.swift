//
//  NDTextView.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

#if os(macOS)

import Foundation
import AppKit
import SwiftUI

class NDTextView: NSTextView {
    weak var document: NDDocument?
    var mousePosition: NSPoint = .zero
    
    func setup() {
        guard let scrollView = enclosingScrollView else {
            fatalError()
        }
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(scrollViewDidResize(_:)),
                         name: NSView.boundsDidChangeNotification,
                         object: scrollView.contentView)
    }
    
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
    
    /// Overscroll Behavior
    
    private var overscrollY: CGFloat = 0
    
    @objc func scrollViewDidResize(_ notification: Notification) {
        guard let clipView = notification.object as? NSClipView else {
            return
        }
        let offset = clipView.bounds.height / 4
        textContainerInset = NSSize(width: 0, height: offset)
        overscrollY = offset
        
        // Ensure we pre-calculate the layout for the whole document so that scrolling is buttery smooth.
        // This also fixes a weird bug where the scrollbar can freak out the first time we scroll.
        if
            let layoutManager = textLayoutManager,
            let documentRange = layoutManager.textContentManager?.documentRange
        {
            layoutManager.ensureLayout(for: documentRange)
        }
    }
    
    override var textContainerOrigin: NSPoint {
        return super.textContainerOrigin.applying(.init(translationX: 0, y: -overscrollY))
    }
}

#endif

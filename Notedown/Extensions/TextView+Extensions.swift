//
//  TextView+Extensions.swift
//  Notedown
//
//  Created by Aaron on 4/18/23.
//

import Foundation

extension NDPlatformTextView {
    func replaceWithUndo(in range: NSRange, with string: String, moveCursor: Bool = false) {
        #if os(macOS)
        let oldString = textStorage?.attributedSubstring(from: range).string ?? ""
        textStorage?.replaceCharacters(in: range, with: string)
        undoManager?.registerUndo(withTarget: self, handler: { _ in
            self.textStorage?.replaceCharacters(in: NSRange(location: range.location, length: string.count), with: oldString)
        })
        #elseif os(iOS)
        let oldString = textStorage.attributedSubstring(from: range).string
        textStorage.replaceCharacters(in: range, with: string)
        undoManager?.registerUndo(withTarget: self, handler: { _ in
            self.textStorage.replaceCharacters(in: NSRange(location: range.location, length: string.count), with: oldString)
        })
        if moveCursor {
            self.selectedRange = NSRange(location: range.location + string.count, length: 0)
        }
        #endif
    }
    
    func insertWithUndo(at position: Int, attributedString: NSAttributedString) {
        #if os(macOS)
        textStorage?.insert(attributedString, at: position)
        undoManager?.registerUndo(withTarget: self, handler: { _ in
            self.textStorage?.deleteCharacters(in: NSRange(location: position, length: attributedString.length))
        })
        #elseif os(iOS)
        textStorage.insert(attributedString, at: position)
        undoManager?.registerUndo(withTarget: self, handler: { _ in
            self.textStorage.deleteCharacters(in: NSRange(location: position, length: attributedString.length))
        })
        #endif
    }
    
    func insertWithUndo(atIndex position: String.Index, attributedString: NSAttributedString) {
        insertWithUndo(at: string.distance(from: string.startIndex, to: position), attributedString: attributedString)
    }
    
    func insertWithUndo(at position: Int, string: String) {
        insertWithUndo(at: position, attributedString: NSAttributedString(string: string))
    }
    
    func insertWithUndo(atIndex position: String.Index, string: String) {
        insertWithUndo(atIndex: position, attributedString: NSAttributedString(string: string))
    }
}

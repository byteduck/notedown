//
//  TextView+Extensions.swift
//  Notedown
//
//  Created by Aaron on 4/18/23.
//

import Foundation

extension NDPlatformTextView {
    func replaceWithUndo(in range: NSRange, with string: String) {
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
        #endif
    }
}

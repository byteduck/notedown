//
//  NDSyntaxCompletion.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

import Foundation

func performSyntaxCompletion(textView: NDPlatformTextView, inRange range: NSRange, replacementString: String?) -> Bool {
    let viewString = textView.string
    
    guard
        let replacementString = replacementString,
        let stringRange = Range(range, in: viewString)
    else { return true }
    
    let lineRange = viewString.lineRange(for: stringRange)
    let lineString = viewString[lineRange]
    
    #if os(macOS)
    textView.textStorage?.beginEditing()
    defer { textView.textStorage?.endEditing() }
    #elseif os(iOS)
    textView.textStorage.beginEditing()
    defer { textView.textStorage.endEditing() }
    #endif
    
    for processor in markdownProcessors {
        if !processor(textView, range, replacementString, lineRange, lineString) {
            return false
        }
    }
    
    return true
}

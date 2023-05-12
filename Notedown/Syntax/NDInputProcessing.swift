//
//  NDInputProcessing.swift
//  Notedown
//
//  Created by Aaron on 4/18/23.
//

import Foundation

typealias NDInputProcessor = (_ textView: NDPlatformTextView, _ replacementRange: NSRange, _ replacementString: String, _ lineRange: Range<String.Index>, _ lineString: Substring) -> Bool

let markdownProcessors: [NDInputProcessor] = [
    processUnorderedList,
    processOrderedList,
    processListIndentation
]

/// Unordered list completion
let processUnorderedList: NDInputProcessor = { textView, replacementRange, replacementString, lineRange, lineString in
    guard
        replacementString == "\n",
        let listMatch = lineString.firstMatch(of: Regex(NDSyntaxRegex.unorderedList)),
        let bulletRange = listMatch[2].range
    else { return true }
        
    let bullet = lineString[bulletRange]
    var indentation = ""
    let restOfLine = lineString.replacingCharacters(in: bulletRange, with: "")
    let indentationRange = lineString.firstMatch(of: NDSyntaxRegex.whitespace)?.range
    if let indentationRange = indentationRange, indentationRange.lowerBound < bulletRange.lowerBound {
        indentation = String(lineString[indentationRange])
        
        // If the line is just an indented bullet with nothing after it, just decrease the indentation
        if restOfLine.firstIndex(where: { !$0.isWhitespace }) == nil {
            textView.replaceWithUndo(in: NSRange(lineRange.lowerBound...lineRange.lowerBound, in: textView.string), with: "")
            #if os(iOS)
            textView.selectedRange = NSRange(location: textView.selectedRange.location - 1, length: 0)
            #endif
            return false
        }
    }
    
    // If the line is just a bullet with nothing else, then we should remove the bullet
    if restOfLine.firstIndex(where: { !$0.isWhitespace }) == nil {
        textView.replaceWithUndo(in: NSRange(lineRange, in: textView.string), with: "", moveCursor: true)
        return false
    }
    
    textView.replaceWithUndo(in: replacementRange, with: "\n\(indentation)\(bullet) ", moveCursor: true)
    
    return false
}

/// Ordered list completion
let processOrderedList: NDInputProcessor = { textView, replacementRange, replacementString, lineRange, lineString in
    guard
        replacementString == "\n",
        let listMatch = lineString.firstMatch(of: Regex(NDSyntaxRegex.orderedList)),
        let numberRange = listMatch[1].range,
        let number = Int(lineString[numberRange])
    else { return true }
    
    var indentation = ""
    if let indentationRange = lineString.firstMatch(of: NDSyntaxRegex.whitespace)?.range {
        indentation = String(lineString[indentationRange])
    }
    
    textView.replaceWithUndo(in: replacementRange, with: "\n\(indentation)\(number + 1). ", moveCursor: true)
    
    return false
}

/// List indentation (tab) completion
let processListIndentation: NDInputProcessor = { textView, replacementRange, replacementString, lineRange, lineString in
    guard
        replacementString == "\t" &&
        (lineString.starts(with: NDSyntaxRegex.orderedList) || lineString.starts(with: NDSyntaxRegex.unorderedList))
    else { return true }
    
    textView.insertWithUndo(atIndex: lineRange.lowerBound, string: "\t")
    return false
}

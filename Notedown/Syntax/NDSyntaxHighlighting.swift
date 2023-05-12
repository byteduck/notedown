//
//  NDSyntaxHighlighting.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

func applyHighlighting(inRange paragraphRange: NSRange, withStorage textStorage: NSTextStorage, configuration: NDMarkdownEditorConfiguration, document: NDDocument?) {
    if paragraphRange.length == 0 {
        return
    }
    
    textStorage.setAttributes([
        .font: configuration.defaultFont,
        .foregroundColor: configuration.defaultColor
    ], range: paragraphRange)
    let string = textStorage.attributedSubstring(from: paragraphRange).string
    
    markdownSyntaxRules.forEach({ rule in
        // TODO: Cache rule attributes so we don't have to calculate them on the fly every time
        let ruleAttributes = rule.attributes(configuration)
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
                action(document, textStorage, paragraphRange, string, match)
            }
        })
    })
}

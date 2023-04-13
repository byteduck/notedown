//
//  NDMarkdownEditor+Syntax.swift
//  Notedown
//
//  Created by Aaron on 4/10/23.
//

import AppKit

struct NDSyntaxHighlightRule {
    /// The `Regex` to match for this syntax highlighting rule.
    let regex: Regex<AnyRegexOutput>
    /// An array of `NSAttributedString` style dictionaries corresponding to capture groups in the regular expression
    let styles: [[NSAttributedString.Key : Any]?]
}

struct NDSyntaxRegex {
    static let link = try! Regex("!?\\[([^\\[\\]]*)\\]\\((.*?)\\)")
    static let unorderedList = try! Regex("^\\s*(\\-|\\*|\\+)\\s").anchorsMatchLineEndings(true)
    static let orderedList = try! Regex("^\\s*(\\d*)\\.\\s").anchorsMatchLineEndings(true)
    static let latex = try! Regex("\\$(?:[^\\\\\\$\\n]|\\\\.)*\\$").repetitionBehavior(.reluctant)
    static let header = try! Regex("^#{1,\(maxHeadingLevel)}\\s.*$").anchorsMatchLineEndings(true)
    static let whitespace = try! Regex("\\s*")
    static let maxHeadingLevel = 6
}

let markdownSyntaxRules: [NDSyntaxHighlightRule] = {
    var rules: [NDSyntaxHighlightRule] = [
        /// Links / images
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.link,
            styles: [
                [.foregroundColor: NSColor.secondaryLabelColor],
                [.foregroundColor: NSColor.linkColor],
                [.foregroundColor: NSColor.linkColor, .underlineStyle: NSUnderlineStyle.single.rawValue]
            ]
        ),
        /// Bulleted lists
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.unorderedList,
            styles: [[.foregroundColor: NSColor.secondaryLabelColor]]
        ),
        /// Numbered lists
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.orderedList,
            styles: [[.foregroundColor: NSColor.secondaryLabelColor]]
        ),
        /// LaTeX
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.latex,
            styles: [[.foregroundColor: NSColor.systemGreen]]
        )
    ]
    
    // Editor rules for markdown headers
    for level in 1...NDSyntaxRegex.maxHeadingLevel {
        rules.append(NDSyntaxHighlightRule(
            regex: try! Regex("^#{\(level)}\\s.*$").anchorsMatchLineEndings(true),
            styles: [[
                .foregroundColor: NSColor.systemBlue,
                .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize + CGFloat((2 * NDSyntaxRegex.maxHeadingLevel - 2 * level)), weight: .bold)
            ]]
        ))
    }
    
    return rules
}()

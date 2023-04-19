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
    static let latex = try! Regex("(\\$)((?:[^\\\\\\$\\n]|\\\\.){1,})(\\$)").repetitionBehavior(.reluctant)
    static let header = try! Regex("^(#{1,\(maxHeadingLevel)}\\s).*$").anchorsMatchLineEndings(true)
    static let bold = try! Regex("(\\*\\*)((?:[^\\*\\n]){1,})(\\*\\*)").repetitionBehavior(.reluctant)
    static let italic = try! Regex("(\\*)((?:[^\\*\\n]){1,})(\\*)").repetitionBehavior(.reluctant)
    static let codeBlock = try! Regex("(```)((?:[^`]|\\n.){1,})(```)").repetitionBehavior(.reluctant)
    static let whitespace = try! Regex("\\s*")
    static let maxHeadingLevel = 6
}

let italicFont = {
    let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
    return font
}()

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
            styles: [
                [:],
                [.font: NSFont.monospacedSystemFont(ofSize: 0.001, weight: .regular)],
                [
                    .font: NSFont(name: "Times New Roman", size: NSFont.systemFontSize)!,
                    .foregroundColor: NSColor.systemGreen
                ],
                [.font: NSFont.monospacedSystemFont(ofSize: 0.001, weight: .regular)]
            ]
        ),
        /// Bold
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.bold,
            styles: [
                [:],
                [.font: NSFont.monospacedSystemFont(ofSize: 0.001, weight: .bold)],
                [
                    .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .bold),
                    .foregroundColor: NSColor.systemRed
                ],
                [.font: NSFont.monospacedSystemFont(ofSize: 0.001, weight: .bold)]
            ]
        ),
        /// Code block
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.codeBlock,
            styles: [
                [:],
                [:],
                [.font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)],
                [:]
            ]
        )
        /// Italic
//        NDSyntaxHighlightRule(
//            regex: NDSyntaxRegex.italic,
//            styles: [
//                [:],
//                [.font: NSFont.monospacedSystemFont(ofSize: 0.001, weight: .regular)],
//                [.font: italicFont],
//                [.font: NSFont.monospacedSystemFont(ofSize: 0.001, weight: .regular)]
//            ]
//        ),
    ]
    
    // Editor rules for markdown headers
    for level in 1...NDSyntaxRegex.maxHeadingLevel {
        let fontSize = NSFont.systemFontSize + pow(1.6, Double(NDSyntaxRegex.maxHeadingLevel - level))
        rules.append(NDSyntaxHighlightRule(
            regex: try! Regex("^#{\(level)}\\s.*$").anchorsMatchLineEndings(true),
            styles: [[
                .foregroundColor: level == 1 ? NSColor.systemBlue : NSColor.systemCyan,
                .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: level == 1 ? .bold : .semibold)
            ]]
        ))
    }
    
    return rules
}()

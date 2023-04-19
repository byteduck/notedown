//
//  NDMarkdownEditor+Syntax.swift
//  Notedown
//
//  Created by Aaron on 4/10/23.
//

import AppKit

enum NDFontType {
    case regular
    case monospace
    case serif
}

enum NDSyntaxFormat {
    case color(NSColor)
    case font(NDFontType)
    case weight(NSFont.Weight)
    case italic
    case underlineStyle(NSUnderlineStyle)
    case size(CGFloat)
}

struct NDSyntaxHighlightRule {
    /// The `Regex` to match for this syntax highlighting rule.
    let regex: Regex<AnyRegexOutput>
    /// An array of `NSAttributedString` style dictionaries corresponding to capture groups in the regular expression
    let styles: [[NDSyntaxFormat]]
    
    // This initializer simply serves to type-erase the output parameter of the regex
    init<Output>(regex: Regex<Output>, styles: [[NDSyntaxFormat]]) {
        self.regex = Regex(regex)
        self.styles = styles
    }
    
    /// Creates an NSAttributedString attribute dictionary using the styles and given configuration.
    func attributes(_ config: NDMarkdownEditorConfiguration) -> [[NSAttributedString.Key : Any]] {
        return styles.map { $0.reduce(into: [NSAttributedString.Key : Any](), { map, style in
            map.addAttribute(style, config: config)
        })}
    }
}

extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    mutating func addAttribute(_ style: NDSyntaxFormat, config: NDMarkdownEditorConfiguration) {
        switch(style) {
        case .color(let color):
            self[.foregroundColor] = color
        case .size(let size):
            self[.font] = font(config).withSize(size)
        case .weight(let weight):
            let oldFont = font(config)
            let oldTraits = NSFontManager.shared.traits(of: oldFont)
            guard let fontFamily = oldFont.familyName else {
                break
            }
            self[.font] = NSFontManager.shared.font(withFamily: fontFamily, traits: oldTraits, weight: weight.intWeight, size: oldFont.pointSize)
        case .italic:
            self[.font] = NSFontManager.shared.convert(font(config), toHaveTrait: .italicFontMask)
        case .underlineStyle(let underlineStyle):
            self[.underlineStyle] = underlineStyle
        case .font(let style):
            let oldFont = font(config)
            let oldWeight = NSFontManager.shared.weight(of: oldFont)
            let oldTraits = NSFontManager.shared.traits(of: oldFont)
            let newFont: NSFont
            switch(style) {
            case .regular:
                newFont = config.defaultFont
            case .monospace:
                newFont = config.defaultMonospaceFont
            case .serif:
                newFont = config.defaultSerifFont
            }
            guard let newFontFamily = newFont.familyName else {
                break
            }
            self[.font] = NSFontManager.shared.font(withFamily: newFontFamily, traits: oldTraits, weight: oldWeight, size: oldFont.pointSize)
        }
    }
    
    private func font(_ config: NDMarkdownEditorConfiguration) -> NSFont {
        self[.font] as? NSFont ?? config.defaultFont
    }
}

extension NSFont.Weight {
    // The float representation ranges from -1.0 to 1.0, where 0.0 is regular.
    // The int representation that NSFontManager expects ranges from 0 to 15, where 5 is regular.
    var intWeight: Int {
        if rawValue < 0 {
            return Int(5.0 + (rawValue * 5.0))
        } else {
            return Int(rawValue * 10.0 + 5.0)
        }
    }
}

struct NDSyntaxRegex {
    static let link = /!?\[([^\[\]]*)\]\((.*?)\)/
    static let unorderedList = /^\s*(\-|\*|\+)\s/.anchorsMatchLineEndings(true)
    static let orderedList = /^\s*(\d*)\.\s/.anchorsMatchLineEndings(true)
    static let latex = /(\$)((?:[^\\\$\n]|\\.){1,})(\$)/.repetitionBehavior(.reluctant)
    static let header = try! Regex("^(#{1,\(maxHeadingLevel)}\\s).*$").anchorsMatchLineEndings(true)
    static let bold = /(\*\*)((?:[^\*\n]){1,})(\*\*)/.repetitionBehavior(.reluctant)
    static let italic = /(\*)((?:[^\*\n]){1,})(\*)/.repetitionBehavior(.reluctant)
    static let codeBlock = /(```)((?:[^`]|\n.){1,})(```)/.repetitionBehavior(.reluctant)
    static let whitespace = /\s*/
    static let htmlTag = /<[a-zA-Z]+(\s+[a-zA-Z]+\s*=\s*("([^"]*)"|'([^'])'))*\s*\/>/
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
                [.color(.secondaryLabelColor)],
                [.color(.linkColor)],
                [.color(.linkColor), .underlineStyle(.single)]
            ]
        ),
        /// Bulleted lists
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.unorderedList,
            styles: [[.color(.secondaryLabelColor)]]
        ),
        /// Numbered lists
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.orderedList,
            styles: [[.color(.secondaryLabelColor)]]
        ),
        /// LaTeX
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.latex,
            styles: [
                [],
                [.size(0.001)],
                [.font(.serif), .color(.systemGreen)],
                [.size(0.001)]
            ]
        ),
        /// Bold
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.bold,
            styles: [
                [],
                [.size(0.001)],
                [.font(.monospace), .weight(.bold), .color(.systemRed)],
                [.size(0.001)]
            ]
        ),
        /// Code block
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.codeBlock,
            styles: [
                [],
                [],
                [.font(.monospace)],
                []
            ]
        ),
        /// HTML tag
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.htmlTag,
            styles: [
                [.font(.monospace), .color(.systemTeal)],
                [.color(.systemMint)],
                [.color(.systemRed)]
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
                .size(fontSize),
                .color(level == 1 ? .systemBlue : .systemCyan),
                .weight(level == 1 ? .bold : .semibold)
            ]]
        ))
    }
    
    return rules
}()

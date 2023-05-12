//
//  NDSyntaxHighlightRule.swift
//  Notedown
//
//  Created by Aaron on 4/10/23.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum NDFontType {
    case regular
    case monospace
    case serif
}

enum NDSyntaxFormat {
    case color(NDColor)
    case font(NDFontType)
    case weight(NDFont.Weight)
    case italic
    case underlineStyle(NSUnderlineStyle)
    case size(CGFloat)
    case background(NDColor)
    case paragraphStyle(NSParagraphStyle)
}

struct NDSyntaxHighlightRule {
    typealias SyntaxHighlightAction = (NDDocument?, NSTextStorage, NSRange, String, Regex<AnyRegexOutput>.Match) -> Void
    
    /// The `Regex` to match for this syntax highlighting rule.
    let regex: Regex<AnyRegexOutput>
    /// An array of `NSAttributedString` style dictionaries corresponding to capture groups in the regular expression
    let styles: [[NDSyntaxFormat]]
    /// An optional special action to perform when evaluating the rule
    let action: SyntaxHighlightAction?
    
    // This initializer simply serves to type-erase the output parameter of the regex
    init<Output>(regex: Regex<Output>, styles: [[NDSyntaxFormat]], action: SyntaxHighlightAction? = nil) {
        self.regex = Regex(regex)
        self.styles = styles
        self.action = action
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
        case .background(let color):
            self[.backgroundColor] = color
        case .size(let size):
            self[.font] = font(config).withSize(size)
        case .weight(let weight):
            let oldFont = font(config)
            
            #if os(macOS)
            let oldTraits = NSFontManager.shared.traits(of: oldFont)
            guard let fontFamily = oldFont.familyName else {
                break
            }
            self[.font] = NSFontManager.shared.font(withFamily: fontFamily, traits: oldTraits, weight: weight.intWeight, size: oldFont.pointSize)
            
            #elseif os(iOS)
            var traits = oldFont.traits
            traits[.weight] = weight.intWeight
            let descriptor = oldFont.fontDescriptor.addingAttributes([.traits: traits])
            self[.font] = UIFont(descriptor: descriptor, size: oldFont.pointSize)
            
            #endif
        case .italic:
            #if os(macOS)
            self[.font] = NSFontManager.shared.convert(font(config), toHaveTrait: .italicFontMask)
            
            #elseif os(iOS)
            let oldFont = font(config)
            let descriptor = oldFont.fontDescriptor.withSymbolicTraits([.traitItalic]) ?? oldFont.fontDescriptor
            self[.font] = UIFont(descriptor: descriptor, size: oldFont.pointSize)
            
            #endif
        case .underlineStyle(let underlineStyle):
            self[.underlineStyle] = underlineStyle
        case .font(let style):
            let oldFont = font(config)
            let newFont: NDFont
            switch(style) {
            case .regular:
                newFont = config.defaultFont
            case .monospace:
                newFont = config.defaultMonospaceFont
            case .serif:
                newFont = config.defaultSerifFont
            }
            
            #if os(macOS)
            guard let newFontFamily = newFont.familyName else {
                break
            }
            let oldWeight = NSFontManager.shared.weight(of: oldFont)
            let oldTraits = NSFontManager.shared.traits(of: oldFont)
            self[.font] = NSFontManager.shared.font(withFamily: newFontFamily, traits: oldTraits, weight: oldWeight, size: oldFont.pointSize)
            
            #elseif os(iOS)
            let oldTraits = oldFont.traits
            let descriptor = UIFontDescriptor(fontAttributes: [
                .family: newFont.familyName,
                .traits: oldTraits
            ])
            self[.font] = UIFont(descriptor: descriptor, size: oldFont.pointSize)
            
            #endif
        case .paragraphStyle(let paragraphStyle):
            self[.paragraphStyle] = paragraphStyle
        }
    }
    
    private func font(_ config: NDMarkdownEditorConfiguration) -> NDFont {
        self[.font] as? NDFont ?? config.defaultFont
    }
}

extension NDFont.Weight {
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
    static let unorderedList = /(^\s*(\-|\*|\+)\s)([^\n]*)/.anchorsMatchLineEndings(true)
    static let orderedList = /^\s*(\d*)\.\s/.anchorsMatchLineEndings(true)
    static let latex = /(\$)((?:[^\\\$\n]|\\.){1,})(\$)/.repetitionBehavior(.reluctant)
    static let header = try! Regex("^(#{1,\(maxHeadingLevel)}\\s*).{1,}$").anchorsMatchLineEndings(true)
    static let bold = /(\*\*)((?:[^\*\n]){1,})(\*\*)/.repetitionBehavior(.reluctant)
    static let italic = /(\*)((?:[^\*\n]){1,})(\*)/.repetitionBehavior(.reluctant)
    static let codeBlock = /(```)((?:[^`]|\n.){1,})(```)/.repetitionBehavior(.reluctant)
    static let whitespace = /\s*/
    static let htmlTag = /<([a-zA-Z]+)(\s+[a-zA-Z]+\s*=\s*("([^"]*)"|'([^'])'))*\s*\/>/
    static let inlineCode = /(\`)((?:[^\\\`\n]|\\.){1,})(\`)/.repetitionBehavior(.reluctant)
    static let maxHeadingLevel = 6
    static let headingColors: [NDColor] = [.systemBlue, .systemCyan, .textColor, .textColor, .textColor, .textColor]
    static let headingWeights: [NDFont.Weight] = [.heavy, .bold, .semibold, .semibold, .semibold, .semibold]
    static let headingUnderlines: [NSUnderlineStyle] = [[], [], .single, .single, .single, .single]
}

let headingParagraphStyle = {
    let style = NSMutableParagraphStyle()
    style.paragraphSpacing = 5.0
    style.paragraphSpacingBefore = 10.0
    return style
}()

let codeBlockTicksParagraphStyle = {
    let style = NSMutableParagraphStyle()
    style.paragraphSpacingBefore = 5.0
    style.paragraphSpacing = 5.0
    return style
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
            styles: [
                [],
                [],
                [.color(.secondaryLabelColor), .weight(.heavy)],
                []
            ],
            action: { document, storage, paragraphRange, paragraphString, match in
                // Set paragraph indent to match up with bullet indentation and whitespace
                let storageString = storage.string
                let bulletString = storage.attributedSubstring(from: match[1].range!.relativeTo(paragraphRange, in: paragraphString))
                let style = NSMutableParagraphStyle()
                style.headIndent = bulletString.size().width
                style.paragraphSpacing = 2.0
                storage.addAttributes([.paragraphStyle: style], range: match.range.relativeTo(paragraphRange, in: paragraphString))
            }
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
            ],
            action: { document, storage, paragraphRange, paragraphString, match in
                guard let latex = match[2].substring else { return }
                storage.addAttributes([
                    .link: NDTextLink.latex(String(latex))
                ], range: match[2].range!.relativeTo(paragraphRange, in: paragraphString))
            }
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
        /// Inline code
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.inlineCode,
            styles: [
                [.font(.monospace), .background(.systemRed.withAlphaComponent(0.1)), .color(.systemRed)],
                [.size(0.001)],
                [],
                [.size(0.001)]
            ]
        ),
        /// Code block
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.codeBlock,
            styles: [
                [],
                [.size(0.001), .paragraphStyle(codeBlockTicksParagraphStyle)],
                [.font(.monospace)],
                [.size(0.001), .paragraphStyle(codeBlockTicksParagraphStyle)]
            ]
        ),
        /// HTML tag
        NDSyntaxHighlightRule(
            regex: NDSyntaxRegex.htmlTag,
            styles: [
                [.font(.monospace), .color(.systemTeal)],
                [.color(.systemMint)],
                [.color(.systemRed)]
            ],
            action: { document, storage, paragraphRange, paragraphString, match in
                guard
                    let tagName = match[1].substring,
                    tagName.uppercased() == "IMG",
                    let imageName = match[4].substring
                else {
                    return
                }
                
                let imageRange = match[3].range!.relativeTo(paragraphRange, in: paragraphString)
                storage.addAttributes([
                    .link: NDTextLink.image(String(imageName)),
                    .foregroundColor: NDColor.systemRed
                ], range: imageRange)
            }
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
        let fontSize = NDFont.systemFontSize + pow(1.8, Double(NDSyntaxRegex.maxHeadingLevel - level))
        rules.append(NDSyntaxHighlightRule(
            regex: try! Regex("^(#{\(level)}\\s{1,})[^\\s].*$").anchorsMatchLineEndings(true),
            styles: [
                [
                    .size(fontSize),
                    .color(NDSyntaxRegex.headingColors[level - 1]),
                    .weight(NDSyntaxRegex.headingWeights[level - 1]),
                    .font(.monospace),
                    .underlineStyle(NDSyntaxRegex.headingUnderlines[level - 1]),
                    .paragraphStyle(headingParagraphStyle)
                ],
                [
                    .size(0.001)
                ]
            ]
        ))
    }
    
    return rules
}()

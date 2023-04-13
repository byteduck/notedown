//
//  NDSyntaxHighlight.swift
//  Notedown
//
//  Created by Aaron on 4/10/23.
//

import Foundation

struct NDSyntaxHighlightRule {
    /// The `Regex` to match for this syntax highlighting rule.
    let regex: Regex<AnyRegexOutput>
    /// An array of `NSAttributedString` style dictionaries corresponding to capture groups in the regular expression
    let styles: [[NSAttributedString.Key : Any]?]
}

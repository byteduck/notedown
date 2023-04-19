//
//  NDMarkdownEditorConfiguration.swift
//  Notedown
//
//  Created by Aaron on 4/11/23.
//

import AppKit

struct NDMarkdownEditorConfiguration {
    var defaultFont: NSFont = .systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    var defaultMonospaceFont: NSFont = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    var defaultSerifFont: NSFont = .init(name: "Times New Roman", size: NSFont.systemFontSize) ?? .systemFont(ofSize: NSFont.systemFontSize)
    var defaultColor: NSColor = .textColor
}

//
//  NDMarkdownEditorConfiguration.swift
//  Notedown
//
//  Created by Aaron on 4/11/23.
//

struct NDMarkdownEditorConfiguration {
    var defaultFont: NDFont = .systemFont(ofSize: NDFont.systemFontSize, weight: .regular)
    var defaultMonospaceFont: NDFont = .monospacedSystemFont(ofSize: NDFont.systemFontSize, weight: .regular)
    var defaultSerifFont: NDFont = .init(name: "Times New Roman", size: NDFont.systemFontSize) ?? .systemFont(ofSize: NDFont.systemFontSize)
    var defaultColor: NDColor = .textColor
}

//
//  NDColorCompat.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

/// This adds some of the `NSColor`-specific colors to `UIColor` for easier compatibility.

#if os(iOS)

import UIKit

extension UIColor {
    static let textColor = UIColor.label
    static let secondaryLabelColor = UIColor.secondaryLabel
    static let linkColor = UIColor.link
}

#endif

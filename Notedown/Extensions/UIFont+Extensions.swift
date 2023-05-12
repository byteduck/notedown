//
//  UIFont+Extensions.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

#if os(iOS)

import UIKit

extension UIFont {
    var traits: [UIFontDescriptor.TraitKey: Any] {
        return fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
            ?? [:]
    }
}

#endif

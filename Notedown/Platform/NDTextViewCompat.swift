//
//  NDTextViewCompat.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//


#if os(iOS)
import UIKit

extension UITextView {
    var string: String {
        get { self.text }
        set { self.text = newValue }
    }
}
#endif

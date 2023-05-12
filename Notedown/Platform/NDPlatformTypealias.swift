//
//  NDPlatformSpecifics.swift
//  Notedown
//
//  Created by Aaron on 5/11/23.
//

#if os(macOS)

import AppKit

typealias NDFont = NSFont
typealias NDColor = NSColor
typealias NDPlatformTextView = NSTextView
typealias NDPlatformImage = NSImage

#elseif os(iOS)

import UIKit

typealias NDFont = UIFont
typealias NDColor = UIColor
typealias NDPlatformTextView = UITextView
typealias NDPlatformImage = UIImage

#endif

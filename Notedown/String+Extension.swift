//
//  String+Extension.swift
//  Notedown
//
//  Created by Aaron on 4/12/23.
//

import Foundation

extension NSMutableString {
    func lineRange(atPosition position: Int) -> NSRange {
        if self.length == 0 {
            return NSRange(location: 0, length: 0)
        }
        var lineStartRange = self.range(of: "\n", options: .backwards, range: NSRange(0..<position))
        if lineStartRange.location == NSNotFound {
            lineStartRange = NSRange(0...0)
        } else {
            lineStartRange.location += 1
        }
        var lineEndRange = self.range(of: "\n", range: NSRange(position..<self.length))
        if lineEndRange.location == NSNotFound {
            lineEndRange = NSRange(location: self.length, length: 0)
        }
        return NSRange(lineStartRange.location..<lineEndRange.location)
    }
}

//
//  NSRange+Extensions.swift
//  Notedown
//
//  Created by Aaron on 4/27/23.
//

import Foundation

extension NSRange {
    func relativeTo(_ parentRange: NSRange) -> NSRange {
        return NSRange(location: self.lowerBound + parentRange.lowerBound, length: self.length)
    }
}

extension RangeExpression where Bound == String.Index {
    func relativeTo(_ parentRange: NSRange, in substring: any StringProtocol) -> NSRange {
        return NSRange(self, in: substring).relativeTo(parentRange)
    }
}

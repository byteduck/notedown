//
//  NDTextView+iOS.swift
//  Notedown
//
//  Created by Aaron on 5/12/23.
//

#if os(iOS)
import UIKit

class NDTextView: UITextView {
    func setup() {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure we pre-calculate the layout for the whole document so that scrolling is buttery smooth.
        if
            let layoutManager = textLayoutManager,
            let documentRange = layoutManager.textContentManager?.documentRange
        {
            layoutManager.ensureLayout(for: documentRange)
        }
    }
}

#endif

//
//  NDPopovers.swift
//  Notedown
//
//  Created by Aaron on 5/4/23.
//

import AppKit

class NDImagePopoverViewController: NSViewController {
    var image: NSImage?
    
    override func loadView() {
        if let image = image {
            let view = NSImageView(image: image)
            view.imageScaling = .scaleProportionallyUpOrDown
            self.view = view
        }
    }
}

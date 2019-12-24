//
//  FMCoverButton.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/11.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class FMCoverButton: NSButton {
    var coverTrackID = 0
    var index = -1 {
        didSet {
            if let c = cell as? FMCoverButtonCell {
                c.clickable = index == 1
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
    }
}

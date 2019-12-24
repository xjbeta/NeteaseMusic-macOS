//
//  FMCoverButtonCell.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/12/24.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class FMCoverButtonCell: NSButtonCell {
    var clickable = false
    
    override func highlight(_ flag: Bool, withFrame cellFrame: NSRect, in controlView: NSView) {
        if clickable {
            super.highlight(flag, withFrame: cellFrame, in: controlView)
        } else {
            return
        }
    }
}

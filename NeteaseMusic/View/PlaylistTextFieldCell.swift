//
//  PlaylistTextFieldCell.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/4.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PlaylistTextFieldCell: NSTextFieldCell {
    
    override func drawingRect(forBounds theRect: NSRect) -> NSRect {
        let newRect = NSRect(x: 0, y: (theRect.size.height - 17) / 2, width: theRect.size.width, height: 17)
        return super.drawingRect(forBounds: newRect)
    }
    
}

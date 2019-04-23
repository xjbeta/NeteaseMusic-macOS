//
//  CDBackgroundView.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/22.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class CDBackgroundView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let selectionRect = NSInsetRect(bounds, 0, 0)
        
        let selectionPath = NSBezierPath(roundedRect: selectionRect, xRadius: bounds.width / 2, yRadius: bounds.height / 2)
        NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.06).setFill()
        selectionPath.fill()
        
    }
    
}

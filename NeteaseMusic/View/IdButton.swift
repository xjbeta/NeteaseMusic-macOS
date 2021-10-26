//
//  IdButton.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/15.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class IdButton: NSButton {
    var id = -1
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        isBordered = false
        
    }
}

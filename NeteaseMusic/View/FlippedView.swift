//
//  FlippedView.swift
//  Netease Music
//
//  Created by xjbeta on 10/10/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Cocoa

class FlippedView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override var isFlipped: Bool {
        return true
    }
    
}

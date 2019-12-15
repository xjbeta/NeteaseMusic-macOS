//
//  UnresponsiveScrollView.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/7.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class UnresponsiveScrollView: NSScrollView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    var responsiveScrolling = true
    
    override func scrollWheel(with event: NSEvent) {
        if responsiveScrolling {
            super.scrollWheel(with: event)
        } else {
            self.nextResponder?.scrollWheel(with: event)
        }
    }
    
}

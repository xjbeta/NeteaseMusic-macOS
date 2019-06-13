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
    
    override func scrollWheel(with event: NSEvent) {
        self.nextResponder?.scrollWheel(with: event)
    }
    
}

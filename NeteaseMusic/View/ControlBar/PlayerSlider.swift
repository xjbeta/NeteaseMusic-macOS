//
//  PlayerSlider.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/14.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PlayerSlider: NSSlider {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    var cachedDoubleValue = 0.0
    var ignoreValueUpdate = false
    
    func updateValue(_ value: Double) {
        if !ignoreValueUpdate {
            doubleValue = value
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        ignoreValueUpdate = true
        super.mouseDown(with: event)
    }
}

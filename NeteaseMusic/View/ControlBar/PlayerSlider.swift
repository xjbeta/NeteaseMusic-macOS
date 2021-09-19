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
    
    var mouseResponse = false {
        didSet {
            updateMouse()
        }
    }
    
    var mouseIn = false {
        didSet {
            updateMouse()
        }
    }
    
    func updateMouse() {
        (cell as? PlayerSliderCell)?.mouseIn = mouseIn && mouseResponse
        needsDisplay = true
    }
    
    func updateValue(_ value: Double) {
        if !ignoreValueUpdate {
            doubleValue = value
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        guard mouseResponse else {
            doubleValue = 0
            return
        }
        
        ignoreValueUpdate = true
        super.mouseDown(with: event)
    }
}

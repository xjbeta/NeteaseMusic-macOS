//
//  PlayerSliderCell.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/11/26.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PlayerSliderCell: NSSliderCell {

    let barHeight: CGFloat = 4
    
    override func drawKnob(_ knobRect: NSRect) {
        let knobRadius: CGFloat = 1
        let path = NSBezierPath(roundedRect: knobRect,
                                xRadius: knobRadius, yRadius: knobRadius)
        path.lineWidth = 0.5
        
        let darkMode = NSApp.effectiveAppearance == NSAppearance(named: .darkAqua)
        
        (darkMode ? NSColor.black : NSColor.white).setFill()
        path.stroke()
        
        (darkMode ? NSColor.white : NSColor.black).setFill()
        path.fill()
    }
    
    override func knobRect(flipped: Bool) -> NSRect {
        let slider = self.controlView as! PlayerSlider
        let playedPer = CGFloat(slider.doubleValue / (slider.maxValue - slider.minValue))
        
        let knobSize = NSSize(width: 4, height: 13)
        
        let barRect = self.barRect(flipped: false)
        let knobOriginX = barRect.width * playedPer
        let knobOriginY = barRect.origin.y + (barRect.height / 2) - (knobSize.height / 2)
        let knobOrigin = NSPoint(x: knobOriginX, y: knobOriginY)
        let knobRect = NSRect(origin: knobOrigin, size: knobSize)
        
        return knobRect
    }
    
    
    override func barRect(flipped: Bool) -> NSRect {
        var rect = super.barRect(flipped: flipped)
        rect.size.height = barHeight
        return rect
    }
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let slider = self.controlView as! PlayerSlider
        let barRadius = barHeight / 2
        let r = rect
        
        let playedPer = CGFloat(slider.doubleValue / (slider.maxValue - slider.minValue))
        let cachedPer = CGFloat(slider.cachedDoubleValue / (slider.maxValue - slider.minValue))

        let path = NSBezierPath(roundedRect: r, xRadius: barRadius, yRadius: barRadius)
        
        var gradient: NSGradient?
        if cachedPer >= playedPer {
            gradient = NSGradient(colorsAndLocations:
                (.quaternaryLabelColor, 0.0),
                (.quaternaryLabelColor, 1 - cachedPer),
                (.tertiaryLabelColor, 1 - cachedPer),
                (.tertiaryLabelColor, 1 - playedPer),
                (.secondaryLabelColor, 1 - playedPer),
                (.secondaryLabelColor, 1.0))
        } else {
            gradient = NSGradient(colorsAndLocations:
                (.quaternaryLabelColor, 0.0),
                (.quaternaryLabelColor, 1 - playedPer),
                (.secondaryLabelColor, 1 - playedPer),
                (.secondaryLabelColor, 1.0))
        }
        gradient?.draw(in: path, angle: 180)
    }
}

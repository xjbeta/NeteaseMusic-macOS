//
//  VolumeSliderCell.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/11/27.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class VolumeSliderCell: NSSliderCell {

    let barHeight: CGFloat = 4
    let knobSize = NSSize(width: 11, height: 11)
    
    override func drawKnob(_ knobRect: NSRect) {
        let path = NSBezierPath(ovalIn: knobRect)
        let darkMode = NSApp.effectiveAppearance == NSAppearance(named: .darkAqua)
        
        (darkMode ? NSColor.nColor : NSColor.nColor).setFill()
        path.fill()
    }
    
    override func knobRect(flipped: Bool) -> NSRect {
        let slider = self.controlView as! NSSlider
        let valuePer = CGFloat(slider.doubleValue / (slider.maxValue - slider.minValue))
        
        let barRect = self.barRect(flipped: false)
        
        let knobOriginX = barRect.origin.x + barRect.width * valuePer - knobSize.width / 2
        let knobOriginY = barRect.origin.y + (barRect.height / 2) - (knobSize.height / 2)
        let knobOrigin = NSPoint(x: knobOriginX, y: knobOriginY)
        let knobRect = NSRect(origin: knobOrigin, size: knobSize)
        return knobRect
    }
    
    
    override func barRect(flipped: Bool) -> NSRect {
        var rect = super.barRect(flipped: flipped)
        rect.origin.x += knobSize.width / 2
        rect.size.width -= knobSize.width
        rect.size.height = barHeight
        return rect
    }
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let color1 = NSColor.nColor
        guard let slider = self.controlView as? NSSlider,
              let color3 = NSColor(named: .init("PlaySliderBackgroundColor"))
        else {
            return
        }
        
        let barRadius = barHeight / 2
        let r = rect
        
        let valuePer = CGFloat(slider.doubleValue / (slider.maxValue - slider.minValue))
        let path = NSBezierPath(roundedRect: r, xRadius: barRadius, yRadius: barRadius)
        let gradient = NSGradient(colorsAndLocations:
            (color3, 0.0),
            (color3, 1 - valuePer),
            (color1, 1 - valuePer),
            (color1, 1.0))
        gradient?.draw(in: path, angle: 180)
    }
}

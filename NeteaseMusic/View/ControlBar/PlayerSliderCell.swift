//
//  PlayerSliderCell.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/11/26.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PlayerSliderCell: NSSliderCell {

    var mouseIn = false
    
    let barHeight: CGFloat = 4
    
    var isDarkMode: Bool {
        get {
            [.darkAqua,
             .vibrantDark,
             .accessibilityHighContrastDarkAqua,
             .accessibilityHighContrastVibrantDark]
                .contains(NSApp.effectiveAppearance.name)
        }
    }
    
    override func drawKnob(_ knobRect: NSRect) {
        guard mouseIn else { return }
        
        let knobRadius: CGFloat = knobRect.width / 2
        let path = NSBezierPath(roundedRect: knobRect,
                                xRadius: knobRadius,
                                yRadius: knobRadius)

        NSColor.nColor.setFill()
        path.fill()
    }
    

    override func knobRect(flipped: Bool) -> NSRect {
        guard let slider = self.controlView as? PlayerSlider,
              mouseIn else { return .zero }
        let playedPer = CGFloat(slider.doubleValue / (slider.maxValue - slider.minValue))

        let knobSize = NSSize(width: 13, height: 13)

        var barRect = self.barRect(flipped: false)
        barRect.size.width -= knobSize.width

        let knobOriginX = barRect.origin.x + barRect.width * playedPer
        
        let knobOriginY = barRect.origin.y + (barRect.height / 2) - (knobSize.height / 2)
        let knobOrigin = NSPoint(x: knobOriginX, y: knobOriginY)
        let knobRect = NSRect(origin: knobOrigin, size: knobSize)

        return knobRect
    }
    
    
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let color1 = NSColor.nColor
        
        guard let slider = self.controlView as? PlayerSlider,
              let color2 = NSColor(named: .init("PlaySliderCachedColor")),
              let color3 = NSColor(named: .init("PlaySliderBackgroundColor"))
        else { return }
//        let barRadius = 0
        
        let playedPer = CGFloat(slider.doubleValue / (slider.maxValue - slider.minValue))
        let cachedPer = CGFloat(slider.cachedDoubleValue / (slider.maxValue - slider.minValue))

        
        
//        let path = NSBezierPath(roundedRect: r, xRadius: barRadius, yRadius: barRadius)
        let path = NSBezierPath(rect: rect)

        var gradient: NSGradient?
        if cachedPer == 1 {
            gradient = NSGradient(colorsAndLocations:
                (color1, 0),
                (color1, playedPer),
                (color2, playedPer),
                (color2, 1))
        } else if cachedPer >= playedPer {
            gradient = NSGradient(colorsAndLocations:
                (color1, 0),
                (color1, playedPer),
                (color2, playedPer),
                (color2, cachedPer),
                (color3, cachedPer),
                (color3, 1))
        } else {
            gradient = NSGradient(colorsAndLocations:
                (color1, 0),
                (color1, playedPer),
                (color3, playedPer),
                (color3, 1))
        }
        gradient?.draw(in: path, angle: 0)
    }
}

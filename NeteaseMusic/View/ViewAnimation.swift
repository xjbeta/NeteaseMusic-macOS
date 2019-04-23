//
//  ViewAnimation.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/23.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

extension NSView {
    func rotate() {
        guard let layer = layer else { return }
        
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: frame.origin.x + frame.width / 2,
                                 y: frame.origin.y + frame.height / 2)
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.toValue = NSNumber(value: Double.pi * -2)
        rotation.duration = 100
        rotation.repeatCount = Float.greatestFiniteMagnitude
        layer.removeAllAnimations()
        layer.add(rotation, forKey: "rotationAnimation")
    }
    
    
    //    https://gist.github.com/nazywamsiepawel/e462193f299187d0fc8e#gistcomment-2891783
    
    func pauseAnimation() {
        guard let layer = layer else { return }
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = pausedTime
    }
    
    func resumeAnimation() {
        guard let layer = layer else { return }
        let pausedTime = layer.timeOffset
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
}

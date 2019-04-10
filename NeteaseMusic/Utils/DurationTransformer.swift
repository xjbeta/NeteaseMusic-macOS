//
//  VideoDurationFormatter.swift
//  iina+
//
//  Created by xjbeta on 2018/8/8.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa

@objc(DurationTransformer)
class DurationTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        let defaultStr = "00:00"
        
        if let dValue = (value as? Double) {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            let duration = Int(dValue / 1000)
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = .pad
            return formatter.string(from: TimeInterval(duration)) ?? defaultStr
        }
        return defaultStr
    }
}

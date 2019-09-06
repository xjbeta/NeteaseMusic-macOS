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
        if let v = value as? Double {
            return (v / 1000).durationFormatter()
        }
        return "00:00"
    }
}


extension Double {
    func durationFormatter() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(self)) ?? "00:00"
    }
}

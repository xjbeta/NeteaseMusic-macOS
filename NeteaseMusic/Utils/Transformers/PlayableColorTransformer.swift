//
//  PlayableColorTransformer.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2020/1/5.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

@objc(PlayableColorTransformer)
class PlayableColorTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let b = value as? Bool else {
            return NSColor.labelColor
        }
        
        return b ? NSColor.labelColor : NSColor.tertiaryLabelColor
    }
}

@objc(PlayableSecondaryColorTransformer)
class PlayableSecondaryColorTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let b = value as? Bool else {
            return NSColor.secondaryLabelColor
        }
        
        return b ? NSColor.secondaryLabelColor : NSColor.quaternaryLabelColor
    }
}

//
//  TrackPlayStateTransformer.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2020/2/16.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

@objc(TrackPlayStateTransformer)
class TrackPlayStateTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let isPlaying = value as? Bool else {
            return nil
        }
        return NSImage(named: .init(isPlaying ? "playstate" : "playstate_pause"))
    }
}

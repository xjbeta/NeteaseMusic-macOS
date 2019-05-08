//
//  LyricOffsetTransformer.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/8.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

@objc(LyricOffsetTransformer)
class LyricOffsetTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard var offset = value as? Double else {
            return nil
        }
        
        offset /= 1000
        switch offset {
        case 0:
            return "0s"
        case _ where offset > 0:
            return "+\(offset)s"
        case _ where offset < 0:
            return "\(offset)s"
        default:
            return nil
        }
    }
}

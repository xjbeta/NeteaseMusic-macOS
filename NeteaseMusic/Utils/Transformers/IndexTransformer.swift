//
//  IndexTransformer.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/19.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

@objc(IndexTransformer)
class IndexTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard var index = value as? Int else {
            return nil
        }
        index += 1
        if index < 10 {
            return "0\(index)"
        }
        
        return index
    }
}

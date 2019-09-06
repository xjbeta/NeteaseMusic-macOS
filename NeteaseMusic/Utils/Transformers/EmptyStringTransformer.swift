//
//  EmptyStringTransformer.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/24.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

@objc(EmptyStringTransformer)
class EmptyStringTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let str = value as? String else {
            return true
        }
        
        return str.isEmpty
    }
}

//
//  PubilshTimeTransformer.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/24.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

@objc(PubilshTimeTransformer)
class PubilshTimeTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let time = value as? Int else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let str = formatter.string(from: .init(timeIntervalSince1970: .init(time / 1000)))
        
//        publish time: 9102-01-01
        return "publish time: \(str)"
    }
}

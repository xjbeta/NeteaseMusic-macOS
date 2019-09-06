//
//  AlbumSizeTransformer.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/24.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

@objc(AlbumSizeTransformer)
class AlbumSizeTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let v = value as? Int else {
            return nil
        }
        return "\(v) songs"
    }
}

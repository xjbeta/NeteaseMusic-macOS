//
//  SubscribeButton.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/12/15.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SubscribeButton: NSButton {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    var subscribed: Bool = false {
        didSet {
            title = subscribed ? "已收藏" : "收藏"
        }
    }
    
}

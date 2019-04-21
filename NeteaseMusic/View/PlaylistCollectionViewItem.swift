//
//  PlaylistCollectionViewItem.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/20.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PlaylistCollectionViewItem: NSCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 5
        imageView?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        imageView?.layer?.borderWidth = 0.5
        let todo = "Shader    play button"
    }
    
}

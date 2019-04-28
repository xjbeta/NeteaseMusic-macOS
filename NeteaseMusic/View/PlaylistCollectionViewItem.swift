//
//  PlaylistCollectionViewItem.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/20.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PlaylistCollectionViewItem: NSCollectionViewItem {
    @IBOutlet weak var recommendClickImageView: NSImageView!
    
    var isMouseInside = false {
        didSet {
            recommendClickImageView.isHidden = !isMouseInside
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 5
        imageView?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        imageView?.layer?.borderWidth = 0.5
        
        imageView?.addTrackingArea(.init(rect: imageView?.bounds ?? NSZeroRect,
                                         options: [.mouseEnteredAndExited, .activeInActiveApp, .mouseMoved],
                                         owner: self,
                                         userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        isMouseInside = true
    }
    
    override func mouseExited(with event: NSEvent) {
        isMouseInside = false
    }
    
    deinit {
        imageView?.trackingAreas.forEach {
            imageView?.removeTrackingArea($0)
        }
    }
    
}

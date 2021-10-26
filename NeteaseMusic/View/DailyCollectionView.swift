//
//  DailyCollectionView.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/17.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class DailyCollectionView: NSCollectionView {
    
    //https://stackoverflow.com/a/56727867
    
    var clickedIndex: Int?
    
    override func menu(for event: NSEvent) -> NSMenu? {
        clickedIndex = nil
        
        let point = convert(event.locationInWindow, from: nil)
        for index in 0..<numberOfItems(inSection: 0) {
            let frame = frameForItem(at: index)
            if NSMouseInRect(point, frame, isFlipped) {
                clickedIndex = index
                break
            }
        }
        
        return super.menu(for: event)
    }
}

//
//  SidebarTableCellView.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/8.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SidebarTableCellView: NSTableCellView {

    @IBOutlet weak var highlightColorView: NSView!
    
    var isSelected = false {
        didSet {
            updateSelection()
        }
    }
    
    func updateSelection() {
        highlightColorView.layer?.backgroundColor = isSelected ? NSColor.nColor.cgColor : .clear
//        text color
//        textField?.textColor = isSelected ? NSColor.nColor.cgColor : .controlTextColor
//        image color
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func becomeFirstResponder() -> Bool {
        return false
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
}

//
//  SidebarViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/5.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {
    @IBOutlet weak var outlineView: NSOutlineView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

extension SidebarViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        return ""
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        
        return ""
    }
}

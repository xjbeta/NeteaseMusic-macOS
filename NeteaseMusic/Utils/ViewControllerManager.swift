//
//  ViewControllerManager.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/16.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class ViewControllerManager: NSObject {
    static let shared = ViewControllerManager()
    
    private override init() {
    }
    
    @objc dynamic var selectedSidebarItem: SidebarViewController.SidebarItem? = nil
    
    var searchFieldString = ""
    
    var userId = -233
    
    func selectSidebarItem(_ itemType: SidebarViewController.ItemType,
                           _ id: Int = -1) {
        print(#function, "\(itemType)", "ID: \(id)")
        NotificationCenter.default.post(name: .selectSidebarItem, object: nil, userInfo: ["itemType": itemType, "id": id])
    }
    
    func copyToPasteboard(_ str: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([str as NSString])
    }
    
}

extension NSTableView {
    func selectedIndexs() -> IndexSet{
        if clickedRow != -1 {
            if selectedRowIndexes.contains(clickedRow) {
                return selectedRowIndexes
            } else {
                return IndexSet(integer: clickedRow)
            }
        } else {
            return selectedRowIndexes
        }
    }
}

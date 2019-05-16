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
    
    @objc dynamic var selectedSidebarItem: SidebarViewController.TableViewItem? = nil
    
}

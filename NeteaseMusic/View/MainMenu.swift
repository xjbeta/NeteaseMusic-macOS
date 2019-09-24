//
//  MainMenu.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/23.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    
    @IBAction func preferences(_ sender: NSMenuItem) {
        ViewControllerManager.shared.selectSidebarItem(.preferences)
    }
    
}

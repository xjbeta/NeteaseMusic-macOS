//
//  MainMenu.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/23.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSMenuItemValidation {
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var nextMenuItem: NSMenuItem!
    @IBOutlet weak var previousMenuItem: NSMenuItem!
    @IBOutlet weak var increaseVolumeMenuItem: NSMenuItem!
    @IBOutlet weak var decreaseVolumeMenuItem: NSMenuItem!
    @IBOutlet weak var likeMenuItem: NSMenuItem!
    
    let playCore = PlayCore.shared
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    @IBAction func preferences(_ sender: NSMenuItem) {
        ViewControllerManager.shared.selectSidebarItem(.preferences)
    }
    
    @IBAction func play(_ sender: Any) {
        print(#function)
        playCore.continuePlayOrPause()
    }
    
    @IBAction func next(_ sender: Any) {
        print(#function)
        playCore.nextSong()
    }
    
    @IBAction func previous(_ sender: Any) {
        print(#function)
        playCore.previousSong()
    }
    
    @IBAction func increaseVolume(_ sender: Any) {
        print(#function)
        playCore.increaseVolume()
    }
    
    @IBAction func decreaseVolume(_ sender: Any) {
        print(#function)
        playCore.decreaseVolume()
    }
    
    @IBAction func like(_ sender: Any) {
        print(#function)
    }
}

//
//  AppDelegate.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/28.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var mainMenu: MainMenu!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        
        
        ViewControllerManager.shared.initAllHotKeys()
        
        PlayCore.shared.setupSystemMediaKeys()
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        let playCore = PlayCore.shared
        let fmPlaylist = playCore.fmPlaylist.map {
            $0.id
        }
        let currentFMId = playCore.currentFMTrack?.id
        Preferences.shared.fmPlaylist = (currentFMId, fmPlaylist)
        
    }


}


//
//  AppDelegate.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/28.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import Kingfisher
import GSPlayer

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var mainMenu: MainMenu!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        ViewControllerManager.shared.initAllHotKeys()
        
        PlayCore.shared.setupSystemMediaKeys()
        
        initCache()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        ViewControllerManager.shared.saveFMPlaylist()
    }

    func initCache() {
        // Music cache
        print("Music Cache Path", VideoCacheManager.directory)
        
        
        // Image cache
        ImageCache.default.cleanExpiredCache()
        print("Image Cache Path", ImageCache.default.diskStorage.directoryURL.path)
    }

}


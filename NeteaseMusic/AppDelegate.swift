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
import WebKit
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var mainMenu: MainMenu!
    let pc = PlayCore.shared
    let vcm = ViewControllerManager.shared
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        Log.setUp()
        
        
        
        
        vcm.initAllHotKeys()
        
        pc.setupSystemMediaKeys()
        pc.api.startNRMListening()
        
        initCache()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        vcm.saveFMPlaylist()
        pc.api.stopNRMListening()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                if window.windowController is MainWindowController {
                    window.makeKeyAndOrderFront(self)
                }
            }
        }
        return true
    }

    func initCache() {
        // Music cache
        Log.info("Music Cache Path: \(VideoCacheManager.directory)")
        let vcm = ViewControllerManager.shared
        vcm.cleanMusicCache()
        
        
        // Image cache
        ImageCache.default.cleanExpiredCache()
        Log.info("Image Cache Path: \(ImageCache.default.diskStorage.directoryURL.path)")
    }


    
    @IBAction func checkForUpdate(_ sender: NSMenuItem) {
        SUUpdater().checkForUpdates(sender)
    }
}


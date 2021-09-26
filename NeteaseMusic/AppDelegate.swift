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
        Log.initLog()
        
        
        vcm.initAllHotKeys()
        
        pc.setupSystemMediaKeys()
        pc.api.startNRMListening()
        
        initCache()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        vcm.saveFMPlaylist()
        pc.api.stopNRMListening()
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

    @IBAction func logout(_ sender: NSMenuItem) {
        
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
        
        NotificationCenter.default.post(name: .updateLoginStatus, object: nil)
//        PlayCore.shared.api.logout().done {
//            print("Logout success.")
//            NotificationCenter.default.post(name: .updateLoginStatus, object: nil, userInfo: ["logout": true])
//        }.ensure {
//
//        }.catch {
//            print("Logout error \($0).")
//            NotificationCenter.default.post(name: .updateLoginStatus, object: nil, userInfo: ["logout": false])
//        }
    }
    
    @IBAction func checkForUpdate(_ sender: NSMenuItem) {
        SUUpdater().checkForUpdates(sender)
    }
}


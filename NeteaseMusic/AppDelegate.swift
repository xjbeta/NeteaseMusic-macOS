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
        print("Music Cache Path: \n", VideoCacheManager.directory)
        
        
        // Image cache
        ImageCache.default.cleanExpiredCache()
        print("Image Cache Path: \n", ImageCache.default.diskStorage.directoryURL.path)
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
}


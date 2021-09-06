//
//  MainWindowController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    var updateLoginStatusObserver: NSObjectProtocol?
    var initSidebarPlaylistsObserver: NSObjectProtocol?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isMovableByWindowBackground = true
        
        updateLoginStatusObserver = NotificationCenter.default.addObserver(forName: .updateLoginStatus, object: nil, queue: .main) {
            guard let kv = $0.userInfo as? [String: Any],
                let logout = kv["logout"] as? Bool else {
                self.initLoginStatus(true)
                return
            }
            
            if logout {
                self.initLoginStatus(false)
            } else {
                self.checkLoginStatus()
            }
        }
        initSidebarPlaylistsObserver = NotificationCenter.default.addObserver(forName: .initSidebarPlaylists, object: nil, queue: .main) { _ in
            self.initSidebarPlaylists()
        }
        
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        PlayCore.shared.api.isLogin().done(on: .main) {
            self.initLoginStatus($0)
            }.catch {
                print($0)
        }
    }
    
    func initLoginStatus(_ isLogin: Bool) {
        guard let vc = contentViewController as? MainViewController else { return }
        if isLogin {
            vc.updateMainTabView(.main)
            initUserButton()
            initSidebarItems()
        } else  {
            vc.updateMainTabView(.login)
            // login initViews
            vc.children.compactMap {
                $0 as? LoginViewController
                }.first?.initViews()
//            userButton.isHidden = true
        }
    }
    
    func initUserButton() {
//        userButton.isHidden = true
//        PlayCore.shared.api.userInfo().done(on: .main) {
//            ViewControllerManager.shared.userId = $0.userId
//            self.userButton.title = $0.nickname
//            guard let u = $0.avatarImage else { return }
//            ImageLoader.image(u, true, 13)
//                .roundCorner(radius: .point(self.userButton.frame.size.width / 8))
//                .set(to: self.userButton)
//            self.userButton.isHidden = false
//            }.catch {
//                print($0)
//        }
    }
    
    func initSidebarItems() {
        guard let vc = self.contentViewController as? MainViewController else { return }
        initSidebarPlaylists()
    }
    
    func initSidebarPlaylists() {
        guard let vc = self.contentViewController as? MainViewController else { return }
        vc.children.compactMap {
            $0 as? SidebarViewController
            }.first?.updatePlaylists()
    }
    
    deinit {
        if let o = updateLoginStatusObserver {
            NotificationCenter.default.removeObserver(o)
        }
        if let o = initSidebarPlaylistsObserver {
            NotificationCenter.default.removeObserver(o)
        }
    }
}

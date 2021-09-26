//
//  MainWindowController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class MainWindowController: NSWindowController {
    var updateLoginStatusObserver: NSObjectProtocol?
    var initSidebarPlaylistsObserver: NSObjectProtocol?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isMovableByWindowBackground = true
        
        updateLoginStatusObserver = NotificationCenter.default.addObserver(forName: .updateLoginStatus, object: nil, queue: .main) { _ in
            self.initUsers()
        }
        initSidebarPlaylistsObserver = NotificationCenter.default.addObserver(forName: .initSidebarPlaylists, object: nil, queue: .main) { _ in
            self.initSidebarPlaylists()
        }
        
        initUsers()
    }
    
    func initUsers() {
        guard let vc = self.contentViewController as? MainViewController,
              let discoverVC = vc.contentTabVC(.discover),
              let sidebarVC = sidebarVC(),
              let loginVC = loginVC()
        else { return }
        
        let napi = PlayCore.shared.api
        
        napi.nuserAccount().get {
            if let id = $0?.userId {
                napi.uid = id
            } else {
                throw NeteaseMusicAPI.RequestError.errorCode((301, ""))
            }
        }.then { _ in
            when(fulfilled: [
                discoverVC.initContent(),
                sidebarVC.updatePlaylists()
            ])
        }.done {
            vc.updateMainTabView(.main)
        }.catch(on: .main) {
            switch $0 {
            case NeteaseMusicAPI.RequestError.errorCode((let code, let string)):
                if code == 301 {
                    Log.info("should login.")
                    vc.updateMainTabView(.login)
                    loginVC.initViews()
                } else {
                    Log.error("Unknown error: \(code), \(string)")
                }
            default:
                Log.error("Unknown error: \($0)")
            }
        }
    }
    
    func initSidebarPlaylists() {
        guard let sidebarVC = sidebarVC() else { return }
        sidebarVC.updatePlaylists().done {
            
        }.catch {
            Log.error("InitSidebarPlaylists error: \($0)")
        }
    }
    
    func sidebarVC() -> SidebarViewController? {
        guard let vc = contentViewController as? MainViewController else { return nil }
        return vc.children.compactMap({ $0 as? SidebarViewController }).first
    }
    
    func loginVC() -> LoginViewController? {
        guard let vc = contentViewController as? MainViewController else { return nil }
        return vc.children.compactMap({ $0 as? LoginViewController }).first
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

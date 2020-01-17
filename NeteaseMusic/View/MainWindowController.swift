//
//  MainWindowController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    @IBOutlet weak var searchField: NSSearchField!
    
    @IBAction func search(_ sender: NSSearchField) {
        let str = sender.stringValue
        ViewControllerManager.shared.searchFieldString = str
        if str.isEmpty {
            popover.close()
            return
        }
        
        PlayCore.shared.api.searchSuggest(str).done { [weak self] in
            guard str == self?.searchField.stringValue else { return }
            self?.searchSuggestionsVC.suggestResult = $0
            self?.searchSuggestionsVC.initViewHeight(self?.popover)
            }.catch {
                print($0)
        }
        
        guard !popover.isShown else { return }
        popover.show(relativeTo: sender.frame, of: sender, preferredEdge: .minY)
    }
    
    @IBOutlet weak var userButton: NSButton!
    
    var updateLoginStatusObserver: NSObjectProtocol?
    var initSidebarPlaylistsObserver: NSObjectProtocol?
    
    let searchSuggestionsVC = NSStoryboard(name: .init("SearchSuggestionsView"), bundle: nil).instantiateController(withIdentifier: .init("SearchSuggestionsViewController")) as! SearchSuggestionsViewController
    
    lazy var popover: NSPopover = {
        let p = NSPopover()
        searchSuggestionsVC.dismissPopover = {
            p.close()
        }
        p.contentViewController = searchSuggestionsVC
        return p
    }()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isMovableByWindowBackground = true
        userButton.isHidden = true
        
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
            userButton.isHidden = true
        }
    }
    
    func initUserButton() {
        userButton.isHidden = true
        PlayCore.shared.api.userInfo().done(on: .main) {
            ViewControllerManager.shared.userId = $0.userId
            self.userButton.title = $0.nickname
            guard let u = $0.avatarImage else { return }
            ImageLoader.image(u, true, 13) {
                self.userButton.image = $0.roundCorners(withRadius: $0.size.width / 8)
                self.userButton.isHidden = false
            }
            }.catch {
                print($0)
        }
    }
    
    func initSidebarItems() {
        guard let vc = self.contentViewController as? MainViewController else { return }
        initSidebarPlaylists()
        
        vc.children.compactMap {
            $0 as? DiscoverViewController
            }.first?.initRecommend()
        
        vc.children.compactMap {
            $0 as? FMViewController
            }.first?.loadFMTracks()
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

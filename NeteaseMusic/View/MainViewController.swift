//
//  MainViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet weak var tabView: NSTabView!
    enum TabItems: Int {
        case playlist, playingMusic, fm, preferences, discover, favourite
    }
    @IBOutlet weak var playlistLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var playlistView: NSView!
    
    var sidebarItemObserver: NSKeyValueObservation?
    var playlistNotification: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sidebarItemObserver = PlayCore.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { core, changes in
            guard let newType = changes.newValue??.type, newType != changes.oldValue??.type else { return }
            DispatchQueue.main.async {
                switch newType {
                case .discover:
                    self.updateTabView(.discover)
                case .fm:
                    self.updateTabView(.fm)
                case .playlist, .favourite:
                    self.updateTabView(.playlist)
                default:
                    break
                }
            }
        }
        
        playlistNotification = NotificationCenter.default.addObserver(forName: .showPlaylist, object: nil, queue: .main) { [weak self] _ in
            self?.updatePlaylistLayout()
        }
    }
    
    func updateTabView(_ item: TabItems) {
        tabView.selectTabViewItem(at: item.rawValue)
    }
    
    func updatePlaylistLayout() {
        let width = playlistView.frame.width
        if playlistLayoutConstraint.constant == 0 {
            playlistLayoutConstraint.animator().constant -= width
        } else {
            playlistLayoutConstraint.animator().constant = 0
        }
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
        if let obs = playlistNotification {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

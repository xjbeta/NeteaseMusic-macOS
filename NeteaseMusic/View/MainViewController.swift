//
//  MainViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet weak var mainTabView: NSTabView!
    @IBOutlet weak var contentTabView: NSTabView!
    @IBOutlet weak var playingSongTabView: NSTabView!
    enum ContentTabItems: Int {
        case playlist, fm, preferences, discover, favourite, search, artist
    }
    enum MainTabItems: Int {
        case main, login
    }
    
    enum playingSongTabItems: Int {
        case main, playingSong
    }
    
    @IBOutlet weak var playlistLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var playlistView: NSView!
    @IBOutlet weak var playingSongView: NSView!
    
    var sidebarItemObserver: NSKeyValueObservation?
    var playlistNotification: NSObjectProtocol?
    var playingSongNotification: NSObjectProtocol?
    
    var playlistViewStatus: ExtendedViewState = .hidden
    var playingSongViewStatus: ExtendedViewState = .hidden {
        didSet {
            NotificationCenter.default.post(name: .playingSongViewStatus, object: nil, userInfo: ["status": playingSongViewStatus])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { core, changes in
            guard let newType = changes.newValue??.type, newType != changes.oldValue??.type else { return }
            DispatchQueue.main.async {
                switch newType {
                case .discover:
                    self.updateContentTabView(.discover)
                case .fm:
                    self.updateContentTabView(.fm)
                case .playlist, .favourite, .discoverPlaylist, .album, .topSongs, .fmTrash:
                    self.updateContentTabView(.playlist)
                case .artist:
                    self.updateContentTabView(.artist)
                case .searchResults:
                    self.updateContentTabView(.search)
                default:
                    break
                }
            }
        }
        
        playlistNotification = NotificationCenter.default.addObserver(forName: .showPlaylist, object: nil, queue: .main) { [weak self] _ in
            self?.updatePlaylistLayout()
        }
        
        playingSongNotification = NotificationCenter.default.addObserver(forName: .showPlayingSong, object: nil, queue: .main) { [weak self] _ in
            if PlayCore.shared.fmMode,
                let _ = PlayCore.shared.currentFMTrack {
                ViewControllerManager.shared.selectSidebarItem(.fm)
            } else if !PlayCore.shared.fmMode,
                let _ = PlayCore.shared.currentTrack,
                let playingSongViewStatus = self?.playingSongViewStatus {
                
                let newItem: playingSongTabItems = playingSongViewStatus == .hidden ? .playingSong : .main
                self?.updatePlayingSongTabView(newItem)
                self?.playingSongViewStatus = newItem == .playingSong ? .display : .hidden
            }
        }
    }
    
    func updateMainTabView(_ item: MainTabItems) {
        mainTabView.selectTabViewItem(at: item.rawValue)
    }
    
    func updateContentTabView(_ item: ContentTabItems) {
        contentTabView.selectTabViewItem(at: item.rawValue)
    }
    
    func updatePlayingSongTabView(_ item: playingSongTabItems) {
        playingSongTabView.selectTabViewItem(at: item.rawValue)
    }
    
    func updatePlaylistLayout() {
        guard playlistViewStatus != .animation else { return }
        let width = playlistView.frame.width

        playlistViewStatus = .animation
        let newStatus: ExtendedViewState = playlistLayoutConstraint.constant == 0 ? .display : .hidden
        NSAnimationContext.runAnimationGroup({ [weak self] context in
            if newStatus == .display {
                self?.playlistLayoutConstraint.animator().constant -= width
            } else {
                self?.playlistLayoutConstraint.animator().constant = 0
            }
        }) { [weak self] in
            self?.playlistViewStatus = newStatus
        }
        
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
        if let obs = playlistNotification {
            NotificationCenter.default.removeObserver(obs)
        }
        if let obs = playingSongNotification {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

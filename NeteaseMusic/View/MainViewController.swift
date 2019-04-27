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
        case playlist, fm, preferences, discover, favourite
    }
    @IBOutlet weak var playlistLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var playlistView: NSView!
    @IBOutlet weak var playingSongView: NSView!
    @IBOutlet weak var playingSongTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var playingSongButtomLayoutConstraint: NSLayoutConstraint!
    
    
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
        sidebarItemObserver = PlayCore.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { core, changes in
            guard let newType = changes.newValue??.type, newType != changes.oldValue??.type else { return }
            DispatchQueue.main.async {
                switch newType {
                case .discover:
                    self.updateTabView(.discover)
                case .fm:
                    self.updateTabView(.fm)
                case .playlist, .favourite, .discoverPlaylist:
                    self.updateTabView(.playlist)
                default:
                    break
                }
            }
        }
        
        playlistNotification = NotificationCenter.default.addObserver(forName: .showPlaylist, object: nil, queue: .main) { [weak self] _ in
            self?.updatePlaylistLayout()
        }
        
        playingSongNotification = NotificationCenter.default.addObserver(forName: .showPlayingSong, object: nil, queue: .main) { [weak self] _ in

            guard let _ = PlayCore.shared.currentTrack,
                self?.playingSongViewStatus != .animation else { return }
            self?.playingSongViewStatus = .animation
            let newStatus: ExtendedViewState = self?.playingSongTopLayoutConstraint.priority == .init(999) ? .display : .hidden
            
            NSAnimationContext.runAnimationGroup({ [weak self] context in
                if newStatus == .display {
                    self?.playingSongTopLayoutConstraint.animator().priority = .defaultLow
                    self?.playingSongButtomLayoutConstraint.animator().priority = .init(999)
                } else {
                    self?.playingSongTopLayoutConstraint.animator().priority = .init(999)
                    self?.playingSongButtomLayoutConstraint.animator().priority = .defaultLow
                }
            }) {
                self?.playingSongViewStatus = newStatus
            }
        }
        
    }
    
    func updateTabView(_ item: TabItems) {
        tabView.selectTabViewItem(at: item.rawValue)
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

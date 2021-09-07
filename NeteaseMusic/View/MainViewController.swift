//
//  MainViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class MainViewController: NSViewController {
    @IBOutlet weak var mainTabView: NSTabView!
    @IBOutlet weak var contentTabView: NSTabView!
    @IBOutlet weak var playingSongTabView: NSTabView!
    enum ContentTabItems: Int {
        case playlist, fm, preferences, discover, favourite, search, artist, mySubscription
    }
    enum MainTabItems: Int {
        case main, login
    }
    
    enum playingSongTabItems: Int {
        case main, playingSong
    }
    
    @IBOutlet weak var playingSongView: NSView!
    @IBOutlet weak var messageBox: NSBox!
    @IBOutlet weak var messageTextField: NSTextField!
    private var messageID = ""
    
    var sidebarItemObserver: NSKeyValueObservation?
    var playlistNotification: NSObjectProtocol?
    var playingSongNotification: NSObjectProtocol?
    var displayMessageNotification: NSObjectProtocol?
    var playingSongViewStatus: ExtendedViewState = .hidden {
        didSet {
            NotificationCenter.default.post(name: .playingSongViewStatus, object: nil, userInfo: ["status": playingSongViewStatus])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { core, changes in
            
            guard let newType = changes.newValue??.type else {
                return
            }
            
            DispatchQueue.main.async {
                switch newType {
                case .discover:
                    self.updateContentTabView(.discover)
                case .fm:
                    self.updateContentTabView(.fm)
                case .mySubscription:
                    self.updateContentTabView(.mySubscription)
                case .subscribedPlaylist, .createdPlaylist, .favourite, .discoverPlaylist, .album, .topSongs, .fmTrash:
                    self.updateContentTabView(.playlist)
                case .artist:
                    self.updateContentTabView(.artist)
                case .preferences:
                    self.updateContentTabView(.preferences)
                case .searchSuggestionHeaderSongs,
                     .searchSuggestionHeaderAlbums,
                     .searchSuggestionHeaderArtists,
                     .searchSuggestionHeaderPlaylists:
                    self.updateContentTabView(.search)
                default:
                    break
                }
            }
        }
        
        playingSongNotification = NotificationCenter.default.addObserver(forName: .showPlayingSong, object: nil, queue: .main) { [weak self] _ in
            let pc = PlayCore.shared
            
            if pc.fmMode,
               let _ = pc.currentTrack {
                ViewControllerManager.shared.selectSidebarItem(.fm)
            } else if !pc.fmMode,
                      let _ = pc.currentTrack,
                      let playingSongViewStatus = self?.playingSongViewStatus {
                
                let newItem: playingSongTabItems = playingSongViewStatus == .hidden ? .playingSong : .main
                self?.updatePlayingSongTabView(newItem)
                self?.playingSongViewStatus = newItem == .playingSong ? .display : .hidden
            }
        }
        
        displayMessageNotification = NotificationCenter.default.addObserver(forName: .displayMessage, object: nil, queue: .main) {
            guard let kv = $0.userInfo as? [String: Any],
                let message = kv["message"] as? String else {
                return
            }
            self.showMessage(message)
        }
    }
    
    func showMessage(_ str: String) {
        let id = UUID().uuidString
        messageTextField.stringValue = str
        if messageID == "" {
            messageBox.alphaValue = 0
            messageBox.isHidden = false
            messageBox.animator().alphaValue = 1
        }
        messageID = id
        print("display message \(str)")
        after(seconds: 3).done {
            guard id == self.messageID else { return }
            print("hide message box.")
            self.messageBox.animator().alphaValue = 0
            self.messageID = ""
        }
    }
    
    func updateMainTabView(_ item: MainTabItems) {
        mainTabView.selectTabViewItem(at: item.rawValue)
    }
    
    func updateContentTabView(_ item: ContentTabItems) {
        contentTabView.selectTabViewItem(at: item.rawValue)
        
        guard let vc = contentTabVC(item) else {
            return
        }
        
        vc.initContent().done {
            print("\(item) Content inited.")
            
            
        }.catch {
            print($0)
        }
    }
    
    func contentTabVC(_ item: ContentTabItems) -> ContentTabViewController? {
        children.compactMap {
            $0 as? ContentTabViewController
        }.first {
//            case playlist, fm, preferences, discover, favourite, search, artist, mySubscription
            switch item {
            case .playlist:
                return $0 is PlaylistViewController
            case .fm:
                return $0 is FMViewController
            case .discover:
                return $0 is DiscoverViewController
            case .search:
                return $0 is SearchResultViewController
            case .artist:
                return $0 is ArtistViewController
            case .mySubscription:
                return $0 is SublistViewController
            default:
                return false
            }
        }
    }
    
    func updatePlayingSongTabView(_ item: playingSongTabItems) {
        playingSongTabView.selectTabViewItem(at: item.rawValue)
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
        if let obs = playlistNotification {
            NotificationCenter.default.removeObserver(obs)
        }
        if let obs = playingSongNotification {
            NotificationCenter.default.removeObserver(obs)
        }
        if let obs = displayMessageNotification {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

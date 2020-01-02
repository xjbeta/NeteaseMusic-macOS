//
//  PlaylistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class PlaylistViewController: NSViewController {
    
    @IBOutlet weak var playAllButton: NSButton!
    @IBOutlet weak var subscribeButton: SubscribeButton!
    @IBOutlet weak var coverImageView: NSImageView!
    @IBOutlet weak var titleTextFiled: NSTextField!
    
    @IBOutlet weak var playCountTextField: NSTextField!
    @IBOutlet weak var trackCountTextField: NSTextField!
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var artistTextField: NSTextField!
    
    @IBOutlet weak var descriptionStackView: NSStackView!
    @IBOutlet weak var countAndViewsStackView: NSStackView!
    @IBOutlet weak var artistStackView: NSStackView!
    
    @IBAction func playPlaylist(_ sender: Any) {
        let ids = tracks.map { $0.id }
        if PlayCore.shared.playlist.map({ $0.id }) != ids {
            PlayCore.shared.playlist = tracks
        }
        
        if (sender as? NSButton) == playAllButton {
            PlayCore.shared.start()
        }
    }
    
    @IBAction func subscribe(_ sender: SubscribeButton) {
        guard playlistId > 0 else { return }
        let id = playlistId
        sender.isEnabled = false
        let subscribed = sender.subscribed
        let api = PlayCore.shared.api
        
        api.subscribe(id, unSubscribe: subscribed, type: playlistType)
            .ensure(on: .main) {
                sender.isEnabled = true
        }.done {
            sender.subscribed = !sender.subscribed
            guard let vc = self.view.window?.windowController?.contentViewController as? MainViewController else { return }
            vc.children.compactMap {
                $0 as? SidebarViewController
            }.first?.updatePlaylists()
            print("playlist subscribe / unsubscribe success")
        }.catch {
            print($0)
        }
    }
    
        // MARK: - Playlist Menu
    @IBOutlet var playlistMenu: NSMenu!
    
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var playNextMenuItem: NSMenuItem!
    @IBOutlet weak var copyLinkMenuItem: NSMenuItem!
    @IBOutlet weak var removeFromPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var newPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var addToPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var addToPlaylistMenu: NSMenu!
    
    var playlistMenuUpdateID = ""
    
    var removeMenuItemActionID = ""
    
    @IBAction func menuItemAction(_ sender: NSMenuItem) {
        guard let tableView = trackTableViewController()?.tableView else {
            return
        }
        let selectedIndexs = tableView.selectedIndexs()
        
        switch sender {
        case playMenuItem:
            break
        case playNextMenuItem:
            break
        case copyLinkMenuItem:
            if let t = tracks.enumerated().filter ({
                selectedIndexs.contains($0.offset)
            }).first?.element {
                let str = "https://music.163.com/song?id=\(t.id)"
                ViewControllerManager.shared.copyToPasteboard(str)
            }
        case removeFromPlaylistMenuItem:
            guard removeMenuItemActionID == "" else { return }
            let selectedTracks = tracks.enumerated().filter {
                selectedIndexs.contains($0.offset)
            }
            let ids = selectedTracks.map {
                $0.element.id
            }
            let playlistId = self.playlistId
            let api = PlayCore.shared.api
            let uuid = UUID().uuidString
            removeMenuItemActionID = uuid
            
            
            switch playlistType {
            case .discoverPlaylist:
                guard let track = selectedTracks.first else { return }
                api.discoveryRecommendDislike(track.element.id).done {
                    guard uuid == self.removeMenuItemActionID else { return }
                    guard let newTrack = $0.0 else { return }
                    newTrack.index = track.element.index
                    self.tracks[track.offset] = newTrack
                    print("Remove \(ids) from discoverPlaylist done.")
                }.catch {
                    if let er = ($0 as? NeteaseMusicAPI.RequestError) {
                        switch er {
                        case .errorCode(let code, let msg):
                            if code == 432, msg == "今日暂无更多推荐" {
                                return
                            }
                        default:
                            break
                        }
                    }
                    print("Remove \(ids) from discoverPlaylist error \($0).")
                }
            case .fmTrash:
                guard let track = selectedTracks.first else { return }
                api.fmTrash(id: track.element.id, 0, false).done(on: .main) {
                    guard uuid == self.removeMenuItemActionID else { return }
                    self.trackTableViewController()?.tracks.removeAll {
                        ids.contains($0.id)
                    }
                    print("FM Trash Delected \(ids).")
                }.catch(on: .main) {
                    self.initFMTrashList()
                    print("FM Trash Del error: \($0).")
                }
            case .favourite, .createdPlaylist:
                api.playlistTracks(add: false, ids, to: playlistId).done {
                    guard uuid == self.removeMenuItemActionID else { return }
                    self.trackTableViewController()?.tracks.removeAll {
                        ids.contains($0.id)
                    }
                    print("Remove \(ids) from playlist \(playlistId) done.")
                }.catch(on: .main) {
                    self.initPlaylist(playlistId)
                    print("Remove \(ids) from playlist \(playlistId) error \($0).")
                }
            default:
                removeMenuItemActionID = ""
                return
            }
        case newPlaylistMenuItem:
            guard let newPlaylistVC = newPlaylistViewController else { return }
            self.presentAsSheet(newPlaylistVC)
        default:
            let playlistId = sender.tag
            guard playlistId > 0 else { return }
            
            let ids = tracks.enumerated().filter {
                selectedIndexs.contains($0.offset)
            }.map {
                $0.element.id
            }
            
            PlayCore.shared.api.playlistTracks(add: true, ids, to: playlistId).done {
                print("Add \(ids) to playlist \(playlistId) done.")
                if playlistId == self.playlistId {
                    //                    self.initPlaylist(playlistId)
                }
            }.catch {
                print("Add \(ids) to playlist \(playlistId) error \($0).")
            }
        }
    }
    
    lazy var newPlaylistViewController: NewPlaylistViewController? = {
        let sb = NSStoryboard(name: "NewPlaylist", bundle: nil)
        let vc = sb.instantiateController(withIdentifier: "NewPlaylistViewController") as? NewPlaylistViewController
        vc?.updateSidebarItems = { [weak self] in
            (self?.view.window?.windowController as? MainWindowController)?.initSidebarItems()
        }
        return vc
    }()
    
    
    var sidebarItemObserver: NSKeyValueObservation?
    var tracks: [Track] {
        get {
            return trackTableViewController()?.tracks ?? []
        }
        set {
            trackTableViewController()?.tracks = newValue
        }
    }
    
    var playlistId = -1
    var playlistType: SidebarViewController.ItemType = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coverImageView.wantsLayer = true
        coverImageView.layer?.cornerRadius = 3
        coverImageView.layer?.borderWidth = 0.5
        coverImageView.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        
        
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { [weak self] core, changes in
            guard let newV = changes.newValue,
                let newValue = newV else { return }
            let id = newValue.id
            switch newValue.type {
            case .createdPlaylist, .subscribedPlaylist, .favourite, .discoverPlaylist, .album, .topSongs, .fmTrash:
//                if self?.playlistId == newValue.id,
//                    self?.playlistType == newValue.type {
//                    return
//                }
                self?.playlistId = id
                self?.playlistType = newValue.type
                self?.trackTableViewController()?.playlistId = id
                self?.trackTableViewController()?.playlistType = newValue.type
                self?.trackTableViewController()?.tableView.menu = self?.playlistMenu
            default:
                return
            }
            
            self?.initPlaylistInfo()
            switch newValue.type {
            case .album:
                self?.initPlaylistWithAlbum(id)
            case .topSongs:
                self?.initPlaylistWithTopSongs(id)
            case .subscribedPlaylist, .createdPlaylist, .favourite:
                self?.initPlaylist(id)
            case .discoverPlaylist:
                if id == -114514 {
                    self?.initPlaylistWithRecommandSongs()
                } else {
                    self?.initPlaylist(id)
                }
            case .fmTrash:
                self?.initFMTrashList()
            default:
                break
            }
        }
    }
    
    func initPlaylistInfo() {
        var typeList = [SidebarViewController.ItemType]()
        tracks = []
        
        coverImageView.image = nil
        titleTextFiled.stringValue = ""
        playCountTextField.integerValue = 0
        trackCountTextField.integerValue = 0
        descriptionTextField.stringValue = ""
        descriptionTextField.toolTip = ""
        
        playAllButton.isHidden = playlistType == .fmTrash
        typeList = [.album, .topSongs, .discoverPlaylist]
        countAndViewsStackView.isHidden = typeList.contains(playlistType)
        artistStackView.isHidden = playlistType != .album
        typeList = [.topSongs, .discoverPlaylist, .favourite, .fmTrash]
        subscribeButton.isHidden = typeList.contains(playlistType)
        subscribeButton.isEnabled = true
        descriptionStackView.isHidden = playlistType == .topSongs
        
        initMenuItems()
    }
    
    func initPlaylist(_ id: Int) {
        PlayCore.shared.api.playlistDetail(id).done(on: .main) {
            guard self.playlistId == id else { return }
            self.coverImageView.setImage($0.coverImgUrl.absoluteString, true)
            self.titleTextFiled.stringValue = self.playlistType == .favourite ? "我喜欢的音乐" : $0.name
            let descriptionStr = $0.description ?? "none"
            self.descriptionTextField.stringValue = descriptionStr
            self.descriptionTextField.toolTip = descriptionStr
            self.playCountTextField.integerValue = $0.playCount
            self.trackCountTextField.integerValue = $0.trackCount
            self.tracks = $0.tracks?.initIndexes() ?? []
            
            self.subscribeButton.isEnabled = $0.creator?.userId != ViewControllerManager.shared.userId
            self.subscribeButton.subscribed = $0.subscribed
            }.catch {
                print($0)
        }
    }
    
    func initPlaylistWithRecommandSongs() {
        PlayCore.shared.api.recommendSongs().done(on: .main) {
            guard self.playlistId == -114514 else { return }
            self.titleTextFiled.stringValue = "每日歌曲推荐"
            self.descriptionTextField.stringValue = "根据你的音乐口味生成, 每天6:00更新"
            self.tracks = $0.initIndexes()
            }.catch {
                print($0)
        }
    }
    
    func initPlaylistWithAlbum(_ id: Int) {
        let api = PlayCore.shared.api
        when(fulfilled: api.album(id), api.albumSublist()).done(on: .main) {
            self.coverImageView.setImage($0.0.album.picUrl?.absoluteString, true)
            self.titleTextFiled.stringValue = $0.0.album.name
            self.descriptionTextField.stringValue = $0.0.album.des ?? "none"
            self.descriptionTextField.toolTip = $0.0.album.des
            self.artistTextField.stringValue = $0.0.album.artists?.artistsString() ?? ""
            self.tracks = $0.0.songs.initIndexes()
            
            let subscribed = $0.1.map {
                $0.id
            }.contains($0.0.album.id)
            
            self.subscribeButton.subscribed = subscribed
            }.catch {
                print($0)
        }
    }
    
    func initPlaylistWithTopSongs(_ id: Int) {
        PlayCore.shared.api.artist(id).done(on: .main) {
            self.coverImageView.setImage($0.artist.picUrl, true)
            self.titleTextFiled.stringValue = $0.artist.name + "'s Top 50 Songs"
            self.tracks = $0.hotSongs.initIndexes()
            }.catch {
                print($0)
        }
    }
    
    func initFMTrashList() {
        PlayCore.shared.api.fmTrashList().done(on: .main) {
            let t = "simple mode?"
            self.titleTextFiled.stringValue = "Trash."
            self.tracks = $0.initIndexes()
            }.catch {
                print($0)
        }
    }
    
    func initMenuItems() {
        var typeList = [SidebarViewController.ItemType]()
        
        playMenuItem.isHidden = playlistType == .fmTrash
        playNextMenuItem.isHidden = playlistType == .fmTrash
        copyLinkMenuItem.isHidden = false
        typeList = [.subscribedPlaylist, .album, .topSongs]
        removeFromPlaylistMenuItem.isHidden = typeList.contains(playlistType)
        addToPlaylistMenuItem.isHidden = playlistType == .fmTrash
    }
    
    func trackTableViewController() -> TrackTableViewController? {
        let vc = children.compactMap {
            $0 as? TrackTableViewController
        }.first
        return vc
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}

extension PlaylistViewController: NSMenuItemValidation, NSMenuDelegate {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let tableView = trackTableViewController()?.tableView else {
            return false
        }
        let selectedIndexs = tableView.selectedIndexs()
        
        // Playlist items
        if menuItem.tag != 0, selectedIndexs.count > 0 {
            return true
        }
        
        switch menuItem {
        case copyLinkMenuItem:
            return selectedIndexs.count == 1
        case playMenuItem, playNextMenuItem:
            return selectedIndexs.count > 0
        case removeFromPlaylistMenuItem:
            switch playlistType {
            case .createdPlaylist, .favourite, .fmTrash:
                return selectedIndexs.count > 0
            case .discoverPlaylist:
                return selectedIndexs.count == 1
            default:
                return false
            }
        case newPlaylistMenuItem:
            return true
        default:
            return false
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        playlistMenuUpdateID = ""
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let markID = UUID().uuidString
        playlistMenuUpdateID = markID

        // Update playlist
        addToPlaylistMenu.items.enumerated().forEach {
            if $0.offset >= 2 {
                addToPlaylistMenu.removeItem($0.element)
            }
        }
        
        PlayCore.shared.api.userPlaylist().map { itmes -> [NSMenuItem] in
            guard markID == self.playlistMenuUpdateID else {
                return []
            }
            
            return itmes.enumerated().compactMap { i -> NSMenuItem? in
                if i.element.subscribed {
                    return nil
                }
                
                var name = i.element.name
                if i.offset == 0, name.contains("喜欢的音乐") {
                    name = "我喜欢的音乐"
                }
                let item = NSMenuItem(title: name,
                                      action: #selector(self.menuItemAction), keyEquivalent: "")
                item.tag = i.element.id
                return item
            }
            }.done(on: .main) {
                $0.forEach {
                    self.addToPlaylistMenu.addItem($0)
                }
            }.catch {
                print($0)
        }
        
        removeFromPlaylistMenuItem.isEnabled = removeMenuItemActionID == ""
        
        switch playlistType {
        case .discoverPlaylist:
            // switch to not interested
            removeFromPlaylistMenuItem.title = "Not Interested"
        case .favourite, .createdPlaylist:
            removeFromPlaylistMenuItem.title = "Remove from Playlist"
        case .fmTrash:
            removeFromPlaylistMenuItem.title = "Restore"
        default:
            break
        }
    }
}

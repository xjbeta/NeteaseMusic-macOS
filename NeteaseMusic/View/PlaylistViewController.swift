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
    @IBOutlet weak var subscribeButton: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var coverImageView: NSImageView!
    @IBOutlet weak var titleTextFiled: NSTextField!
    @IBOutlet weak var playlistStrTextField: NSTextField!
    @IBOutlet weak var albumCoverImageView: NSImageView!
    
    @IBOutlet weak var playCountTextField: NSTextField!
    @IBOutlet weak var trackCountTextField: NSTextField!
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var artistTextField: NSTextField!
    @IBOutlet weak var timeTextField: NSTextField!
    
    @IBOutlet weak var descriptionStackView: NSStackView!
    @IBOutlet weak var countAndViewsStackView: NSStackView!
    @IBOutlet weak var artistStackView: NSStackView!
    @IBOutlet weak var timeStackView: NSStackView!
    
// MARK: - Playlist Menu
    @IBOutlet var playlistMenu: NSMenu!
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var playNextMenuItem: NSMenuItem!
    @IBOutlet weak var copyLinkMenuItem: NSMenuItem!
    @IBOutlet weak var removeFromPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var newPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var addToPlaylistMenu: NSMenu!
    
    var playlistMenuUpdateID = ""
    
    @IBAction func menuItemAction(_ sender: NSMenuItem) {
        let selectedIndexs = tableView.selectedIndexs()
        
        switch sender {
        case playMenuItem:
            break
        case playNextMenuItem:
            break
        case copyLinkMenuItem:
            guard selectedIndexs.count == 1,
                let trackId = tracks[safe: tableView.selectedRow]?.id else {
                return
            }
            let str = "https://music.163.com/song?id=\(trackId)"
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([str as NSString])
        case removeFromPlaylistMenuItem:
            let selectedTracks = tracks.enumerated().filter {
                selectedIndexs.contains($0.offset)
            }
            let ids = selectedTracks.map {
                    $0.element.id
            }
            let playlistId = self.playlistId
            
            switch playlistType {
            case .discoverPlaylist:
                guard let track = selectedTracks.first else { return }
                PlayCore.shared.api.discoveryRecommendDislike(track.element.id).done {
                    let newTrack = $0
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
            default:
                PlayCore.shared.api.playlistTracks(add: false, ids, to: playlistId).done {
                    print("Remove \(ids) from playlist \(playlistId) done.")
                    self.initPlaylist(playlistId)
                    }.catch {
                        print("Remove \(ids) from playlist \(playlistId) error \($0).")
                }
            }
        case newPlaylistMenuItem:
            guard let newPlaylistWC = newPlaylistWindowController,
                let sheetWindow = newPlaylistWC.window else { return }
            (newPlaylistWC.contentViewController as? NewPlaylistViewController)?.textField.stringValue = ""
            view.window?.beginSheet(sheetWindow, completionHandler: nil)
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
                    self.initPlaylist(playlistId)
                }
                }.catch {
                    print("Add \(ids) to playlist \(playlistId) error \($0).")
            }
        }
    }
    
    @IBAction func playPlaylist(_ sender: Any) {
        let ids = tracks.map { $0.id }
        let clickedRow = tableView.clickedRow
        if PlayCore.shared.playlist.map({ $0.id }) != ids {
            PlayCore.shared.playlist = tracks
        }
        
        if (sender as? NSButton) == playAllButton {
            PlayCore.shared.start()
        } else if (sender as? NSTableView) == tableView {
            PlayCore.shared.start(clickedRow)
        }
    }
    
    @IBAction func subscribe(_ sender: NSButton) {
        guard playlistId > 0 else { return }
        let id = playlistId
        sender.isEnabled = false
        PlayCore.shared.api.userPlaylist().then { playlists -> Promise<()> in
            let subscribedIds = playlists.filter {
                $0.subscribed
                }.map {
                    $0.id
            }
            
            if subscribedIds.contains(id) {
                return PlayCore.shared.api.playlistSubscribe(id, unSubscribe: true)
            } else {
                return PlayCore.shared.api.playlistSubscribe(id)
            }
            }.ensure(on: .main) {
                let todo = "Update sidebar"
                sender.isEnabled = true
            }.done {
                print("playlist subscribe / unsubscribe success")
            }.catch {
                print($0)
        }
    }
    
    @IBOutlet weak var topViewLayoutConstraint: NSLayoutConstraint!
//    var isUpdateLayout = false
    
    var sidebarItemObserver: NSKeyValueObservation?
    @objc dynamic var tracks = [Track]()
    
    var playlistId = -1
    var playlistType: SidebarViewController.ItemType = .none
    
    lazy var newPlaylistWindowController: NSWindowController? = {
        let sb = NSStoryboard(name: "NewPlaylist", bundle: nil)
        let wc = sb.instantiateController(withIdentifier: "NewPlaylistWindowController") as? NSWindowController
        return wc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playlistStrTextField.textColor = .init(red: 0.83, green: 0.23, blue: 0.19, alpha: 1)
        playlistStrTextField.wantsLayer = true
        playlistStrTextField.layer?.borderWidth = 1
        playlistStrTextField.layer?.cornerRadius = 3.5
        playlistStrTextField.layer?.borderColor = .init(red: 0.83, green: 0.23, blue: 0.19, alpha: 1)
        
            
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { [weak self] core, changes in
            guard let newV = changes.newValue,
                let newValue = newV else { return }
            let id = newValue.id
            switch newValue.type {
            case .playlist, .favourite, .discoverPlaylist, .album, .topSongs, .fmTrash:
//                if self?.playlistId == newValue.id,
//                    self?.playlistType == newValue.type {
//                    return
//                }
                self?.playlistId = id
                self?.playlistType = newValue.type
            default:
                return
            }
            
            switch newValue.type {
            case .album:
                self?.initPlaylistWithAlbum(id)
            case .topSongs:
                self?.initPlaylistWithTopSongs(id)
            case .playlist, .favourite:
                self?.initPlaylist(id)
            case .discoverPlaylist:
                if id == -1, newValue.title == "每日歌曲推荐" {
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(scrollViewDidScroll(_:)), name: NSScrollView.didLiveScrollNotification, object: tableView.enclosingScrollView)
    }
    
    func initPlaylistInfo() {
        let albumMode = playlistType == .album
        let topSongsMode = playlistType == .topSongs
        let discoverPlaylistMode = playlistType == .discoverPlaylist
        tracks.removeAll()
        
        coverImageView.image = nil
        titleTextFiled.stringValue = ""
        playCountTextField.integerValue = 0
        trackCountTextField.integerValue = 0
        descriptionTextField.stringValue = ""
        descriptionTextField.toolTip = ""
        albumCoverImageView.isHidden = !albumMode
        
        tableView.tableColumn(withIdentifier: .init("PlaylistAlbum"))?.isHidden = albumMode
        tableView.tableColumn(withIdentifier: .init("PlaylistPop"))?.isHidden = !albumMode
        
        countAndViewsStackView.isHidden = albumMode || topSongsMode || discoverPlaylistMode
        artistStackView.isHidden = !albumMode
        timeStackView.isHidden = !albumMode
        subscribeButton.isHidden = topSongsMode
        descriptionStackView.isHidden = topSongsMode
    }
    
    func initPlaylist(_ id: Int) {
        initPlaylistInfo()
        PlayCore.shared.api.playlistDetail(id).done(on: .main) {
            guard self.playlistId == id else { return }
            self.playlistStrTextField.stringValue = "Playlist"
            self.coverImageView.setImage($0.coverImgUrl.absoluteString, true)
            self.titleTextFiled.stringValue = $0.name
            let descriptionStr = $0.description ?? "none"
            self.descriptionTextField.stringValue = descriptionStr
            self.descriptionTextField.toolTip = descriptionStr
            self.playCountTextField.integerValue = $0.playCount
            self.trackCountTextField.integerValue = $0.trackCount
            self.tracks = $0.tracks?.initIndexes() ?? []
            }.catch {
                print($0)
        }
    }
    
    func initPlaylistWithRecommandSongs() {
        initPlaylistInfo()
        PlayCore.shared.api.recommendSongs().done(on: .main) {
            guard self.playlistId == -1 else { return }
            self.playlistStrTextField.stringValue = ""
            self.titleTextFiled.stringValue = "每日歌曲推荐"
            self.descriptionTextField.stringValue = "根据你的音乐口味生成, 每天6:00更新"
            self.tracks = $0.initIndexes()
            }.catch {
                print($0)
        }
    }
    
    func initPlaylistWithAlbum(_ id: Int) {
        initPlaylistInfo()
        PlayCore.shared.api.album(id).done(on: .main) {
            self.coverImageView.setImage($0.album.picUrl?.absoluteString ?? "", true)
            self.playlistStrTextField.stringValue = "Album"
            self.titleTextFiled.stringValue = $0.album.name
            self.descriptionTextField.stringValue = $0.album.des ?? "none"
            self.artistTextField.stringValue = $0.album.artists?.artistsString() ?? ""
            self.timeTextField.stringValue = $0.album.formattedTime()
            self.tracks = $0.songs.initIndexes()
            }.catch {
                print($0)
        }
    }
    
    func initPlaylistWithTopSongs(_ id: Int) {
        initPlaylistInfo()
        PlayCore.shared.api.artist(id).done(on: .main) {
            self.coverImageView.setImage($0.artist.picUrl ?? "", true)
            self.titleTextFiled.stringValue = $0.artist.name + "'s Top 50 Songs"
            self.tracks = $0.hotSongs.initIndexes()
            }.catch {
                print($0)
        }
    }
    
    func initFMTrashList() {
        initPlaylistInfo()
        PlayCore.shared.api.fmTrashList().done(on: .main) {
            let t = "simple mode?"
            self.titleTextFiled.stringValue = "Trash."
            self.tracks = $0.initIndexes()
            }.catch {
                print($0)
        }
    }
    
    @objc func scrollViewDidScroll(_ notification: Notification) {
        if let scrollView = notification.object as? NSScrollView {
            let visibleRect = scrollView.contentView.documentVisibleRect
//            self.topViewLayoutConstraint.constant = visibleRect.origin.y > 100 ? 100 : 200
//            isUpdateLayout = true
//            NSAnimationContext.runAnimationGroup({
//                $0.duration = 0.15
//                self.topViewLayoutConstraint.animator().constant = visibleRect.origin.y > 100 ? 100 : 200
//                isUpdateLayout = false
//            })
            
        }
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}

extension PlaylistViewController: NSMenuItemValidation, NSMenuDelegate {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
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
            case .playlist:
                return selectedIndexs.count > 0
            case .discoverPlaylist:
                return selectedIndexs.count == 1
            default:
                return false
            }
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

        switch playlistType {
        case .discoverPlaylist:
            // switch to not interested
            removeFromPlaylistMenuItem.title = "Not Interested"
        default:
            removeFromPlaylistMenuItem.title = "Remove from Playlist"
        }
    }
}

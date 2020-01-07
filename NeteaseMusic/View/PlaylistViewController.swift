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
                if self?.trackTableViewController()?.delegate == nil {
                    self?.trackTableViewController()?.delegate = self
                }
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

extension PlaylistViewController: TrackTableViewDelegate {
    func trackTableView(_ tableView: NSTableView, startPlaying tracks: [Track], with track: Track?) {
        let pc = PlayCore.shared
        guard tracks.count >= 1 else { return }
        if let t = track,
            let i = tracks.firstIndex(of: t) {
            // DoubleClick action
            pc.playlist = tracks
            pc.start(i)
        } else if let c = pc.currentTrack,
            let i = pc.playlist.firstIndex(of: c) {
            // add to next and play
            pc.playlist.insert(contentsOf: tracks, at: i + 1)
            pc.start(i + 1)
        } else {
            pc.playlist = tracks
            pc.start()
        }
    }
    
    func trackTableView(_ tableView: NSTableView, playNext tracks: [Track]) {
        let pc = PlayCore.shared
        guard tracks.count >= 1 else { return }
        if let c = pc.currentTrack,
            let i = pc.playlist.firstIndex(of: c) {
            pc.playlist.insert(contentsOf: tracks, at: i + 1)
        } else {
            pc.playlist = tracks
            pc.start()
        }
    }
    
    func trackTableView(_ tableView: NSTableView, copyLink track: Track) {
        let str = "https://music.163.com/song?id=\(track.id)"
        ViewControllerManager.shared.copyToPasteboard(str)
    }
    
    func trackTableView(_ tableView: NSTableView, remove tracks: [Track], completionHandler: (() -> Void)? = nil) {
        let selectedIndexs = tableView.selectedIndexs()
        let selectedTracks = tracks.enumerated().filter {
            selectedIndexs.contains($0.offset)
        }
        let ids = selectedTracks.map {
            $0.element.id
        }
        let playlistId = self.playlistId
        let api = PlayCore.shared.api
        let vcm = ViewControllerManager.shared
        
        
        switch playlistType {
        case .discoverPlaylist:
            guard let track = selectedTracks.first else { return }
            api.discoveryRecommendDislike(track.element.id).done {
                guard let newTrack = $0.0 else { return }
                newTrack.index = track.element.index
                self.tracks[track.offset] = newTrack
                print("Remove \(ids) from discoverPlaylist done.")
            }.ensure {
                completionHandler?()
            }.catch {
                if let er = ($0 as? NeteaseMusicAPI.RequestError) {
                    switch er {
                    case .errorCode(let code, let msg):
                        if code == 432, msg == "今日暂无更多推荐" {
                            vcm.displayMessage(msg)
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
                self.tracks.removeAll {
                    ids.contains($0.id)
                }
                print("FM Trash Delected \(ids).")
            }.ensure {
                completionHandler?()
            }.catch(on: .main) {
                self.initFMTrashList()
                print("FM Trash Del error: \($0).")
            }
        case .favourite, .createdPlaylist:
            api.playlistTracks(add: false, ids, to: playlistId).done {
                self.tracks.removeAll {
                    ids.contains($0.id)
                }
                print("Remove \(ids) from playlist \(playlistId) done.")
            }.ensure {
                completionHandler?()
            }.catch(on: .main) {
                self.initPlaylist(playlistId)
                print("Remove \(ids) from playlist \(playlistId) error \($0).")
            }
        default:
            completionHandler?()
        }
    }
    
    func trackTableView(_ tableView: NSTableView, createPlaylist tracks: [Track], completionHandler: (() -> Void)? = nil) {
        guard let newPlaylistVC = newPlaylistViewController else { return }
        self.presentAsSheet(newPlaylistVC)
    }
    
    func trackTableView(_ tableView: NSTableView, add tracks: [Track], to playlist: Int) {
        let ids = tracks.map {
            $0.id
        }
        PlayCore.shared.api.playlistTracks(add: true, ids, to: playlist).done {
            print("Add \(ids) to playlist \(playlist) done.")
            if playlist == self.playlistId {
                self.initPlaylist(self.playlistId)
            }
        }.catch {
            print("Add \(ids) to playlist \(playlist) error \($0).")
        }
    }
}

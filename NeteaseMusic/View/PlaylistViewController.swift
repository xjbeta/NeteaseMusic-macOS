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
            case .playlist, .favourite, .discoverPlaylist, .album, .topSongs, .fmTrash:
//                if self?.playlistId == newValue.id,
//                    self?.playlistType == newValue.type {
//                    return
//                }
                self?.playlistId = id
                self?.playlistType = newValue.type
                self?.trackTableViewController()?.playlistId = id
                self?.trackTableViewController()?.playlistType = newValue.type
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
        let albumMode = playlistType == .album
        let topSongsMode = playlistType == .topSongs
        let discoverPlaylistMode = playlistType == .discoverPlaylist
        tracks = []
        
        coverImageView.image = nil
        titleTextFiled.stringValue = ""
        playCountTextField.integerValue = 0
        trackCountTextField.integerValue = 0
        descriptionTextField.stringValue = ""
        descriptionTextField.toolTip = ""
        
        countAndViewsStackView.isHidden = albumMode || topSongsMode || discoverPlaylistMode
        artistStackView.isHidden = !albumMode
        subscribeButton.isHidden = topSongsMode || discoverPlaylistMode || playlistType == .favourite
        subscribeButton.isEnabled = true
        descriptionStackView.isHidden = topSongsMode
    }
    
    func initPlaylist(_ id: Int) {
        initPlaylistInfo()
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
        initPlaylistInfo()
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
        initPlaylistInfo()
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
        initPlaylistInfo()
        PlayCore.shared.api.artist(id).done(on: .main) {
            self.coverImageView.setImage($0.artist.picUrl, true)
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

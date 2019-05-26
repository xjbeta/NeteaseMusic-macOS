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
            case .playlist, .favourite, .discoverPlaylist, .album, .hotSongs:
                if self?.playlistId == newValue.id,
                    self?.playlistType == newValue.type {
                    return
                }
                self?.playlistId = id
                self?.playlistType = newValue.type
            default:
                return
            }
            
            switch newValue.type {
            case .album:
                self?.initPlaylistWithAlbum(id)
            case .hotSongs:
                self?.initPlaylistWithHotSongs(id)
            case .playlist:
                self?.initPlaylist(id)
            case .discoverPlaylist:
                self?.initPlaylistWithRecommandSongs()
            default:
                break
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(scrollViewDidScroll(_:)), name: NSScrollView.didLiveScrollNotification, object: tableView.enclosingScrollView)
    }
    
    func initPlaylistInfo() {
        let albumMode = playlistType == .album
        let hotSongsMode = playlistType == .hotSongs
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
        
        countAndViewsStackView.isHidden = albumMode || hotSongsMode || discoverPlaylistMode
        artistStackView.isHidden = !albumMode
        timeStackView.isHidden = !albumMode
        subscribeButton.isHidden = hotSongsMode
        descriptionStackView.isHidden = hotSongsMode
    }
    
    func initPlaylist(_ id: Int) {
        initPlaylistInfo()
        PlayCore.shared.api.playlistDetail(id).done(on: .main) {
            guard self.playlistId == id else { return }
            self.playlistStrTextField.stringValue = "Playlist"
            self.coverImageView.image = NSImage(contentsOf: $0.coverImgUrl)
            self.titleTextFiled.stringValue = $0.name
            let descriptionStr = $0.description ?? "none"
            self.descriptionTextField.stringValue = descriptionStr
            self.descriptionTextField.toolTip = descriptionStr
            self.playCountTextField.integerValue = $0.playCount
            self.trackCountTextField.integerValue = $0.trackCount
            var tracks = $0.tracks ?? []
            tracks.enumerated().forEach {
                tracks[$0.offset].index = $0.offset
            }
            self.tracks = tracks
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
            var tracks = $0
            tracks.enumerated().forEach {
                tracks[$0.offset].index = $0.offset
            }
            self.tracks = tracks
            }.catch {
                print($0)
        }
    }
    
    func initPlaylistWithAlbum(_ id: Int) {
        initPlaylistInfo()
        PlayCore.shared.api.album(id).done(on: .main) {
            self.coverImageView.image = $0.album.cover
            self.playlistStrTextField.stringValue = "Album"
            self.titleTextFiled.stringValue = $0.album.name
            self.descriptionTextField.stringValue = $0.album.des ?? "none"
            self.artistTextField.stringValue = $0.album.artists?.artistsString() ?? ""
            self.timeTextField.stringValue = $0.album.formattedTime()
            
            var tracks = $0.songs
            tracks.enumerated().forEach {
                tracks[$0.offset].index = $0.offset
            }
            self.tracks = tracks
            }.catch {
                print($0)
        }
    }
    
    func initPlaylistWithHotSongs(_ id: Int) {
        initPlaylistInfo()
        PlayCore.shared.api.artist(id).done(on: .main) {
            self.coverImageView.image = $0.artist.cover
            self.titleTextFiled.stringValue = $0.artist.name + "'s Top 50 Songs"
            
            var tracks = $0.hotSongs
            tracks.enumerated().forEach {
                tracks[$0.offset].index = $0.offset
            }
            self.tracks = tracks
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


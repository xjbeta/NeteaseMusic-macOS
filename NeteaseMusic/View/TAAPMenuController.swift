//
//  TAAPMenuController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2020/1/8.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

enum TAAPItemsType: String {
    case none, song, album, artist, playlist, createdPlaylist, discoverPlaylist, favouritePlaylist, dailyPlaylist, topSongs
}

protocol TAAPMenuDelegate {
    func selectedItems() -> (id: [Int], items: [Any])
    func tableViewList() -> (type: SidebarViewController.ItemType, id: Int, contentType: TAAPItemsType)
    
    func removeSuccess(ids: [Int], newItem: Any?)
    func shouldReloadData()
    func presentNewPlaylist(_ newPlaylisyVC: NewPlaylistViewController)
}

class TAAPMenuController: NSObject, NSMenuDelegate, NSMenuItemValidation {
    
    var delegate: TAAPMenuDelegate?
    
// MARK: - Menu
    @IBOutlet var menu: NSMenu!
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var copyLinkMenuItem: NSMenuItem!
    @IBOutlet weak var removeMenuItem: NetworkRequestMenuItem!
    @IBOutlet weak var newPlaylistSubMenuItem: NetworkRequestMenuItem!
    @IBOutlet weak var newPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var addToPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var addToPlaylistMenu: NSMenu!
    @IBOutlet weak var subscribeMenuItem: NetworkRequestMenuItem!
    
    @IBOutlet weak var albumMenuItem: NSMenuItem!
    @IBOutlet weak var artistMenuItem: NSMenuItem!
    @IBOutlet weak var fromMenuItem: NSMenuItem!
    
// MARK: - Menu Actions
    @IBAction func play(_ sender: NSMenuItem) {
        guard let vc = delegate as? ContentTabViewController else { return }
        
        vc.startPlay(false)
    }
    
    @IBAction func copyLink(_ sender: NSMenuItem) {
        guard let d = delegate,
            d.selectedItems().id.count == 1 else { return }
        let type = d.tableViewList().contentType
        var apiStr = ""
        switch type {
        case .song, .artist, .album:
            apiStr = type.rawValue
        case .playlist, .createdPlaylist, .favouritePlaylist:
            apiStr = TAAPItemsType.playlist.rawValue
        default:
            return
        }
        guard let id = d.selectedItems().id.first, id > 0 else { return }
        
        let str = "https://music.163.com/\(apiStr)?id=\(id)"
        ViewControllerManager.shared.copyToPasteboard(str)
    }
    
    @IBAction func subscribe(_ sender: NetworkRequestMenuItem) {
        guard let d = delegate else { return }
        let pc = PlayCore.shared
        let type = d.tableViewList()
        
        guard let id = d.selectedItems().id.first, id > 0 else { return }
        let unsubscribe = sender.tag == 1
        sender.requesting = true
        var p: Promise<()>
        switch type.contentType {
        case .artist, .album:
            p = pc.api.subscribe(id, unsubscribe: unsubscribe, type: type.contentType)
        case .playlist:
            p = pc.api.subscribe(id, unsubscribe: unsubscribe, type: .playlist)
        case .createdPlaylist:
            p = pc.api.playlistDelete(id)
        default:
            sender.requesting = false
            return
        }
        
        p.done {
            switch type.contentType {
            case .artist, .album:
                guard d.tableViewList() == type, unsubscribe else { return }
                d.removeSuccess(ids: [id], newItem: nil)
            case .playlist, .createdPlaylist:
                if unsubscribe, type.type != .discover {
                    d.removeSuccess(ids: [id], newItem: nil)
                }
                NotificationCenter.default.post(name: .initSidebarPlaylists, object: nil)
            default:
                break
            }
        }.ensure {
            sender.requesting = false
        }.catch {
            Log.error("Subscribe error \($0)")
        }
    }
    
    @IBAction func remove(_ sender: NetworkRequestMenuItem) {
        guard let d = delegate,
            d.selectedItems().id.count > 0 else { return }
        let list = d.tableViewList()
        
        let playlistId = list.id
        let api = PlayCore.shared.api
        let vcm = ViewControllerManager.shared
        sender.requesting = true
        switch list.type {
        case .discoverPlaylist, .discover:
            guard let id = d.selectedItems().id.first, id > 0 else { return }
            var alg = ""
            if let item = d.selectedItems().items.first as? DiscoverViewController.RecommendItem {
                alg = item.alg
            }
            api.discoveryRecommendDislike(id, isPlaylist: list.contentType == .playlist, alg: alg).done {
                Log.info("Remove \(id) from discoverPlaylist done.")
                guard d.tableViewList() == list else { return }
                if list.contentType == .playlist {
                    d.removeSuccess(ids: [id], newItem: $0.1)
                } else {
                    d.removeSuccess(ids: [id], newItem: $0.0)
                }
            }.ensure {
                sender.requesting = false
            }.catch {
                if let er = ($0 as? NeteaseMusicAPI.RequestError) {
                    switch er {
                    case .errorCode((let code, let msg)):
                        if code == 432, msg == "今日暂无更多推荐" {
                            vcm.displayMessage(msg)
                            return
                        }
                    default:
                        break
                    }
                }
                d.shouldReloadData()
                Log.error("Remove \(id) from discoverPlaylist error \($0).")
            }
        case .fmTrash:
            guard let id = d.selectedItems().id.first, id > 0 else { return }
            api.fmTrash(id: id, 0, false).done {
                Log.info("FM Trash Delected \(id).")
                guard d.tableViewList().type == .fmTrash else { return }
                d.removeSuccess(ids: [id], newItem: nil)
            }.ensure {
                sender.requesting = false
            }.catch {
                d.shouldReloadData()
                Log.error("FM Trash Del error: \($0).")
            }
        case .favourite, .createdPlaylist:
            let ids = d.selectedItems().id
            api.playlistTracks(add: false, ids, to: playlistId).done {
                guard list == d.tableViewList() else { return }
                d.removeSuccess(ids: ids, newItem: nil)
                Log.info("Remove \(ids) from playlist \(playlistId) done.")
            }.ensure {
                sender.requesting = false
            }.catch {
                d.shouldReloadData()
                Log.error("Remove \(ids) from playlist \(playlistId) error \($0).")
            }
        case .sidePlaylist:
            sender.requesting = false
            let ids = d.selectedItems().id
            d.removeSuccess(ids: ids, newItem: nil)
        default:
            sender.requesting = false
            break
        }
    }
    
    @IBAction func newPlaylist(_ sender: NSMenuItem) {
        guard let vc = newPlaylistViewController,
            let d = delegate else { return }
        d.presentNewPlaylist(vc)
    }
    
    @IBAction func menuItemAction(_ sender: NSMenuItem) {
        let playlistId = sender.tag
        guard let d = delegate,
            playlistId > 0,
            let ids = delegate?.selectedItems().id,
            ids.count > 0 else { return }
        PlayCore.shared.api.playlistTracks(add: true, ids, to: playlistId).done {
            Log.info("Add \(ids) to playlist \(playlistId) done.")
            guard playlistId == d.tableViewList().id else { return }
            switch d.tableViewList().type {
            case .createdPlaylist, .favourite:
                d.shouldReloadData()
            default:
                break
            }
        }.catch {
            Log.error("Add \(ids) to playlist \(playlistId) error \($0).")
        }
    }
    
    @IBAction func aafMenuActions(_ sender: NSMenuItem) {
        guard let song = delegate?.selectedItems().items.first as? Track else {
            return
        }
        let vcm = ViewControllerManager.shared
        
        switch sender {
        case albumMenuItem:
            vcm.selectSidebarItem(.album, song.album.id)
        case artistMenuItem:
            guard let id = song.artists.first?.id else { return }
            vcm.selectSidebarItem(.artist, id)
        case fromMenuItem:
            vcm.selectSidebarItem(song.from.type, song.from.id)
        default:
            break
        }
    }
    
    private var playlistMenuUpdateID = ""
    
    lazy var newPlaylistViewController: NewPlaylistViewController? = {
        let sb = NSStoryboard(name: "NewPlaylist", bundle: nil)
        let vc = sb.instantiateController(withIdentifier: "NewPlaylistViewController") as? NewPlaylistViewController
        return vc
    }()
    
// MARK: - Menu Delegate
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let d = delegate else {
            return false
        }
        let selectedIDs = d.selectedItems().id
        let type = d.tableViewList().type
        
        // Playlist items
        if menuItem.tag > 1, selectedIDs.count > 0 {
            return true
        }
        
        if let m = menuItem as? NetworkRequestMenuItem, m.requesting {
            return false
        }
        
        switch menuItem {
        case copyLinkMenuItem, subscribeMenuItem:
            return selectedIDs.count == 1
        case playMenuItem:
            return selectedIDs.count > 0
        case removeMenuItem:
            switch type {
            case .createdPlaylist, .favourite, .fmTrash, .sidePlaylist:
                return selectedIDs.count > 0
            case .discoverPlaylist, .discover:
                return selectedIDs.count == 1
            default:
                return false
            }
    
        case newPlaylistMenuItem, newPlaylistSubMenuItem:
            return true
        case albumMenuItem, artistMenuItem, fromMenuItem:
            return type == .sidePlaylist && selectedIDs.count == 1
        default:
            return false
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        playlistMenuUpdateID = ""
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let d = delegate, menu == self.menu else {
            if menu == addToPlaylistMenu {
                updatePlaylists()
            }
            return
        }
        
        let markID = UUID().uuidString
        playlistMenuUpdateID = markID
        
        let tableViewList = d.tableViewList()
        menu.items.forEach {
            if !$0.isSeparatorItem {
                $0.isHidden = !menuItemsToDisplay().contains($0)
            }
        }
        
        
        switch tableViewList.type {
        case .discoverPlaylist, .discover:
            // switch to not interested
            removeMenuItem.title = "不感兴趣"
        case .favourite, .createdPlaylist:
            removeMenuItem.title = "从歌单中删除"
        case .sidePlaylist:
            removeMenuItem.title = "从列表中删除"
            let items = d.selectedItems()
            if items.id.count == 1,
                let song = items.items.first as? Track {
                albumMenuItem.title = "专辑: \(song.album.name)"
                artistMenuItem.title = "歌手: \(song.artists.first?.name ?? "none")"
                fromMenuItem.title = "来自: \(song.from.name ?? "Unknown")"
            }
        case .fmTrash:
            removeMenuItem.title = "还原"
        default:
            break
        }
        
        switch tableViewList.type {
        case .sidebar:
            if tableViewList.contentType == .createdPlaylist {
                subscribeMenuItem.title = "删除歌单"
            } else {
                subscribeMenuItem.title = "删除歌单"
            }
            subscribeMenuItem.tag = 1
        case .mySubscription:
            subscribeMenuItem.title = "删除歌单"
            subscribeMenuItem.tag = 1
        case .searchResults, .discover:
            subscribeMenuItem.isEnabled = false
            subscribeMenuItem.title = "..."
            guard let id = d.selectedItems().id.first else {
                subscribeMenuItem.isHidden = true
                return
            }
            var p: Promise<[Int]>
            let api = PlayCore.shared.api
            switch tableViewList.contentType {
            case .album:
                p = api.albumSublist().map {
                    $0.map({ $0.id })
                }
            case .artist:
                p = api.albumSublist().map {
                    $0.map({ $0.id })
                }
            case .playlist:
                p = api.userPlaylist().map {
                    $0.filter({ $0.subscribed }).map({ $0.id })
                }
            default:
                return
            }
            p.done {
                guard markID == self.playlistMenuUpdateID else { return }
                if $0.contains(id) {
                    self.subscribeMenuItem.title = "Unsubscribe"
                    self.subscribeMenuItem.tag = 1
                } else {
                    self.subscribeMenuItem.title = "Subscribe"
                    self.subscribeMenuItem.tag = 0
                }
            }.catch {
                self.subscribeMenuItem.isHidden = true
                Log.error("check subscribe album list error \($0)")
            }
        default:
            subscribeMenuItem.title = "Subscribe"
            subscribeMenuItem.tag = 0
        }
    }
    
    
// MARK: - Other

    func updatePlaylists() {
        guard let d = delegate else { return }
        
        let tableViewList = d.tableViewList()
        
        let markID = UUID().uuidString
        playlistMenuUpdateID = markID
        
        // Update playlist
        addToPlaylistMenu.items.enumerated().forEach {
            if $0.offset >= 1 {
                addToPlaylistMenu.removeItem($0.element)
            }
        }
        
        PlayCore.shared.api.userPlaylist().map { itmes -> [NSMenuItem] in
            guard markID == self.playlistMenuUpdateID else {
                return []
            }
            
            return itmes.enumerated().compactMap { i -> NSMenuItem? in
                if i.element.subscribed {
                    if tableViewList.type != .sidebar,
                        d.selectedItems().id.first == i.element.id {
                        self.subscribeMenuItem.tag = 1
                        self.subscribeMenuItem.title = "Unsubscribe"
                    }
                    return nil
                }
                
                var name = i.element.name
                if i.offset == 0, name.contains("喜欢的音乐") {
                    name = "我喜欢的音乐"
                }
                
                let item = NSMenuItem()
                item.target = self
                item.title = name
                item.action = #selector(self.menuItemAction(_:))
                item.tag = i.element.id
                return item
            }
        }.done {
            $0.forEach {
                self.addToPlaylistMenu.addItem($0)
            }
            self.addToPlaylistMenu.insertItem(NSMenuItem.separator(), at: 1)
        }.catch {
            let item = NSMenuItem(title: "Load Playlists Failed", action: nil, keyEquivalent: "")
            item.isEnabled = false
            self.addToPlaylistMenu.addItem(item)
            self.addToPlaylistMenu.insertItem(NSMenuItem.separator(), at: 1)
            Log.error("\($0)")
        }
    }
    
    func menuItemsToDisplay() -> [NSMenuItem] {
        guard let d = delegate else { return [] }
        let type = d.tableViewList().type
        let cType = d.tableViewList().contentType
        let albumItems: [NSMenuItem] = [playMenuItem, copyLinkMenuItem, subscribeMenuItem]
        let songItems: [NSMenuItem] =  [playMenuItem, copyLinkMenuItem, addToPlaylistMenuItem]
        let songItems2: [NSMenuItem] =  [playMenuItem, copyLinkMenuItem, addToPlaylistMenuItem, removeMenuItem]
        switch type {
        case .discover:
            switch cType {
            case .dailyPlaylist:
                return [playMenuItem]
            case .playlist:
                return [playMenuItem, copyLinkMenuItem, subscribeMenuItem, removeMenuItem]
            default:
                break
            }
        case .favourite:
            return songItems2
        case .discoverPlaylist:
            return songItems2
        case .album:
            return songItems
        case .artist:
            switch cType {
            case .topSongs:
                return [playMenuItem]
            case .album:
                return albumItems
            default:
                break
            }
        case .topSongs:
            return songItems
        case .searchResults:
            switch cType {
            case .album, .playlist:
                return albumItems
            case .artist:
                return [copyLinkMenuItem, subscribeMenuItem]
            case .song:
                return songItems
            default:
                break
            }
        case .fmTrash:
            return [copyLinkMenuItem, removeMenuItem]
        case .createdPlaylist:
            return songItems2
        case .subscribedPlaylist:
            return songItems
        case .mySubscription:
            switch cType {
            case .album:
                return albumItems
            case .artist:
                return [copyLinkMenuItem, subscribeMenuItem]
            default:
                break
            }
        case .sidebar:
            switch cType {
            case .favouritePlaylist:
                return [playMenuItem, copyLinkMenuItem]
            case .playlist:
                return [playMenuItem, copyLinkMenuItem, newPlaylistSubMenuItem, subscribeMenuItem]
            case .createdPlaylist:
                return [playMenuItem, copyLinkMenuItem, newPlaylistMenuItem, subscribeMenuItem]
            default:
                break
            }
        case .sidePlaylist:
            let ids = d.selectedItems().id
            if ids.count == 1 {
                return [playMenuItem, addToPlaylistMenuItem, copyLinkMenuItem, removeMenuItem, albumMenuItem, artistMenuItem, fromMenuItem]
            } else if ids.count > 1 {
                return [playMenuItem, addToPlaylistMenuItem, removeMenuItem]
            }
        default:
            break
        }
        return []
    }
    
    func getTracksForPlay() -> Promise<[Track]> {
        let empty = Promise<[Track]> {
            $0.fulfill([])
        }
        
        let pc = PlayCore.shared
        guard let d = delegate,
            let id = d.selectedItems().id.first else {
                return empty
        }
        let tracks = d.selectedItems().items as? [Track] ?? []
        
        switch d.tableViewList().contentType {
        case .song:
            return Promise<[Track]> {
                $0.fulfill(tracks)
            }
        case .album:
            return pc.api.album(id).map {
                $0.songs
            }
        case .playlist, .createdPlaylist, .favouritePlaylist:
            return pc.api.playlistDetail(id).map {
                $0.tracks ?? []
            }
        case .dailyPlaylist:
            return pc.api.recommendSongs()
        case .topSongs:
            guard id > 0 else { return empty }
            return pc.api.artist(id).map {
                $0.hotSongs
            }
        default:
            return empty
        }
    }
}

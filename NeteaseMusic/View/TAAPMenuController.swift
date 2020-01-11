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
    case none, song, album, artist, playlist, discoverPlaylist
}

protocol TAAPMenuDelegate {
    func selectedIndexs() -> IndexSet
    func selectedItems() -> (tracks: [Track], albums: [Track.Album], artists: [Track.Artist], playlists: [Playlist])
    func tableViewList() -> (type: SidebarViewController.ItemType, id: Int, contentType: TAAPItemsType)
    
    func removeSuccess(ids: [Int], newItem: Track?)
    func shouldReloadData()
    func presentNewPlaylist(_ newPlaylisyVC: NewPlaylistViewController)
}

class TAAPMenuController: NSObject, NSMenuDelegate, NSMenuItemValidation {
    
    var delegate: TAAPMenuDelegate?
    
    @IBOutlet var menu: NSMenu!
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var playNextMenuItem: NSMenuItem!
    @IBOutlet weak var copyLinkMenuItem: NSMenuItem!
    @IBOutlet weak var removeMenuItem: NetworkRequestMenuItem!
    @IBOutlet weak var newPlaylistMenuItem: NetworkRequestMenuItem!
    @IBOutlet weak var addToPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var addToPlaylistMenu: NSMenu!
    @IBOutlet weak var subscribeMenuItem: NetworkRequestMenuItem!
    
    @IBAction func play(_ sender: NSMenuItem) {
        let pc = PlayCore.shared
        getTracksForPlay().done {
            let ts = $0
            if ts.count > 0 {
                pc.playlist = ts
                pc.start()
            } else {
                print("Play empty tracks.")
            }
        }.catch {
            print($0)
        }
    }
    
    @IBAction func playNext(_ sender: NSMenuItem) {
        let pc = PlayCore.shared
        getTracksForPlay().done {
            let ts = $0
            if ts.count > 0 {
                if let c = pc.currentTrack,
                    let i = pc.playlist.firstIndex(of: c) {
                    pc.playlist.insert(contentsOf: ts, at: i + 1)
                } else {
                    pc.playlist = ts
                    pc.start()
                }
            } else {
                print("Play empty tracks.")
            }
        }.catch {
            print($0)
        }
    }
    
    @IBAction func copyLink(_ sender: NSMenuItem) {
        guard let d = delegate,
            d.selectedIndexs().count == 1 else { return }
        let type = d.tableViewList().contentType
        let items = d.selectedItems()
        var id = 0
        switch type {
        case .song:
            id = items.tracks.first?.id ?? 0
        case .album:
            id = items.albums.first?.id ?? 0
        case .artist:
            id = items.artists.first?.id ?? 0
        case .playlist:
            id = items.playlists.first?.id ?? 0
        default:
            break
        }
        guard id > 0 else { return }
        let str = "https://music.163.com/\(type.rawValue)?id=\(id)"
        ViewControllerManager.shared.copyToPasteboard(str)
    }
    
    @IBAction func subscribe(_ sender: NetworkRequestMenuItem) {
        guard let d = delegate else { return }
        let pc = PlayCore.shared
        let items = d.selectedItems()
        let type = d.tableViewList()
        var id = 0
        
        switch type.contentType {
        case .artist:
            id = items.artists.first?.id ?? 0
        case .album:
            id = items.albums.first?.id ?? 0
        case .playlist:
            id = items.playlists.first?.id ?? 0
        default:
            break
        }
        guard id > 0 else { return }
        let unsubscribe = sender.tag == 1
        sender.requesting = true
        pc.api.subscribe(id, unsubscribe: unsubscribe, type: type.contentType).done {
            if type.contentType == .playlist {
                NotificationCenter.default.post(name: .initSidebarPlaylists, object: nil)
            }
            if type == d.tableViewList(),
                type.type == .mySubscription,
                unsubscribe {
                d.removeSuccess(ids: [id], newItem: nil)
            }
        }.ensure {
            sender.requesting = false
        }.catch {
            print($0)
        }
    }
    
    @IBAction func remove(_ sender: NetworkRequestMenuItem) {
        guard let d = delegate,
            d.selectedIndexs().count > 0 else { return }
        let list = d.tableViewList()
        let items = d.selectedItems()
        
        
        guard list.contentType == .song else { return }
        let playlistId = list.id
        let api = PlayCore.shared.api
        let vcm = ViewControllerManager.shared
        
        sender.requesting = true
        switch list.type {
        case .discoverPlaylist:
            guard let id = items.tracks.first?.id else { return }
            api.discoveryRecommendDislike(id).done {
                print("Remove \(id) from discoverPlaylist done.")
                guard let newTrack = $0.0,
                    d.tableViewList().type == .discover else { return }
                d.removeSuccess(ids: [id], newItem: newTrack)
            }.ensure {
                sender.requesting = false
            }.catch {
                if let er = ($0 as? NeteaseMusicAPI.RequestError) {
                    switch er {
                    case .errorCode(let code, let msg):
                        if code == 432, msg == "今日暂无更多推荐" {
                            vcm.displayMessage(msg)
                            return
                        }
                    default:
                        break
                    }
                }
                d.shouldReloadData()
                print("Remove \(id) from discoverPlaylist error \($0).")
            }
        case .fmTrash:
            guard let id = items.tracks.first?.id else { return }
            api.fmTrash(id: id, 0, false).done {
                print("FM Trash Delected \(id).")
                guard d.tableViewList().type == .fmTrash else { return }
                d.removeSuccess(ids: [id], newItem: nil)
            }.ensure {
                sender.requesting = false
            }.catch {
                d.shouldReloadData()
                print("FM Trash Del error: \($0).")
            }
        case .favourite, .createdPlaylist:
            let ids = items.tracks.map { $0.id }
            api.playlistTracks(add: false, ids, to: playlistId).done {
                guard list == d.tableViewList() else { return }
                d.removeSuccess(ids: ids, newItem: nil)
                print("Remove \(ids) from playlist \(playlistId) done.")
            }.ensure {
                sender.requesting = false
            }.catch {
                d.shouldReloadData()
                print("Remove \(ids) from playlist \(playlistId) error \($0).")
            }
        default:
            sender.requesting = false
            break
        }
    }
    
    @IBAction func newPlaylist(_ sender: NetworkRequestMenuItem) {
        guard let vc = newPlaylistViewController,
            let d = delegate else { return }
        d.presentNewPlaylist(vc)
    }
    
    @IBAction func menuItemAction(_ sender: NSMenuItem) {
        let playlistId = sender.tag
        guard let d = delegate,
            playlistId > 0,
            let tracks = delegate?.selectedItems().tracks else { return }
        let ids = tracks.map {
            $0.id
        }
        PlayCore.shared.api.playlistTracks(add: true, ids, to: playlistId).done {
            print("Add \(ids) to playlist \(playlistId) done.")
            guard playlistId == d.tableViewList().id else { return }
            switch d.tableViewList().type {
            case .createdPlaylist, .favourite:
                d.shouldReloadData()
            default:
                break
            }
        }.catch {
            print("Add \(ids) to playlist \(playlistId) error \($0).")
        }
    }
    
    private var playlistMenuUpdateID = ""
    
    lazy var newPlaylistViewController: NewPlaylistViewController? = {
        let sb = NSStoryboard(name: "NewPlaylist", bundle: nil)
        let vc = sb.instantiateController(withIdentifier: "NewPlaylistViewController") as? NewPlaylistViewController
        return vc
    }()
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let delegate = delegate else {
            return false
        }
        let selectedIndexs = delegate.selectedIndexs()
        let type = delegate.tableViewList().type
        
        // Playlist items
        if menuItem.tag != 0, selectedIndexs.count > 0 {
            return true
        }
        
        if let m = menuItem as? NetworkRequestMenuItem, m.requesting {
            return false
        }
        
        switch menuItem {
        case copyLinkMenuItem, subscribeMenuItem:
            return selectedIndexs.count == 1
        case playMenuItem, playNextMenuItem:
            return selectedIndexs.count > 0
        case removeMenuItem:
            switch type {
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
        guard let delegate = delegate, menu == self.menu else { return }
        
        let tableViewList = delegate.tableViewList()
        menu.items.forEach {
            if !$0.isSeparatorItem {
                $0.isHidden = !menuItemsToDisplay().contains($0)
            }
        }
        
        subscribeMenuItem.title = "Subscribe"
        subscribeMenuItem.tag = 0
        
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
                    if delegate.selectedItems().playlists.first?.id == i.element.id {
                        self.subscribeMenuItem.tag = 1
                        self.subscribeMenuItem.title = "Unsubscribe"
                    }
                    return nil
                }
                
                var name = i.element.name
                if i.offset == 0, name.contains("喜欢的音乐") {
                    name = "我喜欢的音乐"
                }
                let item = NSMenuItem(title: name,
                                      action: #selector(self.menuItemAction),
                                      keyEquivalent: "")
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
        
        switch tableViewList.type {
        case .discoverPlaylist:
            // switch to not interested
            removeMenuItem.title = "Not Interested"
        case .favourite, .createdPlaylist:
            removeMenuItem.title = "Remove from Playlist"
        case .fmTrash:
            removeMenuItem.title = "Restore"
        default:
            break
        }
    }
    
    func menuItemsToDisplay() -> [NSMenuItem] {
        guard let d = delegate else { return [] }
        let type = d.tableViewList().type
        let cType = d.tableViewList().contentType
        let albumItems: [NSMenuItem] = [playMenuItem, playNextMenuItem, copyLinkMenuItem, subscribeMenuItem]
        let songItems: [NSMenuItem] =  [playMenuItem, playNextMenuItem, copyLinkMenuItem, addToPlaylistMenuItem]
        let songItems2: [NSMenuItem] =  [playMenuItem, playNextMenuItem, copyLinkMenuItem, addToPlaylistMenuItem, removeMenuItem]
        switch type {
        case .discover:
            return []
        case .favourite:
            return songItems2
        case .discoverPlaylist:
            return songItems2
        case .album:
            return songItems
        case .artist:
            return []
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
            d.selectedIndexs().count > 0 else {
                return empty
        }
        let content = d.selectedItems()
        switch d.tableViewList().contentType {
        case .song:
            return Promise<[Track]> {
                $0.fulfill(content.tracks)
            }
        case .album:
            guard let id = content.albums.first?.id else {
                return empty
            }
            return pc.api.album(id).map {
                $0.songs
            }
        case .playlist:
            guard let id = content.playlists.first?.id else {
                return empty
            }
            return pc.api.playlistDetail(id).map {
                $0.tracks ?? []
            }
        default:
            return empty
        }
    }
}

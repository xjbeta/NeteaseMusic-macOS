//
//  TrackTableViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/12/11.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class TrackTableViewController: NSViewController {

    @IBOutlet weak var scrollView: UnresponsiveScrollView!
    @IBOutlet weak var tableView: NSTableView!
    
    @IBAction func doubleAction(_ sender: NSTableView) {
        let clickedRow = sender.clickedRow
        let ids = tracks.map { $0.id }
        if PlayCore.shared.playlist.map({ $0.id }) != ids {
            PlayCore.shared.playlist = tracks
        }
        
        PlayCore.shared.start(clickedRow)
    }
    
    
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
            if let t = tracks.enumerated().filter ({
                selectedIndexs.contains($0.offset)
            }).first?.element {
                let str = "https://music.163.com/song?id=\(t.id)"
                ViewControllerManager.shared.copyToPasteboard(str)
            }
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
            default:
                PlayCore.shared.api.playlistTracks(add: false, ids, to: playlistId).done {
                    print("Remove \(ids) from playlist \(playlistId) done.")
//                    self.initPlaylist(playlistId)
                    }.catch {
                        print("Remove \(ids) from playlist \(playlistId) error \($0).")
                }
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
    
    @objc dynamic var tracks = [Track]()
    var playlistId = -1
    var playlistType: SidebarViewController.ItemType = .none {
        didSet {
            initTableColumn()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.responsiveScrolling = true
        initTableColumn()
    }
    
    func initTableColumn() {
        let albumMode = playlistType == .album
        tableView.tableColumn(withIdentifier: .init("PlaylistAlbum"))?.isHidden = albumMode
        tableView.tableColumn(withIdentifier: .init("PlaylistPop"))?.isHidden = !albumMode
    }
    
    func resetData() {
        tracks.removeAll()
    }
}


extension TrackTableViewController: NSMenuItemValidation, NSMenuDelegate {
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

        switch playlistType {
        case .discoverPlaylist:
            // switch to not interested
            removeFromPlaylistMenuItem.title = "Not Interested"
        default:
            removeFromPlaylistMenuItem.title = "Remove from Playlist"
        }
    }
}

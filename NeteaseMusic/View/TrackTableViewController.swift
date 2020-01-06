//
//  TrackTableViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/12/11.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

protocol TrackTableViewDelegate {
    func trackTableView(_ tableView: NSTableView, startPlaying tracks: [Track], with track: Track?)
    func trackTableView(_ tableView: NSTableView, playNext tracks: [Track])
    func trackTableView(_ tableView: NSTableView, copyLink track: Track)
    func trackTableView(_ tableView: NSTableView, remove tracks: [Track], completionHandler: (() -> Void)?)
    func trackTableView(_ tableView: NSTableView, createPlaylist tracks: [Track], completionHandler: (() -> Void)?)
    func trackTableView(_ tableView: NSTableView, add tracks: [Track], to playlist: Int)
}

class TrackTableViewController: NSViewController {

    @IBOutlet weak var scrollView: UnresponsiveScrollView!
    @IBOutlet weak var tableView: NSTableView!
    
    @IBAction func doubleAction(_ sender: NSTableView) {
        let clickedRow = sender.clickedRow
        guard let t = tracks[safe: clickedRow] else { return }
        delegate?.trackTableView(tableView, startPlaying: tracks, with: t)
    }
    
// MARK: - Playlist Menu
    
    @IBOutlet var tableViewMenu: NSMenu!
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var playNextMenuItem: NSMenuItem!
    @IBOutlet weak var copyLinkMenuItem: NSMenuItem!
    @IBOutlet weak var removeFromPlaylistMenuItem: NetworkRequestMenuItem!
    @IBOutlet weak var newPlaylistMenuItem: NetworkRequestMenuItem!
    @IBOutlet weak var addToPlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var addToPlaylistMenu: NSMenu!
    
    @IBAction func menuItemAction(_ sender: NSMenuItem) {
        let selectedIndexs = tableView.selectedIndexs()
        let ts = tracks.enumerated().filter {
            selectedIndexs.contains($0.offset)
        }.map {
            $0.element
        }
        
        switch sender {
        case playMenuItem:
            delegate?.trackTableView(tableView, startPlaying: ts, with: nil)
        case playNextMenuItem:
            delegate?.trackTableView(tableView, playNext: ts)
        case copyLinkMenuItem:
            if let t = ts.first {
                delegate?.trackTableView(tableView, copyLink: t)
            }
        case removeFromPlaylistMenuItem:
            removeFromPlaylistMenuItem.requesting = true
            delegate?.trackTableView(tableView, remove: ts) {
                self.removeFromPlaylistMenuItem.requesting = false
            }
        case newPlaylistMenuItem:
            newPlaylistMenuItem.requesting = true
            delegate?.trackTableView(tableView, createPlaylist: ts) {
                self.newPlaylistMenuItem.requesting = false
            }
        default:
            let playlistId = sender.tag
            guard playlistId > 0 else { return }
            delegate?.trackTableView(tableView, add: ts, to: playlistId)
        }
    }
    
    private var playlistMenuUpdateID = ""
    var delegate: TrackTableViewDelegate?
    
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
    
    func initMenuItems() {
        var typeList = [SidebarViewController.ItemType]()
        
        playMenuItem.isHidden = playlistType == .fmTrash
        playNextMenuItem.isHidden = playlistType == .fmTrash
        copyLinkMenuItem.isHidden = false
        typeList = [.subscribedPlaylist, .album, .topSongs]
        removeFromPlaylistMenuItem.isHidden = typeList.contains(playlistType)
        addToPlaylistMenuItem.isHidden = playlistType == .fmTrash
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
        
        if let m = menuItem as? NetworkRequestMenuItem, m.requesting {
            return false
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

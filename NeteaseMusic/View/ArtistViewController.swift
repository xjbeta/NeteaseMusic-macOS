//
//  ArtistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/21.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class ArtistViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    var sidebarItemObserver: NSKeyValueObservation?
    
    struct Item {
        let artist: Track.Artist?
        let album: Track.Album?
        let type: ItemType
        enum ItemType {
            case artist, hotSongs, album
        }
        
        init(type: ItemType = .album,
             artist: Track.Artist? = nil,
             album: Track.Album? = nil) {
            self.type = type
            self.artist = artist
            self.album = album
        }
    }
    
    var id = -1
    var items = [Item]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.deselectAll(nil)
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { [weak self] core, changes in
            guard let new = changes.newValue,
                new?.type == .artist,
                let id = new?.id else { return }
            guard id != self?.id else { return }
            self?.initArtistView(id)
        }
    }
    
    func initArtistView(_ id: Int) {
        self.id = id
        PlayCore.shared.api.artistAlbums(id).done {
            guard id == self.id else { return }
            
            self.items.removeAll()
            self.items.append(Item(type: .artist, artist: $0.artist))
            self.items.append(Item(type: .hotSongs))
            self.items.append(contentsOf: $0.hotAlbums.map({Item(album: $0)}))
            
            self.tableView.reloadData()
            }.catch {
                print($0)
        }
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}


extension ArtistViewController: NSTableViewDelegate, NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return row != 0
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return row == 0 ? 240 : 80
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row == 0 {
            return tableView.makeView(withIdentifier: .init("ArtistInfoTableCellView"), owner: nil)
        } else {
            return tableView.makeView(withIdentifier: .init("AlbumInfoTableCellView"), owner: nil)
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let item = items[safe: row] else { return nil }
        switch item.type {
        case .artist:
            guard let artist = item.artist,
                let image = NSImage(named: .init("user_150")) else { return nil }
            return ["name": artist.name,
                    "alias": artist.alias?.joined(separator: "; ") ?? "",
                    "albumSize": artist.albumSize ?? 0,
                    "musicSize": artist.musicSize ?? 0,
                    "image": artist.cover ?? image]
        case .hotSongs:
            guard let image = NSImage(named: .init("calendar_bg")) else { return nil }
            return ["image": image,
                    "name": "hot songs",
                    "size": 50,
                    "publishTime": "none"]
            
        case .album:
            guard let album = item.album,
                let image = NSImage(named: .init("calendar_bg")) else { return nil }
            return ["image": album.cover ?? image,
                    "name": album.name,
                    "size": album.size,
                    "publishTime": album.publishTime]
        }
    }
}

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
    
    @IBAction func tableViewClick(_ sender: Any) {
        guard let item = items[safe: tableView.selectedRow] else { return }
        tableView.deselectAll(nil)
        switch item.type {
        case .topSongs:
            guard let id = item.artist?.id else { return }
            ViewControllerManager.shared.selectSidebarItem(.topSongs, id)
        case .album:
            guard let id = item.album?.id else { return }
            ViewControllerManager.shared.selectSidebarItem(.album, id)
        default:
            break
        }
    }
    
    struct Item {
        let artist: Track.Artist?
        let album: Track.Album?
        let type: ItemType
        enum ItemType {
            case artist, topSongs, album
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
            self.items.append(Item(type: .topSongs, artist: $0.artist))
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
        guard let item = items[safe: row] else { return nil }
        var view: NSTableCellView? = nil
        switch item.type {
        case .artist:
            view = tableView.makeView(withIdentifier: .init("ArtistInfoTableCellView"), owner: nil) as? NSTableCellView
            view?.imageView?.setImage(item.artist?.picUrl?.absoluteString ?? "", true)
        case .topSongs:
            view = tableView.makeView(withIdentifier: .init("AlbumInfoTableCellView"), owner: nil) as? NSTableCellView
            view?.imageView?.image = NSImage(named: .init("cover_top50"))
        case .album:
            view = tableView.makeView(withIdentifier: .init("AlbumInfoTableCellView"), owner: nil) as? NSTableCellView
            view?.imageView?.setImage(item.album?.picUrl?.absoluteString ?? "", true)
        }
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let item = items[safe: row] else { return nil }
        switch item.type {
        case .artist:
            guard let artist = item.artist else { return nil }
            return ["name": artist.name,
                    "alias": artist.alias?.joined(separator: "; ") ?? "",
                    "albumSize": artist.albumSize ?? 0,
                    "musicSize": artist.musicSize ?? 0]
        case .topSongs:
            return ["name": "top songs",
                    "size": 50,
                    "publishTime": "none"]
        case .album:
            guard let album = item.album else { return nil }
            return ["name": album.name,
                    "size": album.size,
                    "publishTime": album.publishTime]
        }
    }
}

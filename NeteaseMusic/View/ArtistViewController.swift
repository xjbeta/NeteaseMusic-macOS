//
//  ArtistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/21.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

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
    
    @IBAction func subscribe(_ sender: SubscribeButton) {
        sender.isEnabled = false
        let api = PlayCore.shared.api
        api.subscribe(id, unSubscribe: subscribed, type: .artist).done(on: .main) {
            self.subscribed = !self.subscribed
            self.tableView.reloadData(forRowIndexes: .init(integer: 0), columnIndexes: .init(integer: 0))
        }.ensure(on: .main) {
            sender.isEnabled = true
        }.catch {
            print($0)
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
    var subscribed = false
    
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
        let api = PlayCore.shared.api
        items.removeAll()
        tableView.reloadData()
        when(fulfilled: api.artistAlbums(id), api.artistSublist()).done(on: .main) {
            guard id == self.id else { return }
            let aA = $0.0
            
            self.subscribed = $0.1.map {
                $0.id
            }.contains(aA.artist.id)
            
            self.items.append(Item(type: .artist, artist: aA.artist))
            self.items.append(Item(type: .topSongs, artist: aA.artist))
            self.items.append(contentsOf: aA.hotAlbums.map({Item(album: $0)}))
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
            view?.imageView?.setImage(item.artist?.picUrl, true)
            let t = view?.subviews.compactMap {
                $0 as? SubscribeButton
                }.first
            t?.subscribed = subscribed
        case .topSongs:
            view = tableView.makeView(withIdentifier: .init("AlbumInfoTableCellView"), owner: nil) as? NSTableCellView
            view?.imageView?.image = NSImage(named: .init("cover_top50"))
        case .album:
            view = tableView.makeView(withIdentifier: .init("AlbumInfoTableCellView"), owner: nil) as? NSTableCellView
            view?.imageView?.setImage(item.album?.picUrl?.absoluteString, true)
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

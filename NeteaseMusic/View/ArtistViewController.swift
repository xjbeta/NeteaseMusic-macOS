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
    var id = -1
    
    @objc dynamic var albums = [Track.Album]()
    @objc dynamic var artist: Track.Artist?
    
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
            self.albums = $0.hotAlbums
            self.artist = $0.artist
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
        return albums.count + 1
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
        
        if row == 0 {
            guard let artist = artist,
                let image = NSImage(named: .init("user_150")) else { return nil }
            return ["name": artist.name,
                    "alias": artist.alias?.joined(separator: "; ") ?? "",
                    "albumSize": artist.albumSize ?? 0,
                    "musicSize": artist.musicSize ?? 0,
                    "image": artist.cover ?? image]
        } else {
            return albums[safe: row - 1]
        }
    }
}

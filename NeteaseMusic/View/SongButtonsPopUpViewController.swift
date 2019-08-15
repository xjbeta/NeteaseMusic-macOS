//
//  SongButtonsPopUpViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/8/10.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SongButtonsPopUpViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    
    @IBAction func selected(_ sender: NSTableView) {
        guard let playlistId = playlists[safe: tableView.selectedRow]?.id else { return }
        
        PlayCore.shared.api.playlistTracks(add: true, [trackId], to: playlistId).done {
            print("Added song: \(self.trackId) to playlist: \(playlistId).")
            }.catch {
                print($0)
        }
        dismiss(self)
    }
    
    var playlists = [Playlist]()
    var complete: ((Int) -> Void)?
    var trackId = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func loadPlaylists() {
        PlayCore.shared.api.userPlaylist().done(on: .main) { [weak self] in
            self?.playlists = $0
            self?.tableView.reloadData()
            }.catch {
                print("Load user playlist error: \($0).")
        }
    }
}

extension SongButtonsPopUpViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return playlists.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let item = playlists[safe: row] else { return nil }
        let view = tableView.makeView(withIdentifier: .init("SongButtonsPopUpTableCellView"), owner: nil) as? NSTableCellView
        view?.imageView?.setImage(item.coverImgUrl.absoluteString, true)
        return view
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let item = playlists[safe: row] else { return nil }
        
        return ["name": item.name,
                "songCount": "\(item.trackCount) songs"]
    }
}

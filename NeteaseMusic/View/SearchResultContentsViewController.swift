//
//  SearchSongsResultViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/6.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SearchResultContentsViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    var songs = [Track]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func reloadTableView() {
        tableView.reloadData()
    }
}

extension SearchResultContentsViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let song = songs[safe: row] else { return nil }
        
        return ["index": song.index,
                "name": song.name,
                "artist": song.artists.artistsString(),
                "album": song.album.name,
                "time": song.duration]
    }
}


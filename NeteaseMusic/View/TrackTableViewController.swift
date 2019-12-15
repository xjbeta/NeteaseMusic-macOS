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
    
    @IBAction func tableViewDoubleAction(_ sender: NSTableView) {
        let row = sender.clickedRow
        guard let t = songs[safe: row] else { return }
        PlayCore.shared.playNow([t])
    }
    var songs = [Track]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.responsiveScrolling = false
    }
    
    func resetData() {
        songs.removeAll()
        tableView.reloadData()
    }
}

extension TrackTableViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 25
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



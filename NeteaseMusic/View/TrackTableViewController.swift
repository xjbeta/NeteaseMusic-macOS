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

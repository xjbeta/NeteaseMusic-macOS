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
        guard let track = tracks[safe: clickedRow] else { return }
        let pc = PlayCore.shared
        pc.playlist = tracks
        pc.start(tracks, id: track.id)
    }
    
    @objc dynamic var tracks = [Track]() {
        didSet {
            initCurrentTrack()
        }
    }
    var playlistId = -1
    var playlistType: SidebarViewController.ItemType = .none {
        didSet {
            initTableColumn()
        }
    }
    
    var currentTrackObserver: NSKeyValueObservation?
    var playerStateObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.responsiveScrolling = true
        initTableColumn()
        initObservers()
    }
    
    func initObservers() {
        currentTrackObserver?.invalidate()
        playerStateObserver?.invalidate()
        currentTrackObserver = PlayCore.shared.observe(\.currentTrack, options: [.new, .initial]) { (pc, _) in
            self.initCurrentTrack()
        }
        
        playerStateObserver =  PlayCore.shared.player.observe(\.timeControlStatus, options: [.new, .initial]) { (pc, _) in
            let pc = PlayCore.shared
            self.tracks.first {
                $0.isCurrentTrack
                }?.isPlaying = pc.player.timeControlStatus == .playing
        }
    }
    
    func initCurrentTrack() {
        let pc = PlayCore.shared
        tracks.filter {
            $0.isCurrentTrack
        }.forEach {
            $0.isCurrentTrack = false
        }
        
        guard let c = pc.currentTrack else { return }

        let t = tracks.first {
            $0.from == c.from && $0.id == c.id
        }
        t?.isCurrentTrack = true
        t?.isPlaying = pc.player.timeControlStatus == .playing
    }
    
    func initTableColumn() {
        let albumMode = playlistType == .album
        tableView.tableColumn(withIdentifier: .init("PlaylistAlbum"))?.isHidden = albumMode
        tableView.tableColumn(withIdentifier: .init("PlaylistPop"))?.isHidden = !albumMode
    }
    
    func resetData() {
        tracks.removeAll()
    }
    
    deinit {
        currentTrackObserver?.invalidate()
        playerStateObserver?.invalidate()
    }
    
}

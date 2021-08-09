//
//  SidePlaylistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/12.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SidePlaylistViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var playlistArrayController: NSArrayController!
    @objc dynamic var playlist = [Track]()
    @IBOutlet weak var songsCountTextField: NSTextField!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    
    @IBAction func segmentedControlAction(_ sender: NSSegmentedControl) {
        initObservers()
    }
    
    @IBAction func empty(_ sender: NSButton) {
        switch segmentedControl.selectedSegment {
        case 0:
            // Playlist
            PlayCore.shared.playlist.removeAll()
        case 1:
            // History
            PlayCore.shared.historys.removeAll()
        default:
            break
        }
    }
    
    lazy var menuContainer: (menu: NSMenu?, menuController: TAAPMenuController?) = {
        var objects: NSArray?
        Bundle.main.loadNibNamed(.init("TAAPMenu"), owner: nil, topLevelObjects: &objects)
        let mc = objects?.compactMap {
            $0 as? TAAPMenuController
        }.first
        let m = objects?.compactMap {
            $0 as? NSMenu
        }.first
        return (m, mc)
    }()
    
    var playlistObserver: NSKeyValueObservation?
    var historysObserver: NSKeyValueObservation?
    
    var currentTrackObserver: NSKeyValueObservation?
    var playerStateObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.menu = menuContainer.menu
        menuContainer.menuController?.delegate = self
        initObservers()
    }
    
    func initObservers() {
        playlistObserver?.invalidate()
        historysObserver?.invalidate()
        currentTrackObserver?.invalidate()
        playerStateObserver?.invalidate()
        playlist.removeAll()
        switch segmentedControl.selectedSegment {
        case 0:
            // Playlist
            playlistObserver = PlayCore.shared.observe(\.playlist, options: [.initial, .new]) { [weak self] core, _ in
                self?.playlist = core.playlist
                
                self?.updateSongsCount()
            }
        case 1:
            // History
            historysObserver = PlayCore.shared.observe(\.historys, options: [.initial, .new]) { [weak self] core, _ in
                self?.playlist = core.historys.reversed()
                
                self?.updateSongsCount()
            }
        default:
            break
        }
        
        currentTrackObserver = PlayCore.shared.observe(\.currentTrack, options: [.new, .initial]) { (pc, _) in
            
            self.playlist.filter {
                $0.isCurrentTrack
            }.forEach {
                $0.isCurrentTrack = false
            }
            
            guard let c = pc.currentTrack else { return }
            self.playlist.first {
                $0.from == c.from && $0.id == c.id
                }?.isCurrentTrack = true
        }
        
        playerStateObserver =  PlayCore.shared.observe(\.playerState, options: [.new, .initial]) { (pc, _) in
            let pc = PlayCore.shared
            self.playlist.first {
                $0.isCurrentTrack
            }?.isPlaying = pc.player.isPlaying()
        }
    }
    
    func updateSongsCount() {
        songsCountTextField.stringValue = "\(playlist.count) Songs"
    }
    
    deinit {
        playlistObserver?.invalidate()
        historysObserver?.invalidate()
        currentTrackObserver?.invalidate()
        playerStateObserver?.invalidate()
    }
}

extension SidePlaylistViewController: TAAPMenuDelegate {
    func selectedItems() -> (id: [Int], items: [Any]) {
        let items = playlist.enumerated().filter {
            tableView.selectedIndexs().contains($0.offset)
        }.map {
            $0.element
        }
        return (items.map({ $0.id }), items)
    }
    
    func tableViewList() -> (type: SidebarViewController.ItemType, id: Int, contentType: TAAPItemsType) {
        return (.sidePlaylist, 0, .song)
    }
    
    func removeSuccess(ids: [Int], newItem: Any?) {
        PlayCore.shared.playlist = PlayCore.shared.playlist.filter {
            !ids.contains($0.id)
        }
    }
    
    func shouldReloadData() {
        tableView.reloadData()
    }
    
    func presentNewPlaylist(_ newPlaylisyVC: NewPlaylistViewController) {
        return
    }
}

//
//  SidePlaylistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/12.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SidePlaylistViewController: NSViewController {

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
    
    var playlistObserver: NSKeyValueObservation?
    var historysObserver: NSKeyValueObservation?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        initObservers()
    }
    
    func initObservers() {
        playlistObserver?.invalidate()
        historysObserver?.invalidate()
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
    }
    
    func updateSongsCount() {
        songsCountTextField.stringValue = "\(playlist.count) Songs"
    }
    
    deinit {
        playlistObserver?.invalidate()
        historysObserver?.invalidate()
    }
}

//
//  SidePlaylistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/12.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SidePlaylistViewController: NSViewController {

    @IBOutlet var playlistMenu: NSMenu!
    
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var playNextMenuItem: NSMenuItem!
    @IBOutlet weak var copyLinkMenuItem: NSMenuItem!
    @IBOutlet weak var removeMenuItem: NSMenuItem!
    
    @IBAction func menuItemAction(_ sender: NSMenuItem) {
        let indexs = tableView.selectedIndexs()
        
        switch sender {
        case playMenuItem:
            break
        case playNextMenuItem:
            break
        case copyLinkMenuItem:
            if let t = playlist.enumerated().filter ({
                indexs.contains($0.offset)
            }).first?.element {
                let str = "https://music.163.com/song?id=\(t.id)"
                ViewControllerManager.shared.copyToPasteboard(str)
            }
        case removeMenuItem:
            let offsets = playlist.enumerated().filter ({
                indexs.contains($0.offset)
            }).map({ $0.offset })
            PlayCore.shared.playlist = PlayCore.shared.playlist.enumerated().filter {
                !offsets.contains($0.offset)
                }.map {
                    $0.element
            }
        default:
            break
        }
    }
    
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

extension SidePlaylistViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let indexs = tableView.selectedIndexs()
        switch menuItem {
        case playMenuItem:
//            return indexs.count > 0
            return false
        case playNextMenuItem:
//            return indexs.count > 0
            return false
        case copyLinkMenuItem:
            return indexs.count == 1
        case removeMenuItem:
            return indexs.count > 0
        default:
            break
        }
        return false
    }
}

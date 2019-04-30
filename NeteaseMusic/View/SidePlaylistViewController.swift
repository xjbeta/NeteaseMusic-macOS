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
    
    var ttt: NSKeyValueObservation?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        ttt = PlayCore.shared.observe(\.playlist, options: [.initial, .new]) { [weak self] core, _ in
            self?.playlist = core.playlist
        }
        
    }
    
    
    deinit {
        ttt?.invalidate()
    }
}

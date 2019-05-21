//
//  ArtistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/21.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class ArtistViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    var sidebarItemObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { [weak self] core, changes in
            guard let new = changes.newValue,
                new?.type == .artist,
                let id = new?.id else { return }
            print("Artist ID: \(id)")
        }
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}


extension ArtistViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return 10
    }
    
    
    
    
    
}

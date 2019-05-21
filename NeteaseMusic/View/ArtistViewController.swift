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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}


extension ArtistViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return 10
    }
    
    
    
    
    
}

//
//  SongButtonsViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/7/21.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SongButtonsViewController: NSViewController {
    @IBOutlet weak var loveButton: NSButton!
    @IBOutlet weak var favouriteButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var linkButton: NSButton!
    
    @IBAction func buttonsAction(_ sender: NSButton) {
        
    }
    
    var songId = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

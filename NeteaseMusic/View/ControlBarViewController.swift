//
//  ControlBarViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/10.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class ControlBarViewController: NSViewController {

    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var pauseButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    
    @IBAction func controlAction(_ sender: NSButton) {
        switch sender {
        case previousButton:
            break
        case pauseButton:
            guard PlayCore.shared.player.error == nil else { return }
            if PlayCore.shared.player.rate == 0 {
                PlayCore.shared.player.play()
            } else {
                PlayCore.shared.player.pause()
            }
        case nextButton:
            break
        default:
            break
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

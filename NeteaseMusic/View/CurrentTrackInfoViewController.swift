//
//  CurrentTrackInfoViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/15.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class CurrentTrackInfoViewController: NSViewController {

    @IBOutlet weak var imageButton: NSButton!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var artistTextField: NSTextField!
    
    var currentTrackObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageButton.wantsLayer = true
        imageButton.layer?.cornerRadius = 4
        
        
        currentTrackObserver = PlayCore.shared.observe(\.currentTrack, options: [.initial, .new]) { [weak self] (playCore, changes) in
            if let urlStr = playCore.currentTrack?.al.picUrl?.absoluteString,
                let u = URL(string: urlStr.replacingOccurrences(of: "http://", with: "https://")),
                let image = NSImage(contentsOf: u) {
                self?.imageButton.image = image
            } else {
                self?.imageButton.image = nil
            }
            
            
            self?.nameTextField.stringValue = playCore.currentTrack?.name ?? ""
            self?.artistTextField.stringValue = playCore.currentTrack?.ar.artistsString() ?? ""
        }
    }
    
    deinit {
        currentTrackObserver?.invalidate()
    }
    
}

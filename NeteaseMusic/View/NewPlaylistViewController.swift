//
//  NewPlaylistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/8/22.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class NewPlaylistViewController: NSViewController {

    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var privacyButton: NSButton!
    @IBAction func cancel(_ sender: Any) {
        dismiss(self)
    }
    
    @IBAction func create(_ sender: Any) {
        let str = textField.stringValue
        guard str.count > 0 else { return }
        let privacy = privacyButton.state == .on
        PlayCore.shared.api.playlistCreate(str, privacy: privacy).done(on: .main) {
            print("Playlist created with name \(str)")
            self.updateSidebarItems?()
            self.textField.stringValue = ""
            self.dismiss(self)
            }.catch {
                print("Playlist create error \($0)")
        }
    }
    
    var updateSidebarItems: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

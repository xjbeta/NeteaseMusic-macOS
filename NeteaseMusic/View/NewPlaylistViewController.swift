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
            NotificationCenter.default.post(name: .reloadSidebarData, object: nil)
            self.textField.stringValue = ""
            self.dismiss(self)
            }.catch {
                ViewControllerManager.shared.displayMessage("Create new playlist failed.")
                print("Playlist create error \($0)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

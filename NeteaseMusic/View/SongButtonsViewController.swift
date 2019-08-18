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
    @IBOutlet weak var moreButton: NSButton!
    @IBOutlet var moreMenu: NSMenu!
    
    @IBAction func buttonsAction(_ sender: NSButton) {
        let id = trackId
        guard id > 0 else { return }
        let api = PlayCore.shared.api
        let seconds = PlayCore.shared.player.currentTime().seconds
        let time = seconds.isNaN ? 25 : Int(seconds)
        switch sender {
        case loveButton:
            let t = "check like status."
            let loved = self.loved
            api.like(id, !loved, time).done(on: .main) {
                print("\(loved ? "unlike" : "like") \(id) done.")
                PlayCore.shared.fmPlaylist.filter {
                    $0.id == id
                    }.forEach {
                        $0.loved = !loved
                }
                let name = loved ? "icon.sp#icn-fm_love" : "icon.sp#icn-fm_loved"
                self.loveButton.image = NSImage(named: .init(name))
                }.catch {
                    print($0)
            }
        case deleteButton:
            api.fmTrash(id: id, time).done {
                print("fmTrash \(id) done.")
                PlayCore.shared.fmPlaylist.removeAll {
                    $0.id == id
                }
                let t = "Update fm playlist"
                }.catch {
                    print($0)
            }
        case moreButton:
            if let event = NSApp.currentEvent {
                NSMenu.popUpContextMenu(moreMenu, with: event, for: sender)
            }
        default:
            break
        }
    }
    
    var trackId = -1
    var loved: Bool {
        get {
            let t = "Playing song?"
            return PlayCore.shared.fmPlaylist.filter {
                $0.id == trackId
                }.first?.loved ?? false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? SongButtonsPopUpViewController {
            vc.loadPlaylists()
            vc.trackId = trackId
        }
    }
    
    @IBAction func copyLink(_ sender: Any) {
        let str = "https://music.163.com/song?id=\(trackId)"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([str as NSString])
    }
    
    @IBAction func trash(_ sender: Any) {
        ViewControllerManager.shared.selectSidebarItem(.fmTrash)
    }
    
}

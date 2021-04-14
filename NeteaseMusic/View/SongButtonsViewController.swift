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
    @IBOutlet weak var moreButton: NSButton!
    @IBOutlet var moreMenu: NSMenu!
    
    @IBAction func buttonsAction(_ sender: NSButton) {
        let id = trackId
        guard id > 0 else { return }
        let seconds = PlayCore.shared.player.currentTime().seconds
        let time = seconds.isNaN ? 25 : Int(seconds)
        switch sender {
        case loveButton:
            loveButton.isEnabled = false
            let loved = self.loved
            pc.api.like(id, !loved, time).done {
                self.checkLikeList()
            }.catch {
                print($0)
            }
        case deleteButton:
            deleteButton.isEnabled = false
            pc.api.fmTrash(id: id, time).done {
                let index = self.pc.fmPlaylist.enumerated().first {
                    $0.element.id == id
                }?.offset
                guard let i = index else { return }
                self.pc.fmPlaylist.remove(at: i)
                self.pc.currentFMTrack = self.pc.fmPlaylist[safe: i]
                
                if self.pc.fmMode {
                    self.pc.start([], enterFMMode: true)
                }
                print("fmTrash \(id) done.")
            }.ensure(on: .main) {
                self.deleteButton.isEnabled = true
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
    
    let pc = PlayCore.shared
    var trackId = -1 {
        didSet {
            loveButton.isEnabled = false
            checkLikeList()
        }
    }
    
    var loved = false {
        didSet {
            let name = loved ? "icon.sp#icn-fm_loved" : "icon.sp#icn-fm_love"
            loveButton.image = NSImage(named: .init(name))
        }
    }
    
    var isFMView = true {
        didSet {
            deleteButton.isHidden = !isFMView
            moreButton.isHidden = !isFMView
            linkButton.isHidden = isFMView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func checkLikeList() {
        let id = trackId
        self.loved = false
        pc.api.likeList().done(on: .main) {
            guard id == self.trackId else { return }
            self.loved = $0.contains(id)
        }.ensure(on: .main) {
            self.loveButton.isEnabled = true
        }.catch {
            print($0)
        }
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

//
//  PlaylistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PlaylistViewController: NSViewController {

    @IBOutlet weak var playAllButton: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var coverImageView: NSImageView!
    @IBOutlet weak var titleTextFiled: NSTextField!
    
    @IBOutlet weak var playCountTextField: NSTextField!
    @IBOutlet weak var trackCountTextField: NSTextField!
    @IBOutlet weak var descriptionTextField: NSTextField!
    
    @IBAction func playPlaylist(_ sender: Any) {
        let addTracks = tracks
        let ids = addTracks.map { $0.id }
        let clickedRow = tableView.clickedRow
        if PlayCore.shared.playlist.map({ $0.id }) == ids {
            if (sender as? NSButton) == playAllButton {
                PlayCore.shared.start()
            } else if (sender as? NSTableView) == tableView {
                PlayCore.shared.start(clickedRow)
            }
            return
        }
        
        PlayCore.shared.playlist = addTracks
        PlayCore.shared.api.songUrl(ids).done { [weak self] songs in
            guard PlayCore.shared.playlist == addTracks,
                songs.count == PlayCore.shared.playlist.count else { return }
            
            PlayCore.shared.playlist.enumerated().forEach { obj in
                PlayCore.shared.playlist[obj.offset].song = songs.first {
                    $0.id == obj.element.id
                }
            }
            
            if (sender as? NSButton) == self?.playAllButton {
                PlayCore.shared.start()
            } else if (sender as? NSTableView) == self?.tableView {
                PlayCore.shared.start(clickedRow)
            }
            }.catch {
                print($0)
        }
    }
    
    @IBOutlet weak var topViewLayoutConstraint: NSLayoutConstraint!
//    var isUpdateLayout = false
    
    var sidebarItemObserver: NSKeyValueObservation?
    @objc dynamic var tracks = [Playlist.Track]()
    var playlistId = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coverImageView.wantsLayer = true
        coverImageView.layer?.cornerRadius = 6
        coverImageView.layer?.borderWidth = 0.5
        coverImageView.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        
        
        sidebarItemObserver = PlayCore.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { core, changes in
            guard let new = changes.newValue,
                new?.type == .playlist || new?.type == .favourite,
                let id = new?.id,
                id > 0 else { return }
            self.playlistId = id
            PlayCore.shared.api.playlistDetail(id).done(on: .main) {
                guard self.playlistId == id else { return }
                
                self.coverImageView.image = NSImage(contentsOf: $0.coverImgUrl)
                self.titleTextFiled.stringValue = $0.name
                self.descriptionTextField.stringValue = $0.description ?? "none"
                self.playCountTextField.integerValue = $0.playCount
                self.trackCountTextField.integerValue = $0.trackCount
                self.tracks = $0.tracks ?? []
                }.catch {
                    print($0)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(scrollViewDidScroll(_:)), name: NSScrollView.didLiveScrollNotification, object: tableView.enclosingScrollView)
    }
    
    @objc func scrollViewDidScroll(_ notification: Notification) {
        if let scrollView = notification.object as? NSScrollView {
            let visibleRect = scrollView.contentView.documentVisibleRect
//            self.topViewLayoutConstraint.constant = visibleRect.origin.y > 100 ? 100 : 200
//            isUpdateLayout = true
//            NSAnimationContext.runAnimationGroup({
//                $0.duration = 0.15
//                self.topViewLayoutConstraint.animator().constant = visibleRect.origin.y > 100 ? 100 : 200
//                isUpdateLayout = false
//            })
            
        }
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}

extension PlaylistViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return 10
    }
    
    
    
}

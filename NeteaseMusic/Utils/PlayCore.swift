//
//  PlayCore.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/31.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import AVFoundation

class PlayCore: NSObject {
    static let shared = PlayCore()
    
    private override init() {
        
    }
    
    let api = NeteaseMusicAPI()
    let player = AVPlayer()
    
    @objc dynamic var selectedSidebarItem: SidebarViewController.TableViewItem? = nil
    @objc dynamic var playlist: [Playlist.Track] = []
    
    
    func playUrl(_ url: URL) {
        let uStr = url.absoluteString.replacingOccurrences(of: "http://", with: "https://")
        guard let u = URL(string: uStr) else { return }
        let avAsset = AVURLAsset(url: u)
        let playerItem = AVPlayerItem(asset: avAsset)
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }
    
}

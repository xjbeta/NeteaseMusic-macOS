//
//  FMViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import AVFoundation

class FMViewController: NSViewController {

    @IBOutlet weak var prevImageButton: NSButton!
    @IBOutlet weak var coverImageView: NSImageView!
    @IBOutlet weak var playButton: NSButton!
    
    @IBAction func buttonAction(_ sender: NSButton) {
        let player = PlayCore.shared.player
        switch sender {
        case playButton:
            guard player.error == nil else { return }
            if PlayCore.shared.fmMode {
                if player.rate == 0 {
                    player.play()
                } else {
                    player.pause()
                }
            } else {
                PlayCore.shared.start(enterFMMode: true)
            }
        case prevImageButton:
            PlayCore.shared.previousSong()
        default:
            break
        }
    }
    
    var currentTrackObserver: NSKeyValueObservation?
    var playerStatueObserver: NSKeyValueObservation?
    var playListObserver: NSKeyValueObservation?
    var fmModeObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePlayButton(true)
        
//        playButton.wantsLayer = true
//        playButton.layer?.cornerRadius = playButton.frame.width / 2
//        playButton.layer?.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0.35)
        
        
        
        playListObserver = PlayCore.shared.observe(\.fmPlaylist, options: [.old, .new]) { [weak self] playcore, changes in
            print(changes)
            
            if changes.oldValue?.count == 0,
                let tracksCount = changes.newValue?.count,
                tracksCount > 0 {
                // fmPlayList inited
                playcore.currentFMTrack = changes.newValue?.first
                self?.initView()
            }
        }
        
        currentTrackObserver = PlayCore.shared.observe(\.currentFMTrack, options: [.initial, .new]) { [weak self] playcore, _ in
            guard playcore.fmMode else { return }
            print("currentFMTrack changed")
            self?.lyricViewController()?.currentLyricId = playcore.currentFMTrack?.id ?? -1
            self?.initView()
            
            if let track = playcore.currentFMTrack,
                let index = playcore.fmPlaylist.firstIndex(of: track),
                (playcore.fmPlaylist.count - index) <= 2 {
                self?.loadFMTracks()
            }
        }
        
        playerStatueObserver = PlayCore.shared.player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] (player, changes) in
            guard PlayCore.shared.fmMode else { return }
            self?.updateCoverButtonStatus(player.timeControlStatus)
        }
        
        fmModeObserver = PlayCore.shared.observe(\.fmMode, options: [.initial, .new]) { [weak self] (playcore, _) in
            guard let vc = self?.lyricViewController() else { return }
            if playcore.fmMode {
                self?.updateCoverButtonStatus(playcore.player.timeControlStatus)
                vc.addPeriodicTimeObserver(playcore.player)
            } else {
                self?.updateCoverButtonStatus(.paused)
                vc.removePeriodicTimeObserver(playcore.player)
            }
        }
        
        PlayCore.shared.fmPlaylist.removeAll()
        loadFMTracks()
    }
    
    func loadFMTracks() {
        PlayCore.shared.api.radioGet().done {
            PlayCore.shared.fmPlaylist.append(contentsOf: $0)
            }.catch {
                print($0)
        }
    }
    
    func initView() {
        prevImageButton.image = nil
        prevImageButton.isHidden = true
        let playlist = PlayCore.shared.fmPlaylist
        guard let track = PlayCore.shared.currentFMTrack else {
            lyricViewController()?.currentLyricId = -1
            return
        }
        
        songInfoViewController()?.initInfos(track)
        
        guard let index = playlist.firstIndex(of: track) else { return }

        coverImageView.setImage(track.album.picUrl?.absoluteString ?? "", true)
        lyricViewController()?.currentLyricId = track.id
        
        if let track = playlist[safe: index - 1] {
            prevImageButton.isHidden = false
            prevImageButton.image = track.album.cover
        }
        
        if index > 1 {
            PlayCore.shared.fmPlaylist.removeSubrange(0..<(index - 1))
        }
    }
    
    func updateCoverButtonStatus(_ status: AVPlayer.TimeControlStatus) {
        guard PlayCore.shared.fmMode else {
            updatePlayButton(true)
            return
        }
        switch status {
        case .paused:
            updatePlayButton(true)
        case .playing:
            updatePlayButton(false)
        case .waitingToPlayAtSpecifiedRate:
            break
        }
    }
    
    func updatePlayButton(_ paused: Bool) {
        playButton.image = paused ? NSImage(named: .init("btmbar.sp#icn-play")): NSImage(named: .init("btmbar.sp#icn-pause"))
    }
    
    func lyricViewController() -> LyricViewController? {
        let lyricVC = children.compactMap {
            $0 as? LyricViewController
            }.first
        return lyricVC
    }
    
    func songInfoViewController() -> SongInfoViewController? {
        let songInfoVC = children.compactMap {
            $0 as? SongInfoViewController
            }.first
        return songInfoVC
    }
    
    deinit {
        lyricViewController()?.removePeriodicTimeObserver(PlayCore.shared.player)
        currentTrackObserver?.invalidate()
        playerStatueObserver?.invalidate()
        playListObserver?.invalidate()
        fmModeObserver?.invalidate()
    }
}

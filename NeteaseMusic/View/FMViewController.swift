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
    @IBOutlet weak var ppImageView: NSImageView!
    @IBOutlet weak var ppImageSizeLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var ppImageLeadingLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var prevImageButton: NSButton!
    @IBOutlet weak var prevButtonSizeLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var prevButtonLeadingLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var coverImageView: NSImageView!
    @IBOutlet weak var coverImageSizeLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageLeadingLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var nextImageView: CoverImageView!
    @IBOutlet weak var nextImageLeadingLayoutConstraint: NSLayoutConstraint!
    
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
    var fmModeObserver: NSKeyValueObservation?
    
    var imageViewsFrames = [NSRect]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePlayButton(true)
        
        imageViewsFrames.append(nextImageView.frame)
        imageViewsFrames.append(coverImageView.frame)
        imageViewsFrames.append(prevImageButton.frame)
        imageViewsFrames.append(ppImageView.frame)
        
        currentTrackObserver = PlayCore.shared.observe(\.currentFMTrack, options: [.initial, .new, .old]) { [weak self] playcore, changes in
            guard playcore.fmMode else { return }
            print("currentFMTrack changed \(changes).")
            if let oldTrack = changes.oldValue,
                let newTrack = changes.newValue,
                let old = oldTrack,
                let new = newTrack {
                
                var oldI = -1
                var newI = -1
                playcore.fmPlaylist.enumerated().forEach {
                    if $0.element == old {
                        oldI = $0.offset
                    } else if $0.element == new {
                        newI = $0.offset
                    }
                }
                guard oldI != -1, newI != -1 else { return }
                
                print(oldI, newI)
                
                DispatchQueue.main.async {
                    if newI > oldI {
                        self?.nextTrackAnimation {
                            self?.initView()
                        }
                    } else if newI < oldI {
                        self?.prevTrackAnimation {
                            self?.initView()
                        }
                    } else {
                        self?.initView()
                    }
                }
            }
            
            // Load more fm tracks
            if let track = playcore.currentFMTrack,
                let index = playcore.fmPlaylist.firstIndex(of: track),
                (playcore.fmPlaylist.count - index) <= 3 {
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
        
        initFMPlayList()
    }
    
    func loadFMTracks() {
        let playCore = PlayCore.shared
        playCore.api.radioGet().done {
            playCore.fmPlaylist.append(contentsOf: $0)
            }.catch {
                print($0)
        }
    }
    
    func initView() {
        prevImageButton.image = nil
        prevImageButton.isHidden = true
        let playlist = PlayCore.shared.fmPlaylist
        let markWidth = coverImageView.frame.width
        
        guard let track = PlayCore.shared.currentFMTrack else {
            lyricViewController()?.currentLyricId = -1
            songButtonsViewController()?.trackId = -1
            return
        }
        
        songInfoViewController()?.initInfos(track)
        
        guard let index = playlist.firstIndex(of: track) else { return }

        coverImageView.setImage(track.album.picUrl?.absoluteString ?? "", true, markWidth)
        lyricViewController()?.currentLyricId = track.id
        songButtonsViewController()?.trackId = track.id
        
        if let track = playlist[safe: index - 1] {
            prevImageButton.isHidden = false
            prevImageButton.setImage(track.album.picUrl?.absoluteString ?? "", true, markWidth)
        } else {
            prevImageButton.isHidden = true
        }
        
        if let track = playlist[safe: index + 1] {
            nextImageView.isHidden = false
            nextImageView.setImage(track.album.picUrl?.absoluteString ?? "", true, markWidth)
        } else {
            nextImageView.isHidden = true
        }
        
        if let track = playlist[safe: index - 2] {
            ppImageView.setImage(track.album.picUrl?.absoluteString ?? "", true, markWidth)
        } else {
            ppImageView.image = nil
        }
        
        if index > 1 {
            PlayCore.shared.fmPlaylist.removeSubrange(0..<(index - 2))
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
        @unknown default:
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
    
    func songButtonsViewController() -> SongButtonsViewController? {
        let vc = children.compactMap {
            $0 as? SongButtonsViewController
            }.first
        return vc
    }
    
    func nextTrackAnimation(_ completionHandler: (() -> Void)? = nil) {
        nextImageView.alphaValue = 0
        nextImageView.isHidden = false
        let frames = imageViewsFrames
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            nextImageView.animator().alphaValue = 1
            nextImageLeadingLayoutConstraint.animator().constant = frames[1].origin.x
            
            coverImageSizeLayoutConstraint.animator().constant = frames[2].width
            coverImageLeadingLayoutConstraint.animator().constant = frames[2].origin.x
            
            prevImageButton.animator().alphaValue = 0
            prevButtonSizeLayoutConstraint.animator().constant = frames[3].width
            prevButtonLeadingLayoutConstraint.animator().constant = frames[3].origin.x
        }) {
            self.resetLayoutConstraints()
            completionHandler?()
        }
    }
    
    func prevTrackAnimation(_ completionHandler: (() -> Void)? = nil) {
        ppImageView.alphaValue = 0
        ppImageView.isHidden = false
        let frames = imageViewsFrames
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            if ppImageView.image != nil {
                ppImageView.animator().alphaValue = 1
                ppImageLeadingLayoutConstraint.animator().constant = frames[2].origin.x
                ppImageSizeLayoutConstraint.animator().constant = frames[2].width
            }
            
            prevButtonSizeLayoutConstraint.animator().constant = frames[1].width
            prevButtonLeadingLayoutConstraint.animator().constant = frames[1].origin.x
            
            
            coverImageSizeLayoutConstraint.animator().constant = frames[0].width
            coverImageLeadingLayoutConstraint.animator().constant = frames[0].origin.x
            
        }) {
            self.resetLayoutConstraints()
            completionHandler?()
        }
    }
    
    func resetLayoutConstraints() {
        let frames = imageViewsFrames
        guard frames.count == 4 else { return }
        
        nextImageView.alphaValue = 0
        nextImageView.isHidden = true
        nextImageLeadingLayoutConstraint.constant = frames[0].origin.x
        
        coverImageSizeLayoutConstraint.constant = frames[1].width
        coverImageLeadingLayoutConstraint.constant = frames[1].origin.x
        
        prevImageButton.alphaValue = 1
        prevButtonSizeLayoutConstraint.constant = frames[2].width
        prevButtonLeadingLayoutConstraint.constant = frames[2].origin.x
        
        ppImageView.alphaValue = 0
        ppImageView.isHidden = true
        ppImageSizeLayoutConstraint.constant = frames[3].width
        ppImageLeadingLayoutConstraint.constant = frames[3].origin.x
    }
    
    func initFMPlayList() {
        let pref = Preferences.shared
        let cId = pref.fmPlaylist.0
        let ids = pref.fmPlaylist.1
        let playCore = PlayCore.shared
        if ids.count > 0 {
            playCore.api.songDetail(ids).done(on: .main) {
                playCore.fmPlaylist = $0
                playCore.currentFMTrack = $0.first {
                    $0.id == cId
                }
                self.initView()
            }.catch {
                print($0)
            }
        } else {
            pref.fmPlaylist = (nil, [])
            playCore.currentFMTrack = nil
            playCore.api.radioGet().done(on: .main) {
                playCore.fmPlaylist = $0
                playCore.currentFMTrack = $0.first
                self.initView()
            }.catch {
                print($0)
            }
        }
    }
    
    deinit {
        lyricViewController()?.removePeriodicTimeObserver(PlayCore.shared.player)
        currentTrackObserver?.invalidate()
        playerStatueObserver?.invalidate()
        fmModeObserver?.invalidate()
    }
}

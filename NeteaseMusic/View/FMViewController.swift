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
    @IBOutlet weak var coverButton1: FMCoverButton!
    @IBOutlet weak var coverButton1LeadingLC: NSLayoutConstraint!
    @IBOutlet weak var coverButton1WidthLC: NSLayoutConstraint!
    
    @IBOutlet weak var coverButton2: FMCoverButton!
    @IBOutlet weak var coverButton2LeadingLC: NSLayoutConstraint!
    @IBOutlet weak var coverButton2WidthLC: NSLayoutConstraint!
    
    @IBOutlet weak var coverButton3: FMCoverButton!
    @IBOutlet weak var coverButton3LeadingLC: NSLayoutConstraint!
    @IBOutlet weak var coverButton3WidthLC: NSLayoutConstraint!
    
    @IBOutlet weak var coverButton4: FMCoverButton!
    @IBOutlet weak var coverButton4LeadingLC: NSLayoutConstraint!
    @IBOutlet weak var coverButton4WidthLC: NSLayoutConstraint!
    
    @IBOutlet weak var playButton: NSButton!
    
    @IBOutlet weak var coversContainerView: NSView!
    
    
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
        case coverButton1, coverButton2, coverButton3, coverButton4:
            PlayCore.shared.previousSong()
        default:
            break
        }
    }
    
    var currentTrackObserver: NSKeyValueObservation?
    var playerStatueObserver: NSKeyValueObservation?
    var fmModeObserver: NSKeyValueObservation?
    
    var coverViews = [(button: FMCoverButton,
                       leadingLC: NSLayoutConstraint,
                       widthLC: NSLayoutConstraint)]()
    var coverViewsLC = [(leading: CGFloat, width: CGFloat)]()
    
    enum CoversInitMode {
        case reset, next, prev
    }
    var date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePlayButton(true)
        initCoverButtonsArray()
        
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
                
                DispatchQueue.main.async {
                    if newI == oldI + 1 {
                        self?.initView(.next)
                        self?.nextTrackAnimation()
                    } else if newI == oldI - 1 {
                        self?.initView(.prev)
                        self?.prevTrackAnimation()
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
    
    func initCoverButtonsArray() {
        coverViews = [(coverButton1, coverButton1LeadingLC, coverButton1WidthLC),
                      (coverButton2, coverButton2LeadingLC, coverButton2WidthLC),
                      (coverButton3, coverButton3LeadingLC, coverButton3WidthLC),
                      (coverButton4, coverButton4LeadingLC, coverButton4WidthLC)]
        
        coverViewsLC = coverViews.map {
            ($0.leadingLC.constant, $0.widthLC.constant)
        }
    }
    
    func loadFMTracks() {
        let playCore = PlayCore.shared
        playCore.api.radioGet().done {
            playCore.fmPlaylist.append(contentsOf: $0)
            }.catch {
                print($0)
        }
    }
    
    func initView(_ mode: CoversInitMode = .reset) {
        let playCore = PlayCore.shared
        var initMode = mode
        if coverViews.count != 4 || coverViewsLC.count != 4 {
            initCoverButtonsArray()
            initMode = .reset
        }
        let imageWidth = coverViews[3].button.frame.width
        let playlist = playCore.fmPlaylist
        
        if let track = playCore.currentFMTrack,
            let index = playlist.firstIndex(of: track) {
            // Update sub VC
            lyricViewController()?.currentLyricId = track.id
            songButtonsViewController()?.trackId = track.id
            songInfoViewController()?.initInfos(track)
            
            var coverList = [String?]()
            
            switch index {
            case 0:
                coverList = [nil, nil]
                coverList.append(playlist.first?.album.picUrl?.absoluteString)
                if playlist.count > 1 {
                    coverList.append(playlist[1].album.picUrl?.absoluteString)
                }
            case 1:
                coverList = [nil]
                coverList.append(playlist[0].album.picUrl?.absoluteString)
                coverList.append(playlist[1].album.picUrl?.absoluteString)
                if playlist.count > 2 {
                    coverList.append(playlist[1].album.picUrl?.absoluteString)
                }
            default:
                coverList = [nil]
                coverList.append(playlist[index - 1].album.picUrl?.absoluteString)
                coverList.append(playlist[index].album.picUrl?.absoluteString)
                if playlist.count > index {
                    coverList.append(playlist[index + 1].album.picUrl?.absoluteString)
                }
            }
            
            if index > 1 {
                playCore.fmPlaylist.removeSubrange(0..<(index - 2))
            }
            
            guard coverList.count == 4 else { return }
            switch initMode {
            case .reset:
                resetLayoutConstraints()
                coverViews.enumerated().forEach {
                    $0.element.button.setImage(coverList[$0.offset], true, imageWidth)
                }
                [0, 3].forEach {
                    coverViews[$0].button.alphaValue = 0
                    coverViews[$0].button.isHidden = true
                }
                coverViews[2].button.alphaValue = 1
                coverViews[2].button.isHidden = false
                if coverList[1] == nil {
                    coverViews[1].button.isHidden = true
                }
            case .next:
                // Move first to last
                let v = coverViews.remove(at: 0)
                v.button.setImage(coverList[3], true, imageWidth)
                coverViews.append(v)
                if coverViews[2].button.image == nil {
                    coverViews[2].button.setImage(coverList[2], true, imageWidth)
                }
                coverViews[2].button.isHidden = false
                coverViews[2].button.alphaValue = 0

                coverViews[3].button.isHidden = true
                coverViews[3].button.alphaValue = 0
            case .prev:
                // Move last to first
                let v = coverViews.remove(at: 3)
                v.button.image = nil
                coverViews.insert(v, at: 0)
                [1, 2].forEach {
                    if coverViews[$0].button.image == nil {
                        if let c = coverList[$0] {
                            coverViews[$0].button.setImage(c, true, imageWidth)
                        } else {
                            coverViews[$0].button.alphaValue = 0
                            coverViews[$0].button.isHidden = true
                        }
                    } else if $0 == 1 {
                        coverViews[$0].button.alphaValue = 0
                        coverViews[$0].button.isHidden = false
                    }
                }
            }
        } else {
            lyricViewController()?.currentLyricId = -1
            songButtonsViewController()?.trackId = -1
            if playlist.count > 0 {
                PlayCore.shared.currentFMTrack = playlist[0]
            } else {
                initFMPlayList()
            }
        }
        
        coverViews.enumerated().forEach {
            $0.element.button.index = $0.offset
        }
        
        coversContainerView.sortSubviews({ (v1, v2, _) -> ComparisonResult in
            if let b1 = v1 as? FMCoverButton,
                let b2 = v2 as? FMCoverButton {
                return b1.index > b2.index ? .orderedDescending : .orderedAscending
            } else if v1 is FMCoverButton {
                return .orderedAscending
            } else if v2 is FMCoverButton {
                return .orderedDescending
            }
            return .orderedSame
        }, context: nil)
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
    
    func nextTrackAnimation() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            if coverViews[0].button.image != nil {
                coverViews[0].button.animator().alphaValue = 0
            }
            coverViews[2].button.animator().alphaValue = 1
            coverViews.enumerated().forEach {
                $0.element.leadingLC.animator().constant = coverViewsLC[$0.offset].leading
                $0.element.widthLC.animator().constant = coverViewsLC[$0.offset].width
            }
        }) {
            self.coverViews[0].button.isHidden = true
        }
    }
    
    func prevTrackAnimation() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            if coverViews[1].button.image != nil {
                coverViews[1].button.animator().alphaValue = 1
            }
            coverViews[3].button.animator().alphaValue = 0
            
            coverViews.enumerated().forEach {
                $0.element.leadingLC.animator().constant = coverViewsLC[$0.offset].leading
                $0.element.widthLC.animator().constant = coverViewsLC[$0.offset].width
            }
        }) {
            self.coverViews[3].button.isHidden = true
        }
    }
    
    func resetLayoutConstraints() {
        coverViews.enumerated().forEach {
            $0.element.leadingLC.constant = coverViewsLC[$0.offset].leading
            $0.element.widthLC.constant = coverViewsLC[$0.offset].width
        }
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

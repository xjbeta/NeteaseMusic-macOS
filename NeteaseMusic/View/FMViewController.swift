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
    }
    
    @IBAction func previousSong(_ sender: FMCoverButton) {
        let pc = PlayCore.shared
        guard sender.index == 1 else { return }
        if pc.fmMode {
            pc.previousSong()
        } else if let t = pc.currentFMTrack,
            let i
            = pc.fmPlaylist.firstIndex(of: t) {
            pc.currentFMTrack = pc.fmPlaylist[safe: i - 1]
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
        let pc = PlayCore.shared
        if let track = pc.currentFMTrack,
            let index = pc.fmPlaylist.firstIndex(of: track) {
            if (pc.fmPlaylist.count - index) > 5 {
                return
            }
        } else if pc.fmPlaylist.count > 5 {
            return
        }
        
        pc.api.radioGet().done {
            pc.fmPlaylist.append(contentsOf: $0)
            }.catch {
                print($0)
        }
    }
    
    func initView(_ mode: CoversInitMode = .reset) {
        let playCore = PlayCore.shared
        var initMode = mode
        songButtonsViewController()?.isFMView = true
        if coverViews.count != 4 || coverViewsLC.count != 4 {
            initCoverButtonsArray()
            initMode = .reset
        }
        let imageWidth = coverViews[3].button.frame.width
        let playlist = playCore.fmPlaylist
        var coverList = [(id: Int?, url: String?)]()
        if let track = playCore.currentFMTrack,
            let index = playlist.firstIndex(of: track) {
            // Update sub VC
            lyricViewController()?.currentLyricId = track.id
            songButtonsViewController()?.trackId = track.id
            songInfoViewController()?.initInfos(track)
            
            switch index {
            case 0:
                coverList = [(nil, nil), (nil, nil)]
                let alF = playlist.first?.album
                coverList.append((alF?.id,
                                  alF?.picUrl?.absoluteString))
                let alS = playlist[safe: 1]?.album
                coverList.append((alS?.id, alS?.picUrl?.absoluteString))
            case 1:
                coverList = [(nil, nil)]
                let alF = playlist[0].album
                coverList.append((alF.id,
                                  alF.picUrl?.absoluteString))
                let alS = playlist[1].album
                coverList.append((alS.id,
                                  alS.picUrl?.absoluteString))
                let alT = playlist[safe: 2]?.album
                coverList.append((alT?.id,
                                  alT?.picUrl?.absoluteString))
            default:
                coverList = [(nil, nil)]
                let alP = playlist[safe: index - 1]?.album
                coverList.append((alP?.id, alP?.picUrl?.absoluteString))
                
                let al = playlist[safe: index]?.album
                coverList.append((al?.id, al?.picUrl?.absoluteString))
                
                let alN = playlist[safe: index + 1]?.album
                coverList.append((alN?.id, alN?.picUrl?.absoluteString))
            }
            
            if index > 1 {
                playCore.fmPlaylist.removeSubrange(0..<(index - 2))
            }
            
            guard coverList.count == 4 else { return }

            switch initMode {
            case .reset:
                resetLayoutConstraints()
            case .next:
                // Move first to last
                let v = coverViews.remove(at: 0)
                coverViews.append(v)
            case .prev:
                // Move last to first
                let v = coverViews.remove(at: 3)
                coverViews.insert(v, at: 0)
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
            let b = $0.element.button
            b.index = $0.offset
            let c = coverList[safe: $0.offset]
            if let id = c?.id {
                b.alphaValue = 1
                b.isHidden = false
                if b.coverAlbumID != id {
                    b.setImage(c?.url, false, imageWidth)
                    b.coverAlbumID = id
                }
            } else {
                b.alphaValue = 0
                b.isHidden = true
            }
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
        coverViews[3].button.isHidden = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            coverViews[0].button.animator().alphaValue = 0
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
            coverViews[1].button.animator().alphaValue = 1
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
                $0.forEach {
                    $0.from = (.fm, 0, "FM")
                }
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

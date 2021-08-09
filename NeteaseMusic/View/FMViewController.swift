//
//  FMViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

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
        let pc = PlayCore.shared
        let player = pc.player
        if pc.fmMode {
            pc.togglePlayPause()
        } else {
            pc.start(fmPlaylist,
                     id: currentTrackId,
                     enterFMMode: true)
        }
    }
    
    @IBAction func previousSong(_ sender: FMCoverButton) {
        let pc = PlayCore.shared
        guard pc.fmMode, sender.index == 1 else { return }
        pc.previousSong()
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
    
    var fmPlaylist = [Track]()
    var currentTrackId = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ViewControllerManager.shared.fmVC = self
        
        updatePlayButton(true)
        initCoverButtonsArray()
        
        currentTrackObserver = PlayCore.shared.observe(\.currentTrack, options: [.initial, .new, .old]) { pc, changes in
            guard pc.fmMode else { return }
            self.currentTrackId = pc.currentTrack?.id ?? -1
            
            print("currentTrack changed \(changes).")
            if let oldTrack = changes.oldValue,
                let newTrack = changes.newValue,
                let old = oldTrack,
                let new = newTrack {
                
                var oldI = -1
                var newI = -1
                pc.playlist.enumerated().forEach {
                    if $0.element == old {
                        oldI = $0.offset
                    } else if $0.element == new {
                        newI = $0.offset
                    }
                }
                
                DispatchQueue.main.async {
                    if newI == oldI + 1 {
                        self.initView(.next)
                        self.nextTrackAnimation()
                    } else if newI == oldI - 1 {
                        self.initView(.prev)
                        self.prevTrackAnimation()
                    } else {
                        self.initView()
                    }
                }
            }
            
            // Load more fm tracks
            if let track = pc.currentTrack,
                let index = pc.playlist.firstIndex(of: track),
                (pc.playlist.count - index) <= 3 {
                self.loadFMTracks()
            }
        }
        
        playerStatueObserver = PlayCore.shared.observe(\.playerState, options: [.initial, .new]) { pc, changes in
            guard PlayCore.shared.fmMode else { return }
            self.updateCoverButtonStatus(!pc.player.isPlaying())
        }
        
        fmModeObserver = PlayCore.shared.observe(\.fmMode, options: [.initial, .new]) { pc, _ in
            guard let vc = self.lyricViewController() else { return }
            if pc.fmMode {
                self.updateCoverButtonStatus(!pc.player.isPlaying())
                vc.addPlayProgressObserver()
            } else {
                self.updateCoverButtonStatus(true)
                vc.removePlayProgressObserver()
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
        if let track = pc.currentTrack,
            let index = pc.playlist.firstIndex(of: track) {
            if (pc.playlist.count - index) > 5 {
                return
            }
        } else if pc.playlist.count > 5 {
            return
        }
        
        pc.api.radioGet().done {
            self.fmPlaylist.append(contentsOf: $0)
            pc.playlist.append(contentsOf: $0)
            }.catch {
                print($0)
        }
    }
    
    func initView(_ mode: CoversInitMode = .reset) {
        var initMode = mode
        songButtonsViewController()?.isFMView = true
        if coverViews.count != 4 || coverViewsLC.count != 4 {
            initCoverButtonsArray()
            initMode = .reset
        }
        let imageWidth = coverViews[3].button.frame.width
        let playlist = fmPlaylist
        var coverList = [(id: Int?, url: String?)]()
        
        
        if let track = playlist.first(where: { $0.id == currentTrackId }),
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
                fmPlaylist.removeSubrange(0..<(index - 2))
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
                currentTrackId = playlist[0].id
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
    
    func updateCoverButtonStatus(_ paused: Bool) {
        guard PlayCore.shared.fmMode else {
            updatePlayButton(true)
            return
        }
        updatePlayButton(paused)
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
        let pc = PlayCore.shared
        
        let cId = pref.fmPlaylist.0
        let ids = pref.fmPlaylist.1
        if ids.count > 0 {
            pc.api.songDetail(ids).done(on: .main) {
                $0.forEach {
                    $0.from = (.fm, 0, "FM")
                }
                self.fmPlaylist = $0
                self.currentTrackId = cId ?? -1
                self.initView()
            }.catch {
                print($0)
            }
        } else {
            pref.fmPlaylist = (nil, [])
            currentTrackId = -1
            pc.api.radioGet().done(on: .main) {
                self.fmPlaylist = $0
                self.currentTrackId = $0.first?.id ?? -1
                self.initView()
            }.catch {
                print($0)
            }
        }
    }
    
    deinit {
        Preferences.shared.fmPlaylist = (currentTrackId, fmPlaylist.map({ $0.id }))
        
        lyricViewController()?.removePlayProgressObserver()
        currentTrackObserver?.invalidate()
        playerStatueObserver?.invalidate()
        fmModeObserver?.invalidate()
    }
}

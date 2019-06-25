//
//  ControlBarViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/10.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import AVFoundation

class ControlBarViewController: NSViewController {
    
    @IBOutlet weak var trackPicButton: NSButton!
    @IBOutlet weak var trackNameTextField: NSTextField!
    @IBOutlet weak var trackSecondNameTextField: NSTextField!
    @IBOutlet weak var trackArtistTextField: NSTextField!

    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var pauseButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var muteButton: NSButton!
    @IBOutlet weak var playlistButton: NSButton!
    @IBOutlet weak var repeatModeButton: NSButton!
    @IBOutlet weak var shuffleModeButton: NSButton!
    
    @IBAction func controlAction(_ sender: NSButton) {
        let player = PlayCore.shared.player
        switch sender {
        case previousButton:
            PlayCore.shared.previousSong()
        case pauseButton:
            guard player.error == nil else { return }
            func continuePlayOrPause() {
                if player.rate == 0 {
                    player.play()
                } else {
                    player.pause()
                }
            }
            if PlayCore.shared.fmMode, PlayCore.shared.currentFMTrack != nil {
                continuePlayOrPause()
            } else if !PlayCore.shared.fmMode, PlayCore.shared.currentTrack != nil {
                continuePlayOrPause()
            } else if let item = ViewControllerManager.shared.selectedSidebarItem?.type {
                switch item {
                case .fm:
                    PlayCore.shared.start(enterFMMode: true)
                case .playlist:
                    let todo = "play playlist."
                    break
                default:
                    break
                }
            }
        case nextButton:
            PlayCore.shared.nextSong()
            if PlayCore.shared.fmMode, let id = PlayCore.shared.currentTrack?.id {
                let seconds = Int(player.currentTime().seconds)
                PlayCore.shared.api.radioSkip(id, seconds).done {
                    print("Song skipped, id: \(id) seconds: \(seconds)")
                    }.catch {
                        print($0)
                }
            }
        case muteButton:
            player.isMuted = !player.isMuted
        case playlistButton:
            NotificationCenter.default.post(name: .showPlaylist, object: nil)
        case repeatModeButton:
            switch PlayCore.shared.repeatMode {
            case .noRepeat:
                PlayCore.shared.repeatMode = .repeatPlayList
            case .repeatPlayList:
                PlayCore.shared.repeatMode = .repeatItem
            case .repeatItem:
                PlayCore.shared.repeatMode = .noRepeat
            }
            initPlayModeButton()
        case shuffleModeButton:
            switch PlayCore.shared.shuffleMode {
            case .noShuffle:
                PlayCore.shared.shuffleMode = .shuffleItems
            case .shuffleItems:
                PlayCore.shared.shuffleMode = .noShuffle
            case .shuffleAlbums:
                break
            }
            initPlayModeButton()
        case trackPicButton:
            NotificationCenter.default.post(name: .showPlayingSong, object: nil)
        default:
            break
        }
    }
    
    @IBOutlet weak var durationSlider: PlayerSlider!
    @IBOutlet weak var durationTextField: NSTextField!
    @IBOutlet weak var volumeSlider: NSSlider!
    
    @IBAction func sliderAction(_ sender: NSSlider) {
        switch sender {
        case durationSlider:
            PlayCore.shared.player.pause()
            let time = CMTime(seconds: sender.doubleValue, preferredTimescale: 1000)
            PlayCore.shared.player.seek(to: time) { [weak self] re in
                self?.durationSlider.finishValueUpdate()
                PlayCore.shared.player.play()
            }
        case volumeSlider:
            PlayCore.shared.player.volume = volumeSlider.floatValue
        default:
            break
        }
    }
    
    var periodicTimeObserverToken: Any?
    var pauseStautsObserver: NSKeyValueObservation?
    var muteStautsObserver: NSKeyValueObservation?
    var previousButtonObserver: NSKeyValueObservation?
    var currentTrackObserver: NSKeyValueObservation?
    var currentFMTrackObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPeriodicTimeObserver()
        
        volumeSlider.maxValue = 1
        volumeSlider.floatValue = PlayCore.shared.player.volume
        
        trackPicButton.wantsLayer = true
        trackPicButton.layer?.cornerRadius = 4
        
        trackNameTextField.stringValue = ""
        trackSecondNameTextField.stringValue = ""
        trackArtistTextField.stringValue = ""
        
        initPlayModeButton()
        
        pauseStautsObserver = PlayCore.shared.player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] (player, changes) in
            switch player.timeControlStatus {
            case .playing:
                self?.pauseButton.image = NSImage(named: NSImage.Name("btmbar.sp#icn-pause"))
            case .paused:
                self?.pauseButton.image = NSImage(named: NSImage.Name("btmbar.sp#icn-play"))
            default:
                break
            }
        }
        
        muteStautsObserver = PlayCore.shared.player.observe(\.isMuted, options: [.initial, .new]) { [weak self] (player, changes) in
            guard let image = player.isMuted ? NSImage(named: NSImage.Name("btmbar.sp#icn-silence")) : NSImage(named: NSImage.Name("btmbar.sp#icn-voice")) else { return }
            self?.muteButton.image = image
        }
        
        previousButtonObserver = PlayCore.shared.observe(\.playedTracks, options: [.initial, .new]) { [weak self] (playCore, changes) in
            self?.previousButton.isEnabled = playCore.playedTracks.count > 0
        }
        
        currentTrackObserver = PlayCore.shared.observe(\.currentTrack, options: [.initial, .new]) { [weak self] (playCore, changes) in
            guard !playCore.fmMode, let track = playCore.currentTrack else { return }
            self?.initViews(track)
        }
        
        currentFMTrackObserver = PlayCore.shared.observe(\.currentFMTrack, options: [.initial, .new]) { [weak self] (playCore, changes) in
            guard playCore.fmMode, let track = playCore.currentFMTrack else { return }
            self?.initViews(track)
        }
    }
    
    func addPeriodicTimeObserver() {
        // Notify every half second
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.25, preferredTimescale: timeScale)
        periodicTimeObserverToken = PlayCore.shared.player
            .addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
                guard let duration = PlayCore.shared.player.currentItem?.asset.duration,
                    let durationSlider = self?.durationSlider else { return }
                let periodicSec = Double(CMTimeGetSeconds(time))
                durationSlider.updateValue(periodicSec)
                let durationSec = Double(CMTimeGetSeconds(duration))
                if durationSec != durationSlider.maxValue {
                    durationSlider.maxValue = durationSec
                }
                
                self?.durationTextField.stringValue = "\(periodicSec.durationFormatter()) / \(durationSec.durationFormatter())"
        }
    }
    
    func initViews(_ track: Track) {
        trackPicButton.setImage(track.album.picUrl?.absoluteString ?? "", true)
        trackNameTextField.stringValue = track.name
        let name = track.secondName
        trackSecondNameTextField.isHidden = name == ""
        trackSecondNameTextField.stringValue = name
        trackArtistTextField.stringValue = track.artists.artistsString()
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = periodicTimeObserverToken {
            PlayCore.shared.player.removeTimeObserver(timeObserverToken)
            self.periodicTimeObserverToken = nil
        }
    }
    
    func initPlayModeButton() {
        var repeatImage: NSImage?
        switch PlayCore.shared.repeatMode {
        case .repeatPlayList:
            repeatImage = NSImage(named: NSImage.Name("btmbar.sp#icn-loop"))
        case .repeatItem:
            repeatImage = NSImage(named: NSImage.Name("btmbar.sp#icn-one"))
        case .noRepeat:
            break
        }
        repeatModeButton.image = repeatImage
        
        var shuffleImage: NSImage?
        switch PlayCore.shared.shuffleMode {
        case .shuffleItems:
            shuffleImage = NSImage(named: NSImage.Name("btmbar.sp#icn-shuffle"))
        case .shuffleAlbums:
            shuffleImage = NSImage(named: NSImage.Name("btmbar.sp#icn-shuffle"))
        case .noShuffle:
            break
        }
        shuffleModeButton.image = shuffleImage
    }
    
    deinit {
        removePeriodicTimeObserver()
        pauseStautsObserver?.invalidate()
        previousButtonObserver?.invalidate()
        muteStautsObserver?.invalidate()
        currentTrackObserver?.invalidate()
        currentFMTrackObserver?.invalidate()
    }
    
}

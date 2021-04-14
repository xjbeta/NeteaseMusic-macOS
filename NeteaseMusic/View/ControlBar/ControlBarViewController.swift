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
        let preferences = Preferences.shared
        switch sender {
        case previousButton:
            PlayCore.shared.previousSong()
        case pauseButton:
            PlayCore.shared.togglePlayPause()
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
            let mute = !player.isMuted
            player.isMuted = mute
            preferences.mute = mute
            initVolumeButton()
        case repeatModeButton:
            switch preferences.repeatMode {
            case .noRepeat:
                preferences.repeatMode = .repeatPlayList
            case .repeatPlayList:
                preferences.repeatMode = .repeatItem
            case .repeatItem:
                preferences.repeatMode = .noRepeat
            }
            initPlayModeButton()
        case shuffleModeButton:
            switch preferences.shuffleMode {
            case .noShuffle:
                preferences.shuffleMode = .shuffleItems
            case .shuffleItems:
                preferences.shuffleMode = .noShuffle
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
            let time = CMTime(seconds: sender.doubleValue, preferredTimescale: 1000)
            PlayCore.shared.player.seek(to: time) { _ in }
            if let eventType = NSApp.currentEvent?.type,
                eventType == .leftMouseUp {
                durationSlider.ignoreValueUpdate = false
            }
        case volumeSlider:
            let v = volumeSlider.floatValue
            PlayCore.shared.player.volume = v
            Preferences.shared.volume = v
            initVolumeButton()
        default:
            break
        }
    }
    
    var periodicTimeObserverToken: Any?
    var pauseStautsObserver: NSKeyValueObservation?
    var previousButtonObserver: NSKeyValueObservation?
    var currentTrackObserver: NSKeyValueObservation?
    var currentFMTrackObserver: NSKeyValueObservation?
    var fmModeObserver: NSKeyValueObservation?
    
    let imgSize = NSSize(width: 15, height: 13)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playlistButton.image?.size = imgSize
        
        let playCore = PlayCore.shared
        
        addPeriodicTimeObserver()
        
        initVolumeButton()
        
        
        trackPicButton.wantsLayer = true
        trackPicButton.layer?.cornerRadius = 4
        
        trackNameTextField.stringValue = ""
        trackSecondNameTextField.stringValue = ""
        trackArtistTextField.stringValue = ""
        
        initPlayModeButton()
        
        pauseStautsObserver = playCore.player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] (player, changes) in
            switch player.timeControlStatus {
            case .playing:
                self?.pauseButton.image = NSImage(named: NSImage.Name("sf.pause.circle"))
            case .paused:
                self?.pauseButton.image = NSImage(named: NSImage.Name("sf.play.circle"))
            default:
                break
            }
        }
        
        previousButtonObserver = playCore.observe(\.playedTracks, options: [.initial, .new]) { [weak self] (playCore, changes) in
            self?.previousButton.isEnabled = playCore.playedTracks.count > 0
        }
        
        currentTrackObserver = playCore.observe(\.currentTrack, options: [.initial, .new]) { [weak self] (playCore, changes) in
            guard !playCore.fmMode, let track = playCore.currentTrack else { return }
            self?.initViews(track)
        }
        
        currentFMTrackObserver = playCore.observe(\.currentFMTrack, options: [.initial, .new]) { [weak self] (playCore, changes) in
            guard playCore.fmMode, let track = playCore.currentFMTrack else { return }
            self?.initViews(track)
        }
        
        fmModeObserver = playCore.observe(\.fmMode, options: [.initial, .new]) { [weak self] (playCore, changes) in
            let fmMode = playCore.fmMode
            self?.previousButton.isHidden = fmMode
            self?.repeatModeButton.isHidden = fmMode
            self?.shuffleModeButton.isHidden = fmMode
        }
    }
    
    func addPeriodicTimeObserver() {
        // Notify every half second
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.25, preferredTimescale: timeScale)
        periodicTimeObserverToken = PlayCore.shared.player
            .addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
                let player = PlayCore.shared.player
                guard let duration = player.currentItem?.asset.duration,
                    let slider = self?.durationSlider else { return }
                
                let loadedTimeRanges = player.currentItem?.loadedTimeRanges

                let periodicSec = Double(CMTimeGetSeconds(time))
                slider.updateValue(periodicSec)
                let durationSec = Double(CMTimeGetSeconds(duration))
                if durationSec != slider.maxValue {
                    slider.maxValue = durationSec
                }

                if let range = loadedTimeRanges?.first {
                    let time = CMTimeRangeGetEnd(range.timeRangeValue)
                    let sec = Double(CMTimeGetSeconds(time))
                    let todo = "Update cache value when paused."
                    slider.cachedDoubleValue = sec
                    
                    let loadProgress = sec / durationSec
                    guard let item = player.currentItem as? NeteasePlayerItem,
                          item.downloadState != .downloadFinished,
                        loadProgress == 1 else { return }
                    NotificationCenter.default.post(name: .AVPlayerItemDownloadFinished, object: nil, userInfo: ["id": item.id])
                }
                
                self?.durationTextField.stringValue = "\(periodicSec.durationFormatter()) / \(durationSec.durationFormatter())"
                if Preferences.shared.useSystemMediaControl {
                    PlayCore.shared.updateNowPlayingInfo()
                }
        }
    }
    
    func initViews(_ track: Track) {
        trackPicButton.setImage(track.album.picUrl?.absoluteString, true)
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
    
    func initVolumeButton() {
        let pc = PlayCore.shared
        let pref = Preferences.shared
        
        let volume = pref.volume
        volumeSlider.floatValue = volume
        pc.player.volume = volume
        
        let mute = pref.mute
        pc.player.isMuted = mute
        
        var imageName = ""
        if mute {
            imageName = "sf.speaker.slash"
        } else {
            switch volume {
            case 0:
                imageName = "sf.speaker"
            case 0..<1/3:
                imageName = "sf.speaker.wave.1"
            case 1/3..<2/3:
                imageName = "sf.speaker.wave.2"
            case 2/3...1:
                imageName = "sf.speaker.wave.3"
            default:
                imageName = "sf.speaker"
            }
        }
        guard let image = NSImage(named: NSImage.Name(imageName)) else {
            return
        }
        let h: CGFloat = 14
        let s = image.size
        image.size = .init(width: (s.width / s.height) * h,
                           height: h)
        muteButton.image = image
    }
    
    func initPlayModeButton() {
        let pref = Preferences.shared
        
        let repeatImgName = pref.repeatMode == .repeatItem ? "sf.repeat.1" : "sf.repeat"
        let shuffleImgName = "sf.shuffle"
        
        let repeatImgColor: NSColor = pref.repeatMode == .noRepeat ? .systemGray : .systemRed
        let shuffleImgColor: NSColor = pref.shuffleMode == .noShuffle ? .systemGray : .systemRed

        let repeatImage = NSImage(named: .init(repeatImgName))
        let shuffleImage = NSImage(named: .init(shuffleImgName))
        
        repeatImage?.size = imgSize
        shuffleImage?.size = imgSize
        
        repeatModeButton.image = repeatImage?.tint(color: repeatImgColor)
        shuffleModeButton.image = shuffleImage?.tint(color: shuffleImgColor)
    }
    
    deinit {
        removePeriodicTimeObserver()
        pauseStautsObserver?.invalidate()
        previousButtonObserver?.invalidate()
//        muteStautsObserver?.invalidate()
        currentTrackObserver?.invalidate()
        currentFMTrackObserver?.invalidate()
        fmModeObserver?.invalidate()
    }
    
}

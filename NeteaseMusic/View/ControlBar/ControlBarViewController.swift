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
    
    var pauseStautsObserver: NSKeyValueObservation?

    var previousButtonObserver: NSKeyValueObservation?
    var currentTrackObserver: NSKeyValueObservation?
    var fmModeObserver: NSKeyValueObservation?
    
    let imgSize = NSSize(width: 15, height: 13)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playlistButton.image?.size = imgSize
        
        let pc = PlayCore.shared
        pc.playerProgressDelegate = self
        
        initVolumeButton()
        
        
        trackPicButton.wantsLayer = true
        trackPicButton.layer?.cornerRadius = 4
        
        trackNameTextField.stringValue = ""
        trackSecondNameTextField.stringValue = ""
        trackArtistTextField.stringValue = ""
        
        initPlayModeButton()
        
        pauseStautsObserver = pc.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] (player, changes) in
            switch player.timeControlStatus {
            case .playing:
                self?.pauseButton.image = NSImage(named: NSImage.Name("sf.pause.circle"))
            case .paused:
                self?.pauseButton.image = NSImage(named: NSImage.Name("sf.play.circle"))
            default:
                break
            }
        }
        
        previousButtonObserver = pc.observe(\.pnItemType, options: [.initial, .new]) { [weak self] pc, _ in
            
            self?.previousButton.isEnabled = true
            self?.nextButton.isEnabled = true
            
            switch pc.pnItemType {
            case .withoutNext:
                self?.nextButton.isEnabled = false
            case .withoutPrevious:
                self?.previousButton.isEnabled = false
            case .withoutPreviousAndNext:
                self?.nextButton.isEnabled = false
                self?.previousButton.isEnabled = false
            case .other:
                break
            }
            
        }
        
        currentTrackObserver = pc.observe(\.currentTrack, options: [.initial, .new]) { [weak self] pc, _ in
            self?.initViews(pc.currentTrack)
        }
        
        fmModeObserver = pc.observe(\.fmMode, options: [.initial, .new]) { [weak self] (playCore, changes) in
            let fmMode = playCore.fmMode
            self?.previousButton.isHidden = fmMode
            self?.repeatModeButton.isHidden = fmMode
            self?.shuffleModeButton.isHidden = fmMode
        }
    }
    
    
    func initViews(_ track: Track?) {
        if let t = track {
            trackPicButton.setImage(t.album.picUrl?.absoluteString, true)
            trackNameTextField.stringValue = t.name
            let name = t.secondName
            trackSecondNameTextField.isHidden = name == ""
            trackSecondNameTextField.stringValue = name
            trackArtistTextField.stringValue = t.artists.artistsString()
        } else {
            trackPicButton.image = nil
            trackNameTextField.stringValue = ""
            trackSecondNameTextField.stringValue = ""
            trackArtistTextField.stringValue = ""
        }
        
        durationSlider.maxValue = 1
        durationSlider.doubleValue = 0
        durationSlider.cachedDoubleValue = 0
        durationTextField.stringValue = "00:00 / 00:00"
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
        
        PlayCore.shared.updateRepeatShuffleMode()
    }
    
    deinit {
        pauseStautsObserver?.invalidate()
        previousButtonObserver?.invalidate()
//        muteStautsObserver?.invalidate()
        currentTrackObserver?.invalidate()
        fmModeObserver?.invalidate()
    }
    
}

extension ControlBarViewController: AVPlayerProgressDelegate {
    func avplayer(_ player: AVPlayer, didUpdate progress: Double) {
        guard let slider = durationSlider else { return }
        
        guard player.currentItem != nil else {
            slider.maxValue = 1
            slider.doubleValue = 0
            slider.cachedDoubleValue = 0
            durationTextField.stringValue = "00:00 / 00:00"
            return
        }
        
        let cd = player.currentDuration
        let td = player.totalDuration
        
        if td != slider.maxValue {
            slider.maxValue = td
        }
        slider.updateValue(cd)
        slider.cachedDoubleValue = player.currentBufferDuration
        
        durationTextField.stringValue = "\(cd.durationFormatter()) / \(td.durationFormatter())"
    }
}

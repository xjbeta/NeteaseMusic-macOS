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
    
    var playProgressObserver: NSKeyValueObservation?
    var pauseStautsObserver: NSKeyValueObservation?
    var previousButtonObserver: NSKeyValueObservation?
    var currentTrackObserver: NSKeyValueObservation?
    var fmModeObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previousButton.contentTintColor = .nColor
        nextButton.contentTintColor = .nColor
        
        var musicListImage = NSImage(named: .init("music.note.list"))
        if #available(macOS 11.0, *) {
            musicListImage = musicListImage?.withSymbolConfiguration(.init(scale: .large))
        }
        playlistButton.image = musicListImage?.tint(color: .nColor)
        
        let pc = PlayCore.shared
        initVolumeButton()
        
        
        trackPicButton.wantsLayer = true
        trackPicButton.layer?.cornerRadius = 4
        
        trackNameTextField.stringValue = ""
        trackSecondNameTextField.stringValue = ""
        artistButtonsViewController()?.removeAllButtons()
        
        initPlayModeButton()
        
        playProgressObserver = pc.observe(\.playProgress, options: [.initial, .new]) { [weak self] pc, _ in
            guard let slider = self?.durationSlider,
                  let textFiled = self?.durationTextField else { return }
            let player = pc.player
            guard player.currentItem != nil else {
                slider.maxValue = 1
                slider.doubleValue = 0
                slider.cachedDoubleValue = 0
                textFiled.stringValue = "00:00 / 00:00"
                return
            }
            
            let cd = player.currentDuration
            let td = player.totalDuration
            
            if td != slider.maxValue {
                slider.maxValue = td
            }
            slider.updateValue(cd)
            slider.cachedDoubleValue = player.currentBufferDuration
            
            textFiled.stringValue = "\(cd.durationFormatter()) / \(td.durationFormatter())"
        }
        
        pauseStautsObserver = pc.observe(\.playerState, options: [.initial, .new]) { [weak self] pc, _ in
            guard let button = self?.pauseButton else { return }
            let name = pc.playerState == .playing ? "pause.circle" : "play.circle"
            var img = NSImage(named: NSImage.Name(name))
            if #available(macOS 11.0, *) {
                img = img?.withSymbolConfiguration(.init(pointSize: button.frame.width, weight: .light, scale: .large))
            }
            button.image = img?.tint(color: .nColor)
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
        
        if durationSlider.trackingAreas.isEmpty {
            durationSlider.addTrackingArea(NSTrackingArea(rect: durationSlider.frame, options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect], owner: self, userInfo: ["obj": 0]))
        }
    }
    
    
    func initViews(_ track: Track?) {
        if let t = track {
            trackPicButton.setImage(t.album.picUrl?.absoluteString, true)
            trackNameTextField.stringValue = t.name
            let name = t.secondName
            trackSecondNameTextField.isHidden = name == ""
            trackSecondNameTextField.stringValue = name
            artistButtonsViewController()?.initButtons(t, small: true)
            durationTextField.isHidden = false
        } else {
            trackPicButton.image = nil
            trackNameTextField.stringValue = ""
            trackSecondNameTextField.stringValue = ""
            artistButtonsViewController()?.removeAllButtons()
            durationTextField.isHidden = true
        }
        
        durationSlider.maxValue = 1
        durationSlider.doubleValue = 0
        durationSlider.cachedDoubleValue = 0
        durationTextField.stringValue = "00:00 / 00:00"
        
        durationSlider.mouseResponse = !durationTextField.isHidden
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
        var color = NSColor.nColor
        if mute {
            imageName = "speaker.slash"
            color = .systemGray
        } else {
            switch volume {
            case 0:
                imageName = "speaker"
                color = .systemGray
            case 0..<1/3:
                imageName = "speaker.wave.1"
            case 1/3..<2/3:
                imageName = "speaker.wave.2"
            case 2/3...1:
                imageName = "speaker.wave.3"
            default:
                imageName = "speaker"
            }
        }
        var img = NSImage(named: .init(imageName))
        if #available(macOS 11.0, *) {
            img = img?.withSymbolConfiguration(.init(scale: .large))
        }
        
        muteButton.image = img?.tint(color: color)
    }
    
    func initPlayModeButton() {
        let pref = Preferences.shared
        
        let repeatImgName = pref.repeatMode == .repeatItem ? "repeat.1" : "repeat"
        let shuffleImgName = "shuffle"
        
        let repeatImgColor: NSColor = pref.repeatMode == .noRepeat ? .systemGray : .nColor
        let shuffleImgColor: NSColor = pref.shuffleMode == .noShuffle ? .systemGray : .nColor

        var repeatImage = NSImage(named: .init(repeatImgName))
        var shuffleImage = NSImage(named: .init(shuffleImgName))
        
        if #available(macOS 11.0, *) {
            repeatImage = repeatImage?.withSymbolConfiguration(.init(scale: .large))
            shuffleImage = shuffleImage?.withSymbolConfiguration(.init(scale: .large))
        }
        
        repeatModeButton.image = repeatImage?.tint(color: repeatImgColor)
        shuffleModeButton.image = shuffleImage?.tint(color: shuffleImgColor)
        
        PlayCore.shared.updateRepeatShuffleMode()
    }
    
    func artistButtonsViewController() -> ArtistButtonsViewController? {
        let vc = children.compactMap {
            $0 as? ArtistButtonsViewController
        }.first
        return vc
    }
    
    deinit {
        playProgressObserver?.invalidate()
        pauseStautsObserver?.invalidate()
        previousButtonObserver?.invalidate()
//        muteStautsObserver?.invalidate()
        currentTrackObserver?.invalidate()
        fmModeObserver?.invalidate()
    }
    
}

extension ControlBarViewController {
    
    override func mouseEntered(with event: NSEvent) {
        guard let userInfo = event.trackingArea?.userInfo as? [String: Int],
              userInfo["obj"] == 0 else {
            return
        }
        durationSlider.mouseIn = true
    }
    
    override func mouseExited(with event: NSEvent) {
        guard let userInfo = event.trackingArea?.userInfo as? [String: Int],
              userInfo["obj"] == 0 else {
            return
        }
        durationSlider.mouseIn = false
    }
    
}

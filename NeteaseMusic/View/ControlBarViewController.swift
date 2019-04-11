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

    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var pauseButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var muteButton: NSButton!
    
    @IBAction func controlAction(_ sender: NSButton) {
        let player = PlayCore.shared.player
        switch sender {
        case previousButton:
            break
        case pauseButton:
            guard player.error == nil else { return }
            if player.rate == 0 {
                player.play()
            } else {
                player.pause()
            }
        case nextButton:
            break
        case muteButton:
            player.isMuted = !player.isMuted
            
            sender.title = player.isMuted ? "Muted" : ""
        default:
            break
        }
    }
    
    @IBOutlet weak var durationSlider: NSSlider!
    @IBOutlet weak var durationTextField: NSTextField!
    @IBOutlet weak var volumeSlider: NSSlider!
    
    @IBAction func sliderAction(_ sender: NSSlider) {
        switch sender {
        case durationSlider:
            PlayCore.shared.player.pause()
            let time = CMTime(seconds: sender.doubleValue, preferredTimescale: 1000)
            PlayCore.shared.player.seek(to: time) { re in
                PlayCore.shared.player.play()
            }
        case volumeSlider:
            PlayCore.shared.player.volume = volumeSlider.floatValue
        default:
            break
        }
    }
    
    var periodicTimeObserverToken: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        volumeSlider.maxValue = 1
        volumeSlider.floatValue = PlayCore.shared.player.volume
    }
    
    func addPeriodicTimeObserver() {
        // Notify every half second
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.25, preferredTimescale: timeScale)
        periodicTimeObserverToken = PlayCore.shared.player
            .addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
                guard let duration = PlayCore.shared.player.currentItem?.asset.duration else { return }
                
                let periodicSec = Double(CMTimeGetSeconds(time))
                self?.durationSlider.doubleValue = periodicSec
                
                let durationSec = Double(CMTimeGetSeconds(duration))
                if durationSec != self?.durationSlider.maxValue {
                    self?.durationSlider.maxValue = durationSec
                }
                
                self?.durationTextField.stringValue = "\(periodicSec.durationFormatter()) / \(durationSec.durationFormatter())"
        }
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = periodicTimeObserverToken {
            PlayCore.shared.player.removeTimeObserver(timeObserverToken)
            self.periodicTimeObserverToken = nil
        }
    }
    
    deinit {
        removePeriodicTimeObserver()
    }
    
}

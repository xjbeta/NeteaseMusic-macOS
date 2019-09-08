//
//  PlayingSongViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/22.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import AVFoundation
import PromiseKit

class PlayingSongViewController: NSViewController {
    @IBOutlet weak var visualEffectView: NSVisualEffectView!
    @IBOutlet weak var cdRunImageView: NSImageView!
    @IBOutlet weak var cdwarpImageView: NSImageView!
    @IBOutlet weak var cdImgImageView: NSImageView!
    
    @IBOutlet weak var lyricContainerView: NSView!
    @IBOutlet weak var offsetTextField: NSTextField!
    @IBOutlet weak var offsetUpButton: NSButton!
    @IBOutlet weak var offsetDownButton: NSButton!
    @IBAction func offset(_ sender: NSButton) {
        // 0.1s  0.5s
        let v = NSEvent.modifierFlags.contains(.option) ? 100 : 500

        switch sender {
        case offsetUpButton:
            lyricOffset -= v
        case offsetDownButton:
            lyricOffset += v
        default:
            break
        }
        
        let time = PlayCore.shared.player.currentTime()
        lyricViewController()?.updateLyric(time)
    }
    
    // lyricOffset ms
    @objc dynamic var lyricOffset = 0 {
        didSet {
            lyricViewController()?.lyricOffset = lyricOffset
        }
    }
    
    var currentTrackObserver: NSKeyValueObservation?
    var playerStatueObserver: NSKeyValueObservation?
    var viewStatusObserver: NSObjectProtocol?
    var fmModeObserver: NSKeyValueObservation?
    var viewFrameObserver: NSKeyValueObservation?
    var viewStatus: ExtendedViewState = .unkonwn
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentTrackObserver = PlayCore.shared.observe(\.currentTrack, options: [.initial, .new]) { [weak self] playcore, _ in
            self?.initView()
        }
        
        playerStatueObserver = PlayCore.shared.player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] (player, changes) in
            switch player.timeControlStatus {
            case .playing:
                self?.cdwarpImageView.resumeAnimation()
                self?.cdImgImageView.resumeAnimation()
                self?.updateCDRunImage()
            case .paused:
                self?.cdwarpImageView.pauseAnimation()
                self?.cdImgImageView.pauseAnimation()
                self?.updateCDRunImage()
            default:
                break
            }
        }
        
        viewStatusObserver = NotificationCenter.default.addObserver(forName: .playingSongViewStatus, object: nil, queue: .main) { [weak self] in
            guard let dic = $0.userInfo as? [String: ExtendedViewState],
                let status = dic["status"] else {
                    self?.viewStatus = .unkonwn
                    return
            }
            self?.viewStatus = status
            
            switch status {
            case .display:
                self?.initView()
                after(seconds: 0.1).done {
                    // Fix rotation problem after display
                    self?.cdwarpImageView.setAnchorPoint(anchorPoint: .init(x: 0.5, y: 0.5))
                    self?.cdImgImageView.setAnchorPoint(anchorPoint: .init(x: 0.5, y: 0.5))
                }
            default:
                self?.cdwarpImageView.layer?.removeAllAnimations()
                self?.cdImgImageView.layer?.removeAllAnimations()
            }
        }
        
        fmModeObserver = PlayCore.shared.observe(\.fmMode, options: [.initial, .new]) { [weak self] (playcore, _) in
            guard let vc = self?.lyricViewController() else { return }
            if !playcore.fmMode {
                vc.addPeriodicTimeObserver(playcore.player)
            } else {
                vc.removePeriodicTimeObserver(playcore.player)
            }
        }
        
        viewFrameObserver = view.observe(\.frame, options: [.initial, .new]) { [weak self] (_, changes) in
            guard let status = self?.viewStatus, status == .display else { return }
            
            self?.cdwarpImageView.setAnchorPoint(anchorPoint: .init(x: 0.5, y: 0.5))
            self?.cdImgImageView.setAnchorPoint(anchorPoint: .init(x: 0.5, y: 0.5))
        }
    }
    
    func initView() {
        guard let track = PlayCore.shared.currentTrack else {
            cdImgImageView.image = nil
            lyricViewController()?.currentLyricId = -1
            songButtonsViewController()?.trackId = -1
            return
        }
        
        if let u = track.album.picUrl {
            cdImgImageView.wantsLayer = true
            cdImgImageView.layer?.cornerRadius = cdImgImageView.frame.width / 2
            cdImgImageView.setImage(u.absoluteString, true)
            cdwarpImageView.wantsLayer = true
            cdwarpImageView.rotate()
            cdImgImageView.rotate()
        } else {
            cdImgImageView.image = nil
        }

        songInfoViewController()?.initInfos(track)
        songButtonsViewController()?.trackId = track.id
        lyricViewController()?.currentLyricId = track.id
    }
    
    
    func updateCDRunImage() {
        cdRunImageView.wantsLayer = true
        guard let layer = cdRunImageView.layer else { return }
        var toValue: Double = 0
        var fromValue: Double = 0
        let value = Double.pi / 5.3
        switch PlayCore.shared.player.timeControlStatus {
        case .playing:
            fromValue = value
        case .paused:
            toValue = value
        default:
            layer.removeAllAnimations()
            return
        }
        
        let frame = cdRunImageView.frame
        let rotationPoint = CGPoint(x: frame.origin.x + 27,
                                    y: frame.origin.y + frame.height - 26.5)
        
        layer.anchorPoint = CGPoint(x: (rotationPoint.x - frame.minX) / frame.width,
                                    y: (rotationPoint.y - frame.minY) / frame.height)
        layer.position = rotationPoint
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = NSNumber(value: fromValue)
        rotation.toValue = NSNumber(value: toValue)
        rotation.duration = 0.35
        rotation.fillMode = .forwards
        rotation.isRemovedOnCompletion = false
        layer.removeAllAnimations()
        layer.add(rotation, forKey: "rotationAnimation")
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
    
    deinit {
        currentTrackObserver?.invalidate()
        playerStatueObserver?.invalidate()
        fmModeObserver?.invalidate()
        viewFrameObserver?.invalidate()
        lyricViewController()?.removePeriodicTimeObserver(PlayCore.shared.player)
        if let obs = viewStatusObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

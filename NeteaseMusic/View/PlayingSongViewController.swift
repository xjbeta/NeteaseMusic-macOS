//
//  PlayingSongViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/22.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PlayingSongViewController: NSViewController {
    @IBOutlet weak var visualEffectView: NSVisualEffectView!
    @IBOutlet weak var cdRunImageView: NSImageView!
    @IBOutlet weak var cdwarpImageView: NSImageView!
    @IBOutlet weak var cdImgImageView: NSImageView!
    
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var secondTitleTextField: NSTextField!
    
    var currentTrackObserver: NSKeyValueObservation?
    var playerStatueObserver: NSKeyValueObservation?
    var viewStatusObserver: NSObjectProtocol?
    
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
                    return
            }
            switch status {
            case .display:
                self?.initView()
            default:
                self?.cdwarpImageView.layer?.removeAllAnimations()
                self?.cdImgImageView.layer?.removeAllAnimations()
            }
        }
    }
    
    func initView() {
        guard let track = PlayCore.shared.currentTrack else { return }
        
        if let urlStr = track.al.picUrl?.absoluteString,
            let u = URL(string: urlStr.replacingOccurrences(of: "http://", with: "https://")),
            let image = NSImage(contentsOf: u) {
            cdImgImageView.wantsLayer = true
            cdImgImageView.layer?.cornerRadius = cdImgImageView.frame.width / 2
            cdImgImageView.image = image
            cdwarpImageView.rotate()
            cdImgImageView.rotate()
        } else {
            cdImgImageView.image = nil
        }

        
        titleTextField.stringValue = track.name
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
        rotation.duration = 0.5
        rotation.fillMode = .forwards
        rotation.isRemovedOnCompletion = false
        layer.removeAllAnimations()
        layer.add(rotation, forKey: "rotationAnimation")
    }
    
    deinit {
        currentTrackObserver?.invalidate()
        playerStatueObserver?.invalidate()
        if let obs = viewStatusObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

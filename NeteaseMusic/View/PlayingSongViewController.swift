//
//  PlayingSongViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/22.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import AVFoundation

class PlayingSongViewController: NSViewController {
    @IBOutlet weak var visualEffectView: NSVisualEffectView!
    @IBOutlet weak var cdRunImageView: NSImageView!
    @IBOutlet weak var cdwarpImageView: NSImageView!
    @IBOutlet weak var cdImgImageView: NSImageView!
    
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var secondTitleTextField: NSTextField!
    
    @IBOutlet weak var lyricTableView: NSTableView!
    @IBOutlet weak var lyricScrollView: NSScrollView!
    struct Lyricline {
        enum LyricType {
            case first, second
        }
        
        let string: String
        var time: LyricTime
        let type: LyricType
    }
    var lyriclines = [Lyricline]()
    var currentLyricId = -1
    
    var currentTrackObserver: NSKeyValueObservation?
    var playerStatueObserver: NSKeyValueObservation?
    var viewStatusObserver: NSObjectProtocol?
    var periodicTimeObserverToken: Any?
    
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
        
        addPeriodicTimeObserver()
        lyricTableView.refusesFirstResponder = true
    }
    
    func initView() {
        guard let track = PlayCore.shared.currentTrack else {
            lyriclines.removeAll()
            lyricTableView.reloadData()
            cdImgImageView.image = nil
            return
        }
        
        if let urlStr = track.album.picUrl?.absoluteString,
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
        
        guard currentLyricId != track.id else { return }
        currentLyricId = track.id
        lyriclines.removeAll()
        lyricTableView.reloadData()
        PlayCore.shared.api.lyric(track.id).map {
            guard self.currentLyricId == PlayCore.shared.currentTrack?.id else { return }
            self.initLyric(lyric: $0)
            }.done(on: .main) {
                self.lyricTableView.reloadData()
            }.catch {
                print($0)
        }
    }
    
    func initLyric(lyric: LyricResult) {
        lyriclines.removeAll()
        if let nolyric = lyric.nolyric, nolyric {
            print("nolyric")
        } else if let uncollected = lyric.uncollected, uncollected {
            print("uncollected")
        } else if let lyricStr = lyric.lrc?.lyric {
            lyriclines.append(contentsOf: Lyric(lyricStr).lyrics.map({ Lyricline(string: $0.1, time: $0.0, type: .first) }))
            lyriclines.append(contentsOf: Lyric(lyric.tlyric?.lyric ?? "").lyrics.map({ Lyricline(string: $0.1, time: $0.0, type: .second) }))
        }
        
        lyriclines.sort {
            return $0.type == .first && $1.type == .second
        }
        
        lyriclines.sort {
            return $0.time.totalMS < $1.time.totalMS
        }
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
    
    func addPeriodicTimeObserver() {
        // Notify every half second
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.25, preferredTimescale: timeScale)
        periodicTimeObserverToken = PlayCore.shared.player
            .addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
                let periodicMS = Int(CMTimeGetSeconds(time) * 1000)
                
                if let line = self?.lyriclines.filter({ $0.time.totalMS < periodicMS }).last,
                    let offsets = self?.lyriclines.enumerated().filter({ $0.element.time == line.time }).map({ $0.offset }) {
                    self?.updateLyricTableView(offsets)
                }
        }
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = periodicTimeObserverToken {
            PlayCore.shared.player.removeTimeObserver(timeObserverToken)
            self.periodicTimeObserverToken = nil
        }
    }
    
    func updateLyricTableView(_ offsets: [Int]) {
        let indexSet = IndexSet(offsets)
        guard lyricTableView.selectedRowIndexes != indexSet else { return }
        lyricTableView.deselectAll(nil)
        lyricTableView.selectRowIndexes(indexSet, byExtendingSelection: true)
        
        guard let i = offsets.first else { return }
        
        let frame = lyricTableView.frameOfCell(atColumn: 0, row: i)
        let y = frame.midY - lyricScrollView.frame.height / 2
        lyricScrollView.verticalScroller?.isEnabled = false
        lyricTableView.scroll(.init(x: 0, y: y))
        lyricScrollView.verticalScroller?.isEnabled = true
    }
    
    deinit {
        currentTrackObserver?.invalidate()
        playerStatueObserver?.invalidate()
        removePeriodicTimeObserver()
        if let obs = viewStatusObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

extension PlayingSongViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return lyriclines.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var rowHeight = tableView.rowHeight
        let fixedHeight: CGFloat = 12
        
        if let line = lyriclines[safe: row],
            let nextLine = lyriclines[safe: row + 1] {
            if line.type == .second {
                rowHeight += fixedHeight
            } else if line.type == nextLine.type, line.type == .first {
                rowHeight += fixedHeight
            }
        }
        return rowHeight
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let type = lyriclines[safe: row]?.type else { return nil }
        switch type {
        case .first:
            return tableView.makeView(withIdentifier: .init("LyricTableCellView"), owner: nil)
        case .second:
            return tableView.makeView(withIdentifier: .init("LyricSecondTableCellView"), owner: nil)
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return lyriclines[safe: row]?.string
    }
}

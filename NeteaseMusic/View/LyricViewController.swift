//
//  LyricViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import AVFoundation

class LyricViewController: NSViewController {
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var textField: NSTextField!
    
    var mouseInLyric = false
    var autoScrollLyrics = true
    
    struct Lyricline {
        enum LyricType {
            case first, second, both
        }
        
        var stringF: String?
        var stringS: String?
        let time: LyricTime
        var type: LyricType
        var highlighted = false
    }
    var lyriclines = [Lyricline]()
    var currentLyricId = -1 {
        willSet {
            guard newValue != currentLyricId else { return }
            tableView.scrollToBeginningOfDocument(nil)
            
            if newValue == -1 {
                // reset views
                lyriclines.removeAll()
                tableView.reloadData()
            } else {
                getLyric(for: newValue)
            }
        }
    }
    
    // lyricOffset ms
    @objc dynamic var lyricOffset = 0
    
    var playProgressObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.isHidden = true
        tableView.refusesFirstResponder = true
        

        initTrackingArea()
    }
    
    
    
    func updateLyric(_ time: Double) {
        var periodicMS = Int(time * 1000)
        periodicMS += lyricOffset

        guard let line = lyriclines.filter({ $0.time.totalMS < periodicMS }).last else {
            return
        }
        let lins = lyriclines.enumerated().filter({ $0.element.time == line.time }).filter({ !($0.element.stringF ?? "").isEmpty })
        guard lins.count > 0 else { return }

        var offsets = lins.map({ $0.offset })

        lyriclines.enumerated().forEach {
            lyriclines[$0.offset].highlighted = offsets.contains($0.offset)
            if $0.element.highlighted, !offsets.contains($0.offset) {
                offsets.append($0.offset)
            }
        }
        let indexSet = IndexSet(offsets)
        tableView.reloadData(forRowIndexes: indexSet, columnIndexes: .init(integer: 0))
        guard let i = offsets.first, autoScrollLyrics else { return }

        let frame = tableView.frameOfCell(atColumn: 0, row: i)
        let y = frame.midY - scrollView.frame.height / 2
        NSAnimationContext.runAnimationGroup { [weak self] (context) in
            context.allowsImplicitAnimation = true
            self?.tableView.animator().scroll(.init(x: 0, y: y))
        }
    }
    
    func getLyric(for id: Int) {
        PlayCore.shared.api.lyric(id).map {
            guard self.currentLyricId == id else { return }
            self.initLyric(lyric: $0)
            }.done(on: .main) {
                self.tableView.reloadData()
            }.catch {
                Log.error($0)
        }
    }
    
    func initLyric(lyric: LyricResult) {
        lyriclines.removeAll()
        textField.isHidden = true
        if let nolyric = lyric.nolyric, nolyric {
            textField.isHidden = false
            textField.stringValue = "no lyric"
        } else if let uncollected = lyric.uncollected, uncollected {
            textField.isHidden = false
            textField.stringValue = "uncollected"
        } else {
            if let lyricStr = lyric.lrc?.lyric {
                let linesF = Lyric(lyricStr).lyrics.map {
                    Lyricline(stringF: $0.1, stringS: nil, time: $0.0, type: .first)
                }
                lyriclines.append(contentsOf: linesF)
            }
            
            Lyric(lyric.tlyric?.lyric ?? "").lyrics.forEach { l in
                if let i = lyriclines.enumerated().first(where: { $0.element.time == l.0 })?.offset {
                    lyriclines[i].type = .both
                    lyriclines[i].stringS = l.1
                } else if !l.1.isEmpty {
                    let line = Lyricline(stringF: nil, stringS: l.1, time: l.0, type: .second)
                    lyriclines.append(line)
                }
            }
        }
        
        lyriclines.sort {
            return $0.type == .first && $1.type == .second
        }
        
        lyriclines.sort {
            return $0.time.totalMS < $1.time.totalMS
        }
    }
    
    func addPlayProgressObserver() {
        let pc = PlayCore.shared
        guard playProgressObserver == nil else { return }
        playProgressObserver = pc.observe(\.playProgress, options: [.initial, .new]) { [weak self] pc, _ in
            let time = pc.player.currentDuration
            self?.updateLyric(time)
        }
    }
    
    func removePlayProgressObserver() {
        playProgressObserver?.invalidate()
        playProgressObserver = nil
    }
    
    func initTrackingArea() {
        scrollView.addTrackingArea(.init(
            rect: scrollView.bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp, .mouseMoved],
            owner: self,
            userInfo: nil))
        
        NotificationCenter.default.addObserver(self, selector: #selector(scrollViewDidScroll(_:)), name: NSScrollView.didLiveScrollNotification, object: scrollView)
        
    }
    
    override func mouseEntered(with event: NSEvent) {
        mouseInLyric = true
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseInLyric = false
        autoScrollLyrics = true
        let time = PlayCore.shared.player.currentDuration
        updateLyric(time)
    }
    
    
    @objc func scrollViewDidScroll(_ notification: Notification) {
        guard let sv = notification.object as? NSScrollView,
              sv == scrollView else {
                  return
              }
        
        if mouseInLyric,
           autoScrollLyrics {
            autoScrollLyrics = false
        }
    }
    
}


extension LyricViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return lyriclines.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let line = lyriclines[safe: row] else { return nil }
        let sStr = line.stringS ?? ""
        
        let fSize = line.highlighted ? 14 : 13
        let sSize = line.highlighted ? 13 : 12
        
        let fColor = line.highlighted ? NSColor.nColor : NSColor.labelColor
        let sColor = line.highlighted ? NSColor.nColor : NSColor.secondaryLabelColor
        
        return ["firstString": line.stringF ?? "",
                "firstSize": fSize,
                "firstColor": fColor,
                "secondString": sStr,
                "secondSize": sSize,
                "secondColor": sColor,
                "hideSecond": sStr.isEmpty]
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}

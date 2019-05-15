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
    
    struct Lyricline {
        enum LyricType {
            case first, second
        }
        
        let string: String
        var time: LyricTime
        let type: LyricType
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
    
    var periodicTimeObserverToken: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.isHidden = true
        tableView.refusesFirstResponder = true
    }
    
    func updateLyric(_ time: CMTime) {
        var periodicMS = Int(CMTimeGetSeconds(time) * 1000)
        periodicMS += lyricOffset
        
        guard let line = lyriclines.filter({ $0.time.totalMS < periodicMS }).last else {
            return
        }
        let lins = lyriclines.enumerated().filter({ $0.element.time == line.time }).filter({ !$0.element.string.isEmpty })
        guard lins.count > 0 else { return }
        
        let offsets = lins.map({ $0.offset })
        
        let indexSet = IndexSet(offsets)
        guard tableView.selectedRowIndexes != indexSet else { return }
        tableView.deselectAll(nil)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: true)
        
        guard let i = offsets.first else { return }
        
        let frame = tableView.frameOfCell(atColumn: 0, row: i)
        let y = frame.midY - scrollView.frame.height / 2
        scrollView.verticalScroller?.isEnabled = false
        NSAnimationContext.runAnimationGroup({ [weak self] (context) in
            context.allowsImplicitAnimation = true
            self?.tableView.animator().scroll(.init(x: 0, y: y))
        }) { [weak self] in
            self?.scrollView.verticalScroller?.isEnabled = true
        }
    }
    
    func getLyric(for id: Int) {
        PlayCore.shared.api.lyric(id).map {
            guard self.currentLyricId == id else { return }
            self.initLyric(lyric: $0)
            }.done(on: .main) {
                self.tableView.reloadData()
            }.catch {
                print($0)
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
    
    func addPeriodicTimeObserver(_ player: AVPlayer) {
        // Notify every half second
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.25, preferredTimescale: timeScale)
        periodicTimeObserverToken = player
            .addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
                self?.updateLyric(time)
        }
    }
    
    func removePeriodicTimeObserver(_ player: AVPlayer) {
        if let timeObserverToken = periodicTimeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.periodicTimeObserverToken = nil
        }
    }
    
    
}


extension LyricViewController: NSTableViewDelegate, NSTableViewDataSource {
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

//
//  Lyric.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/7.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class Lyric: NSObject {
    enum LyricTag: String {
        case artist = "ar"
        case album = "al"
        case title = "ti"
        case author = "au"
        case length
        case creater = "by"
        case offset
        case editor = "re"
        case version = "ve"
    }
    
    var tags = [LyricTag: String]()
    var lyrics = [(LyricTime, String)]()
    
    convenience init(_ lyricStr: String) {
        self.init()
        lyricStr.split(separator: "\n").map(String.init).forEach {
            var heads = [String]()
            var line = $0
            while line.starts(with: "["), line.contains("]") {
                let head = line.subString(from:"[", to: "]")
                heads.append(head)
                line = line.subString(from: "]")
            }
            
            if heads.count == 1, let h = heads.first {
                if let time = LyricTime(h) {
                    lyrics.append((time, line))
                } else {
                    let kv = h.split(separator: ":").map(String.init)
                    guard kv.count == 2 else { return }
                    if let str = kv.first,
                        let tag = LyricTag(rawValue: str) {
//TODO: - offset tag
                        tags[tag] = kv.last
                    }
                }
            } else {
                heads.compactMap {
                    LyricTime($0)
                }.forEach {
                    lyrics.append(($0, line))
                }
            }
        }
    }
}

struct LyricTime: Hashable {
    var minute: Int
    var second: Int
    var millisecond: Int
    var totalMS: Int
    
    init?(_ str: String) {
        let minS = str.split(separator: ":").map(String.init)
        guard minS.count == 2, let min = Int(minS.first ?? "") else { return nil }
        minute = min
        let sm = minS.last?.split(separator: ".").map(String.init)
        guard sm?.count == 2,
            let s = Int(sm?.first ?? ""),
            let ms = Int(sm?.last ?? "") else { return nil }
        second = s
        millisecond = ms
        totalMS = ((minute * 60) + second) * 1000 + millisecond
    }
}

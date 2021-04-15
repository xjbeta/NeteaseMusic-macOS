//
//  NeteasePlayerItem.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2020/8/14.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import AVFoundation

class NeteasePlayerItem: AVPlayerItem {
    enum State {
        case unknown, downloading, downloadFinished
    }
    
    var id: Int = -1
    var url: String = ""
    let date = Date()
    var expi: Int = -1
    var type: String = ""
    
    var downloadState: State = .unknown
    
    var expired: Bool {
        get {
            return (Int(date.timeIntervalSinceNow) + expi) < 30
        }
    }
}

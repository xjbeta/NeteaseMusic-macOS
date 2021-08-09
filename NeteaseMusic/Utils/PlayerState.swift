//
//  PlayerState.swift
//  NeteaseMusic
//
//  Created by xjbeta on 8/9/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Cocoa

@objc enum PlayerState: Int {
    case retrievingURL
    case stopped
    case buffering
    case playing
    case paused
    case seeking
    case endOfFile
    case failed
    case retryingStarted
    case retryingSucceeded
    case retryingFailed
    case playbackCompleted
    case unknown
    
    var debug: String {
        get {
            switch self {
            case .retrievingURL: return "retrievingURL"
            case .stopped: return "stopped"
            case .buffering: return "buffering"
            case .playing: return "playing"
            case .paused: return "paused"
            case .seeking: return "seeking"
            case .endOfFile: return "endOfFile"
            case .failed: return "failed"
            case .retryingStarted: return "retryingStarted"
            case .retryingSucceeded: return "retryingSucceeded"
            case .retryingFailed: return "retryingFailed"
            case .playbackCompleted: return "playbackCompleted"
            case .unknown: return "unknown"
            }
        }
    }
}

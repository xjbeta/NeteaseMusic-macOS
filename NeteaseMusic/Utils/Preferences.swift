//
//  Preferences.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/19.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class Preferences: NSObject {
    static let shared = Preferences()
    
    private override init() {
    }
    let prefs = UserDefaults.standard
    let keys = PreferenceKeys.self
    
    enum RepeatMode: Int {
        case noRepeat, repeatPlayList, repeatItem
    }
    enum ShuffleMode: Int {
        case noShuffle, shuffleItems, shuffleAlbums
    }
    
    var repeatMode: RepeatMode {
        get {
            guard let i = defaults(.repeatMode) as? Int,
                let mode = RepeatMode(rawValue: i) else {
                return .noRepeat
            }
            return mode
        }
        set {
            defaultsSet(newValue.rawValue, forKey: .repeatMode)
        }
    }
    
    var shuffleMode: ShuffleMode {
        get {
            guard let i = defaults(.shuffleMode) as? Int,
                let mode = ShuffleMode(rawValue: i) else {
                    return .noShuffle
            }
            return mode
        }
        set {
            defaultsSet(newValue.rawValue, forKey: .shuffleMode)
        }
    }
    
    
    var volume: Float {
        get {
            return defaults(.volume) as? Float ?? 1
        }
        set {
            defaultsSet(newValue, forKey: .volume)
        }
    }
    
    var mute: Bool {
        get {
            return defaults(.mute) as? Bool ?? false
        }
        set {
            defaultsSet(newValue, forKey: .mute)
        }
    }
    
    
    
    
}

private extension Preferences {
    
    func defaults(_ key: PreferenceKeys) -> Any? {
        return prefs.value(forKey: key.rawValue) as Any?
    }
    
    func defaultsSet(_ value: Any, forKey key: PreferenceKeys) {
        prefs.setValue(value, forKey: key.rawValue)
    }
}

enum PreferenceKeys: String {
    case volume
    case mute
    case repeatMode
    case shuffleMode
}

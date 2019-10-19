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
        
        let commandStr = "\(NSEvent.ModifierFlags(arrayLiteral: [.command]).rawValue)"
        let commandOptionStr = "\(NSEvent.ModifierFlags(arrayLiteral: [.command, .option]).rawValue)"
        let commandControlStr = "\(NSEvent.ModifierFlags(arrayLiteral: [.command, .control]).rawValue)"
        
        defaultPreferencesHotKeys =
            // Space
            [.play: ["keyCode": "49"],
             // ⌥⌘Space
                .playGlobal: ["flags": commandOptionStr, "keyCode": "49"],
                // ⌘←
                .pre: ["flags": commandStr, "keyCode": "123"],
                // ⌥⌘←
                .preGlobal: ["flags": commandOptionStr, "keyCode": "123"],
                // ⌘→
                .next: ["flags": commandStr, "keyCode": "124"],
                // ⌥⌘→
                .nextGlobal: ["flags": commandOptionStr, "keyCode": "124"],
                // ⌘↑
                .volumeUp: ["flags": commandStr, "keyCode": "126"],
                // ⌥⌘↑
                .volumeUpGlobal: ["flags": commandOptionStr, "keyCode": "126"],
                // ⌘↓
                .volumeDown: ["flags": commandStr, "keyCode": "125"],
                // ⌥⌘↓
                .volumeDownGlobal: ["flags": commandOptionStr, "keyCode": "125"],
                // ⌘L
                .like: ["flags": commandStr, "keyCode": "37"],
                // ⌥⌘L
                .likeGlobal: ["flags": commandOptionStr, "keyCode": "37"],
                // ⌘R
                .lyric: ["flags": commandStr, "keyCode": "15"],
                // ⌥⌘R
                .lyricGlobal: ["flags": commandOptionStr, "keyCode": "15"],
                // ⌃⌘M
                .mini: ["flags": commandControlStr, "keyCode": "46"],
                .miniGlobal: ["flags": "", "keyCode": ""]]
        
    }
    let prefs = UserDefaults.standard
    let keys = PreferenceKeys.self
    
    enum RepeatMode: Int {
        case noRepeat, repeatPlayList, repeatItem
    }
    enum ShuffleMode: Int {
        case noShuffle, shuffleItems, shuffleAlbums
    }
    
    var defaultPreferencesHotKeys: [PreferencesKeyEquivalents: [String: String]]
    
    var hotKeys: [PreferencesKeyEquivalents : [String : String]] {
        get {
            if let hotKeys = defaults(.hotKeys) as? [String: [String: String]] {
                var dic: [PreferencesKeyEquivalents : [String : String]] = [:]
                hotKeys.forEach {
                    if let key = PreferencesKeyEquivalents(rawValue: $0.key) {
                        dic[key] = $0.value
                    }
                }
                return dic
            } else {
                return defaultPreferencesHotKeys
            }
        }
        
        set {
            var dic: [String : [String : String]] = [:]
            newValue.forEach {
                dic[$0.key.rawValue] = $0.value
            }
            defaultsSet(dic, forKey: .hotKeys)
        }
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
    case hotKeys
}

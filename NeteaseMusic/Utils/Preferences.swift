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
            [.play: .init(flags: nil, keyCode: "49"),
            // ⌥⌘Space
               .playGlobal: .init(flags: commandOptionStr, keyCode: "49"),
               // ⌘←
               .pre: .init(flags: commandStr, keyCode: "123"),
               // ⌥⌘←
               .preGlobal: .init(flags: commandOptionStr, keyCode: "123"),
               // ⌘→
               .next: .init(flags: commandStr, keyCode: "124"),
               // ⌥⌘→
               .nextGlobal: .init(flags: commandOptionStr, keyCode: "124"),
               // ⌘↑
               .volumeUp: .init(flags: commandStr, keyCode: "126"),
               // ⌥⌘↑
               .volumeUpGlobal: .init(flags: commandOptionStr, keyCode: "126"),
               // ⌘↓
               .volumeDown: .init(flags: commandStr, keyCode: "125"),
               // ⌥⌘↓
               .volumeDownGlobal: .init(flags: commandOptionStr, keyCode: "125"),
               // ⌘L
               .like: .init(flags: commandStr, keyCode: "37"),
               // ⌥⌘L
               .likeGlobal: .init(flags: commandOptionStr, keyCode: "37"),
               // ⌘R
               .lyric: .init(flags: commandStr, keyCode: "15"),
               // ⌥⌘R
               .lyricGlobal: .init(flags: commandOptionStr, keyCode: "15"),
               // ⌃⌘M
               .mini: .init(flags: commandControlStr, keyCode: "46"),
               .miniGlobal: .init(flags: "", keyCode: "")]
        
    }
    let prefs = UserDefaults.standard
    let keys = PreferenceKeys.self
    
    enum RepeatMode: Int {
        case noRepeat, repeatPlayList, repeatItem
    }
    enum ShuffleMode: Int {
        case noShuffle, shuffleItems, shuffleAlbums
    }
    
    var defaultPreferencesHotKeys: [PreferencesKeyEquivalents: PreferencesKeyEvent]
    
    var hotKeys: [PreferencesKeyEquivalents: PreferencesKeyEvent] {
        get {
            if let hotKeys = defaults(.hotKeys) as? [String: [String: String]] {
                var dic = [PreferencesKeyEquivalents: PreferencesKeyEvent]()
                hotKeys.forEach {
                    if let key = PreferencesKeyEquivalents(rawValue: $0.key) {
                        dic[key] = .init(flags: $0.value["flags"], keyCode: $0.value["keyCode"])
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
                var d = [String : String]()
                d["flags"] = $0.value.flags
                d["keyCode"] = $0.value.keyCode
                dic[$0.key.rawValue] = d
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
    
    var enableGlobalHotKeys: Bool {
        get {
            return defaults(.enableGlobalHotKeys) as? Bool ?? false
        }
        set {
            defaultsSet(newValue, forKey: .enableGlobalHotKeys)
        }
    }
    
    var useSystemMediaControl: Bool {
        get {
            return defaults(.enableSystemMediaKeys) as? Bool ?? false
        }
        set {
            defaultsSet(newValue, forKey: .enableSystemMediaKeys)
        }
    }
    
    var musicBitRate: MusicBitRate {
        get {
            let i = defaults(.musicBitRate) as? Int ?? MusicBitRate.best.rawValue
            return MusicBitRate(rawValue: i) ?? .best
        }
        set {
            defaultsSet(newValue.rawValue, forKey: .musicBitRate)
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
    case enableGlobalHotKeys
    case enableSystemMediaKeys
    case musicBitRate
}

struct PreferencesKeyEvent {
    var flags: String?
    var keyCode: String?
}

enum MusicBitRate: Int {
    case 🎹192kbps = 192000
    case 🎹320kbps = 320000
    case best = 999000
}

enum PreferencesKeyEquivalents: String {
    case play
    case playGlobal
        
    case pre
    case preGlobal
        
    case next
    case nextGlobal
        
    case volumeUp
    case volumeUpGlobal
        
    case volumeDown
    case volumeDownGlobal
        
    case like
    case likeGlobal
    
    case lyric
    case lyricGlobal
    
    case mini
    case miniGlobal
    
    func isGlobal() -> Bool {
        return self.rawValue.contains("Global")
    }
}

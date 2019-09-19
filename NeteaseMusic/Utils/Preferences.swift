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

}

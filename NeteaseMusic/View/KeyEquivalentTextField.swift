//
//  TestTextField.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/23.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import HotKey

protocol KeyEquivalentTextFieldDelegate {
    func keyEquivalentDidChanged(_ keyEquivalent: PreferencesKeyEvent, _ textField: KeyEquivalentTextField)
    func keyEquivalentChangeFailed(_ reason: KeyEquivalentChangeFailureReason, _ textField: KeyEquivalentTextField)
}

enum KeyEquivalentChangeFailureReason {
    case withoutFlags
    case withoutKeyCode
    case invalidKeyEquivalent
}

class KeyEquivalentTextField: NSTextField {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    var keyEquivalent: PreferencesKeyEvent?
    var keyEquivalentDelegate: KeyEquivalentTextFieldDelegate?
    var isGlobal = false
    var isFirstResponder = false
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isFirstResponder else { return false }

        if event.modifierFlags.rawValue == 256, event.keyCode == 53 {
//            256 + 53 = esc
            self.window?.makeFirstResponder(self.window)
            return true
        }
        
        let modifierFlags = event.modifierFlags
        var flags = NSEvent.ModifierFlags()
        
        if modifierFlags.contains(.control) {
            flags.insert(.control)
        }
        if modifierFlags.contains(.option) {
            flags.insert(.option)
        }
        if modifierFlags.contains(.command) {
            flags.insert(.command)
        }
        if modifierFlags.contains(.shift) {
            flags.insert(.shift)
        }
        
        guard let k = Key(carbonKeyCode: UInt32(event.keyCode)) else {
                 keyEquivalentDelegate?.keyEquivalentChangeFailed(.withoutKeyCode, self)
                return false
        }
        
        if isGlobal, flags.rawValue == 0 {
            keyEquivalentDelegate?.keyEquivalentChangeFailed(.withoutFlags, self)
            return false
        }
        
        let f = NSEvent.ModifierFlags(arrayLiteral: flags)
        
        if !isValidKeyEquivalent(key: k, modifiers: f) {
            keyEquivalentDelegate?.keyEquivalentChangeFailed(.invalidKeyEquivalent, self)
            return false
        }
        
        let keyEquivalent = PreferencesKeyEvent(flags: "\(f.rawValue)", keyCode: "\(event.keyCode)")
        self.keyEquivalent = keyEquivalent
        keyEquivalentDelegate?.keyEquivalentDidChanged(keyEquivalent, self)
        return true
    }
    
    override func textShouldBeginEditing(_ textObject: NSText) -> Bool {
        guard let event = NSApp.currentEvent else { return false }
        // delete
        if event.keyCode == 51 {
            let keyEquivalent = PreferencesKeyEvent(flags: nil, keyCode: nil)
            self.keyEquivalent = keyEquivalent
            keyEquivalentDelegate?.keyEquivalentDidChanged(keyEquivalent, self)
        } else if event.modifierFlags.rawValue == 256 {
            let keyEquivalent = PreferencesKeyEvent(flags: nil, keyCode: "\(event.keyCode)")
            self.keyEquivalent = keyEquivalent
            keyEquivalentDelegate?.keyEquivalentDidChanged(keyEquivalent, self)
        }
        return false
    }
    
    func initStringValue() {
        guard let keyEquivalent = self.keyEquivalent,
            let keyCode = keyEquivalent.keyCode,
            let kCode = UInt16(keyCode),
            let k = keyCodeStr(kCode) else {
                stringValue = ""
                return
        }
        var str = ""
        if let flags = keyEquivalent.flags,
            let flagsUInt = UInt(flags) {
            let modifierFlags = NSEvent.ModifierFlags(rawValue: flagsUInt)
            if modifierFlags.contains(.control) {
                str += "⌃"
            }
            if modifierFlags.contains(.option) {
                str += "⌥"
            }
            if modifierFlags.contains(.command) {
                str += "⌘"
            }
            if modifierFlags.contains(.shift) {
                str += "⇧"
            }
        }
        
        str += k
        stringValue = str
    }
    
    func keyCodeStr(_ keyCode: UInt16) -> String? {
        // A ~ Z  , . / ; ' [ ] \ - = ·
        let keyCodes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 24, 27, 30, 31, 32, 33, 34, 35, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 50]
        switch keyCode {
        case 126:
            return "↑"
        case 125:
            return "↓"
        case 123:
            return "←"
        case 124:
            return "→"
        case 49:
            return "Space"
        case let code where keyCodes.contains(Int(code)):
            guard let key = Key(carbonKeyCode: UInt32(keyCode)) else {
                return nil
            }
            return key.description.uppercased()
        default:
            return nil
        }
    }
    
    func isValidKeyEquivalent(key: Key, modifiers: NSEvent.ModifierFlags) -> Bool {
        let kc = KeyCombo(key: key, modifiers: modifiers)
        guard !KeyCombo.standardKeyCombos().contains(kc) else {
            // standardKeyCombos
            return false
        }
        return true
    }
}

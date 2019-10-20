//
//  TestTextField.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/23.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

protocol KeyEquivalentTextFieldDelegate {
    func keyEquivalentDidChanged(_ keyEquivalent: NSEvent)
}

class KeyEquivalentTextField: NSTextField {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    var keyEquivalent: NSEvent?
    var keyEquivalentDelegate: KeyEquivalentTextFieldDelegate?
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard let window = window,
            let v = window.firstResponder as? NSTextView,
            subviews.first?.subviews.first == v else {
            return false
        }
        let modifierFlags = event.modifierFlags
        var str = ""
        if modifierFlags.contains(.capsLock) || modifierFlags.contains(.numericPad) || modifierFlags.contains(.help) || modifierFlags.contains(.function) {
            return false
        }
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

        guard str.count > 0,
            let keyCodeStr = keyCodeStr(event) else { return false }

        str += keyCodeStr
        self.stringValue = str
        self.keyEquivalent = event
        keyEquivalentDelegate?.keyEquivalentDidChanged(event)
        return true
    }
    
    override func textShouldBeginEditing(_ textObject: NSText) -> Bool {
        guard let event = NSApp.currentEvent else { return false }
        
        if event.keyCode == 51 {
            stringValue = ""
        } else if event.modifierFlags.rawValue == 256 {
            guard let keyCodeStr = keyCodeStr(event) else { return false }
            stringValue = keyCodeStr
        }
        return false
    }
    
    func keyCodeStr(_ event: NSEvent) -> String? {
        // A ~ Z  , . / ; ' [ ] \ - = ·
        let keyCodes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 24, 27, 30, 31, 32, 33, 34, 35, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 50]
        switch event.keyCode {
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
            return event.charactersIgnoringModifiers?.uppercased()
        default:
            return nil
        }
    }
}

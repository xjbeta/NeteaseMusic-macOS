//
//  PreferencesViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/19.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import HotKey

class PreferencesViewController: NSViewController {
    @IBOutlet weak var gridView: NSGridView!
    @IBOutlet weak var playTextField: KeyEquivalentTextField!
    @IBOutlet weak var playGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var preTextField: KeyEquivalentTextField!
    @IBOutlet weak var preGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var nextTextField: KeyEquivalentTextField!
    @IBOutlet weak var nextGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var volumeUpTextField: KeyEquivalentTextField!
    @IBOutlet weak var volumeUpGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var volumeDownTextField: KeyEquivalentTextField!
    @IBOutlet weak var volumeDownGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var likeTextField: KeyEquivalentTextField!
    @IBOutlet weak var likeGlobalTextField: KeyEquivalentTextField!
    
    
    
    @IBOutlet weak var resetKeyEquicalentButton: NSButton!
    @IBOutlet weak var enableGlobalButton: NSButton!
    @IBOutlet weak var enableSystemMediaButton: NSButton!
    
    @IBAction func buttonAction(_ sender: NSButton) {
        let pref = Preferences.shared
        let vcManager = ViewControllerManager.shared
        switch sender {
        case resetKeyEquicalentButton:
            UserDefaults.standard.removeObject(forKey: PreferenceKeys.hotKeys.rawValue)
            ViewControllerManager.shared.initAllHotKeys()
            initKeyEquivalentTextFields()
        case enableGlobalButton:
            pref.enableGlobalHotKeys = sender.state == .on
            initGlobalButtonState()
            vcManager.updateGlobalHotKeysState()
        case enableSystemMediaButton:
            pref.useSystemMediaControl = sender.state == .on
            let todo = "Update SystemMediaKeys state."
            
        default:
            break
        }
    }

    var sidebarItemObserver: NSKeyValueObservation?
    var firstResponderObserver: NSKeyValueObservation?
    let waitTimer = WaitTimer(timeOut: .milliseconds(100)) {
        DispatchQueue.main.async {
            let fr = NSApp.windows.first {
                $0.windowController is MainWindowController
            }?.firstResponder
            let vcManager = ViewControllerManager.shared
            if let tv = fr as? NSTextView,
                let keTV = tv.superview?.superview as? KeyEquivalentTextField {
                if !vcManager.hotKeysEnabled {
                    print("invalidateAllHotKeys")
                    vcManager.invalidateAllHotKeys()
                }
            } else {
                if vcManager.hotKeysEnabled {
                    print("initAllHotKeys")
                    vcManager.initAllHotKeys()
                }
            }
        }
    }
    
    var textFieldsDic = [KeyEquivalentTextField: PreferencesKeyEquivalents]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldsDic = [playTextField: .play,
                         playGlobalTextField: .playGlobal,
                
                         preTextField: .pre,
                         preGlobalTextField: .preGlobal,
                                
                         nextTextField: .next,
                         nextGlobalTextField: .nextGlobal,
                                
                         volumeUpTextField: .volumeUp,
                         volumeUpGlobalTextField: .volumeUpGlobal,
                                
                         volumeDownTextField: .volumeDown,
                         volumeDownGlobalTextField: .volumeDownGlobal,
                                
                         likeTextField: .like,
                         likeGlobalTextField: .likeGlobal,
                            
//            : .lyric,
//            : .lyricGlobal,
//
//            : .mini,
//            : .miniGlobal,
        ]
        
        initKeyEquivalentTextFields()
        initGlobalButtonState()
        
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { _, changes in
            guard let v = changes.newValue, let vv = v, vv.type == .preferences else {
                self.firstResponderObserver?.invalidate()
                self.waitTimer.run()
                return
            }
            
            self.firstResponderObserver = NSApp.windows.first {
                $0.windowController is MainWindowController
                }?.observe(\.firstResponder, options: [.initial, .old, .new]) { window, changes in
                    guard let n = changes.newValue, let o = changes.oldValue else {
                        return
                    }
                    
                    self.waitTimer.run()
                    
                    if let nn = n as? NSTextView,
                        let new = nn.superview?.superview as? KeyEquivalentTextField {
                        new.isFirstResponder = true
                    }
                    
                    if let oo = o as? NSTextView,
                        let old = oo.superview?.superview as? KeyEquivalentTextField {
                        old.isFirstResponder = false
                    }
            }
        }
    }
    
    func initKeyEquivalentTextFields() {
        gridView.subviews.compactMap {
            $0 as? KeyEquivalentTextField
        }.forEach {
            $0.placeholderString = "Empty"
            $0.keyEquivalentDelegate = self
            $0.delegate = self
            guard let key = textFieldsDic[$0] else {
                print("Can't find key in textFieldsDic.")
                return
            }
            $0.isGlobal = key.isGlobal()
            $0.keyEquivalent = Preferences.shared.hotKeys[key]
            $0.initStringValue()
        }
    }
    
    func initGlobalButtonState() {
        let s = Preferences.shared.enableGlobalHotKeys
        textFieldsDic.filter {
            $0.value.isGlobal()
        }.forEach {
            $0.key.isEnabled = s
        }
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}

extension PreferencesViewController: NSTextFieldDelegate, KeyEquivalentTextFieldDelegate {
    func keyEquivalentChangeFailed(_ reason: KeyEquivalentChangeFailureReason, _ textField: KeyEquivalentTextField) {
        print(#function, reason)
    }
    
    func keyEquivalentDidChanged(_ keyEquivalent: PreferencesKeyEvent, _ textField: KeyEquivalentTextField) {
        guard let key = textFieldsDic[textField] else { return }
        
        var hotKeys = Preferences.shared.hotKeys
        if let k = hotKeys.first(where: {
            $0.value.flags == keyEquivalent.flags
                && $0.value.keyCode == keyEquivalent.keyCode
        })?.key {
            hotKeys[k] = PreferencesKeyEvent.init(flags: nil, keyCode: nil)
            let tf = textFieldsDic.first {
                $0.value == k
                }?.key

            tf?.placeholderString = "Empty"
            tf?.stringValue = ""
        }
        
        hotKeys[key] = keyEquivalent
        print("New keyEquivalent setted, \(key)  \(keyEquivalent)")
        Preferences.shared.hotKeys = hotKeys
        textField.initStringValue()
    }
}

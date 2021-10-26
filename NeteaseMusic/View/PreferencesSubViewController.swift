//
//  PreferencesSubViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/19.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import HotKey
import WebKit

class PreferencesSubViewController: NSViewController {
    
    @IBOutlet var userImageView: NSImageView!
    @IBOutlet var userNameTextField: NSTextField!
    
    @IBAction func logoutAction(_ sender: NSButton) {
        let pc = PlayCore.shared
        pc.api.logout().done {
            print("Logout success.")
        }.ensure {
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                records.forEach { record in
                    WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                }
            }
            
            let vc = self.presentingViewController as? PreferencesViewController
            vc?.uid = -1
            pc.api.uid = -1
            pc.stop()
            
            NotificationCenter.default.post(name: .updateLoginStatus, object: nil)
        }.catch {
            print("Logout error \($0).")
        }
        
    }
    
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
            PlayCore.shared.setupSystemMediaKeys()
        default:
            break
        }
    }
    
    @IBOutlet weak var brButton0: NSButton!
    @IBOutlet weak var brButton1: NSButton!
    @IBOutlet weak var brButton2: NSButton!
    
    @IBAction func brButtonAction(_ sender: NSButton) {
        let perf = Preferences.shared
        switch sender {
        case brButton0:
            perf.musicBitRate = .🎹192kbps
        case brButton1:
            perf.musicBitRate = .🎹320kbps
        case brButton2:
            perf.musicBitRate = .best
        default:
            break
        }
        initMusicBrButtons()
    }
    
    @IBOutlet weak var cacheSlider: NSSlider!
    @IBOutlet weak var cacheTextField: NSTextField!
    @IBAction func sliderAction(_ sender: NSSlider) {
        switch sender {
        case cacheSlider:
            let v = sender.doubleValue
            Preferences.shared.cacheSize = v
            initCacheSize(updateSlider: false)
        default:
            break
        }
    }
    
    @IBOutlet weak var addToPlaylistButton: NSButton!
    @IBOutlet weak var replacePlaylistButton: NSButton!
    
    @IBAction func pButtonAction(_ sender: NSButton) {
        switch sender {
        case addToPlaylistButton:
            Preferences.shared.replacePlaylist = false
        case replacePlaylistButton:
            Preferences.shared.replacePlaylist = true
        default:
            break
        }
        initPlaylistActionButtons()
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
                    Log.info("invalidateAllHotKeys")
                    vcManager.invalidateAllHotKeys()
                }
            } else {
                if vcManager.hotKeysEnabled {
                    Log.info("initAllHotKeys")
                    vcManager.initAllHotKeys()
                }
            }
        }
    }
    
    var textFieldsDic = [KeyEquivalentTextField: PreferencesKeyEquivalents]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        scrollView.documentView?.isFlipped = true
        
        
        let pref = Preferences.shared
        enableSystemMediaButton.state = pref.useSystemMediaControl ? .on : .off
        enableGlobalButton.state = pref.enableGlobalHotKeys ? .on : .off
        if #available(macOS 10.13, *) {
            enableSystemMediaButton.isEnabled = true
        } else {
            enableSystemMediaButton.isEnabled = false
        }
        
        initMusicBrButtons()
        initCacheSize()
        initPlaylistActionButtons()
        
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
                Log.error("Can't find key in textFieldsDic.")
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
    
    func initMusicBrButtons() {
        let br = Preferences.shared.musicBitRate
        brButton0.state = .off
        brButton1.state = .off
        brButton2.state = .off
        
        switch br {
        case .🎹192kbps:
            brButton0.state = .on
        case .🎹320kbps:
            brButton1.state = .on
        case .best:
            brButton2.state = .on
        }
    }
    
    func initCacheSize(updateSlider: Bool = true) {
        let v = Preferences.shared.cacheSize
        cacheTextField.doubleValue = v * 1000000
        if updateSlider {
            cacheSlider.doubleValue = v
        }
    }
    
    func initPlaylistActionButtons() {
        let r = Preferences.shared.replacePlaylist
        replacePlaylistButton.state = r ? .on : .off
        addToPlaylistButton.state = !r ? .on : .off
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}

extension PreferencesSubViewController: NSTextFieldDelegate, KeyEquivalentTextFieldDelegate {
    func keyEquivalentChangeFailed(_ reason: KeyEquivalentChangeFailureReason, _ textField: KeyEquivalentTextField) {
        Log.error(reason)
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
        Log.info("New keyEquivalent setted, \(key)  \(keyEquivalent)")
        Preferences.shared.hotKeys = hotKeys
        textField.initStringValue()
    }
}

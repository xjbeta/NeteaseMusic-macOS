//
//  ViewControllerManager.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/16.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import HotKey
import GSPlayer

class ViewControllerManager: NSObject {
    static let shared = ViewControllerManager()
    
    var fmVC: FMViewController?
    
    private override init() {
    }
    
    @objc dynamic var selectedSidebarItem: SidebarViewController.SidebarItem? = nil
    
    var searchFieldString = ""
    
    var userId = -233
    
    var hotKeys = [PreferencesKeyEquivalents: HotKey]()
    
    var hotKeysEnabled = false
    
    func togglePlayPause() {
        let pc = PlayCore.shared
        if pc.playlist.count == 0 {
            guard let vc = mainVC(),
                  let tabVC = vc.currentContentTabVC() else { return }
            
            tabVC.startPlay(true)
        } else {
            pc.togglePlayPause()
        }
    }
    
    func selectSidebarItem(_ itemType: SidebarViewController.ItemType,
                           _ id: Int = -1) {
        
        // Exit Playing Song
        
        if let vc = mainVC(),
           vc.playingSongViewStatus != .hidden {
            vc.updatePlayingSongTabView(.main)
            vc.playingSongViewStatus = .hidden
        }
        
        print(#function, "\(itemType)", "ID: \(id)")
        NotificationCenter.default.post(name: .selectSidebarItem, object: nil, userInfo: ["itemType": itemType, "id": id])
    }
    
    func mainVC() -> MainViewController? {
        NSApp.windows.compactMap {
            $0.windowController as? MainWindowController
        }.first?.contentViewController as? MainViewController
    }
    
    func copyToPasteboard(_ str: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([str as NSString])
    }
    
    func initAllHotKeys() {
        invalidateAllHotKeys()
        Preferences.shared.hotKeys.forEach {
            if $0.key.isGlobal() {
                guard Preferences.shared.enableGlobalHotKeys else { return }
            }
            initHotKey(pKey: $0.key)
        }
        hotKeysEnabled = false
    }
    
    func invalidateAllHotKeys() {
        guard let mainMenu = (NSApp.delegate as? AppDelegate)?.mainMenu else { return }
        hotKeys.forEach {
            $0.value.keyDownHandler = nil
        }
        hotKeys.removeAll()
        
        var items = [NSMenuItem]()
        items.append(mainMenu.playMenuItem)
        items.append(mainMenu.nextMenuItem)
        items.append(mainMenu.previousMenuItem)
        items.append(mainMenu.increaseVolumeMenuItem)
        items.append(mainMenu.decreaseVolumeMenuItem)
        items.append(mainMenu.likeMenuItem)
        items.forEach {
            $0.keyEquivalent = ""
            $0.keyEquivalentModifierMask = .init(rawValue: 0)
        }
        hotKeysEnabled = true
    }
    
    func updateGlobalHotKeysState() {
        if Preferences.shared.enableGlobalHotKeys {
            Preferences.shared.hotKeys.filter {
                $0.key.isGlobal()
            }.forEach {
                initHotKey(pKey: $0.key)
            }
        } else {
            hotKeys.forEach {
                $0.value.keyDownHandler = nil
            }
            hotKeys.removeAll()
        }
    }
    
    func initHotKey(pKey: PreferencesKeyEquivalents) {
        guard let keyEvent = Preferences.shared.hotKeys[pKey],
            let keyCode = keyEvent.keyCode else {
            return
        }
        guard let kCode = UInt32(keyCode), let key = Key(carbonKeyCode: kCode) else {
            print(pKey)
            return
        }
        
        if pKey.isGlobal() {
            guard let flags = keyEvent.flags, let fValue = UInt(flags) else { return }
            let hotKey = HotKey(key: key, modifiers: .init(rawValue: fValue))
            let k = pKey
            
            hotKey.keyDownHandler = {
                let playCore = PlayCore.shared
                switch k {
                case .playGlobal:
                    playCore.togglePlayPause()
                case .volumeUpGlobal:
                    playCore.increaseVolume()
                case .volumeDownGlobal:
                    playCore.decreaseVolume()
                case .nextGlobal:
                    playCore.nextSong()
                case .preGlobal:
                    playCore.previousSong()
                case .likeGlobal:
                    break
                case .miniGlobal:
                    break
                case .lyricGlobal:
                    break
                default:
                    break
                }
            }
            hotKeys[pKey] = hotKey
        } else {
            guard let mainMenu = (NSApp.delegate as? AppDelegate)?.mainMenu else { return }
            
            var menuItem: NSMenuItem?
            switch pKey {
            case .play:
                menuItem = mainMenu.playMenuItem
            case .next:
                menuItem = mainMenu.nextMenuItem
            case .pre:
                menuItem = mainMenu.previousMenuItem
            case .volumeUp:
                menuItem = mainMenu.increaseVolumeMenuItem
            case .volumeDown:
                menuItem = mainMenu.decreaseVolumeMenuItem
            case .like:
                menuItem = mainMenu.likeMenuItem
            default:
                break
            }
            guard let item = menuItem else { return }
            // " " -> Space
            item.keyEquivalent = keyCode == "49" ? " " : key.description.lowercased()
            if let flags = keyEvent.flags, let fValue = UInt(flags) {
                item.keyEquivalentModifierMask = .init(rawValue: fValue)
            } else {
                item.keyEquivalentModifierMask = .init(rawValue: 0)
            }
        }
    }
    
    func invalidateHotKey(pKey: PreferencesKeyEquivalents) {
        if pKey.isGlobal() {
            hotKeys[pKey]?.keyDownHandler = nil
            hotKeys[pKey] = nil
        } else {
            guard let mainMenu = (NSApp.delegate as? AppDelegate)?.mainMenu else { return }

            var menuItem: NSMenuItem?
            switch pKey {
            case .play:
                menuItem = mainMenu.playMenuItem
            case .next:
                menuItem = mainMenu.nextMenuItem
            case .pre:
                menuItem = mainMenu.previousMenuItem
            case .volumeUp:
                menuItem = mainMenu.increaseVolumeMenuItem
            case .volumeDown:
                menuItem = mainMenu.decreaseVolumeMenuItem
            case .like:
                menuItem = mainMenu.likeMenuItem
            default:
                break
            }
            guard let item = menuItem else { return }
            item.keyEquivalent = ""
            item.keyEquivalentModifierMask = .init(rawValue: 0)
        }
    }
    
    func displayMessage(_ str: String) {
        NotificationCenter.default.post(name: .displayMessage, object: nil, userInfo: ["message": str])
    }
    
    func saveFMPlaylist() {
        guard let vc = fmVC else { return }
        let pl = vc.fmPlaylist.map {
            $0.id
        }
        let id = vc.currentTrackId
        Preferences.shared.fmPlaylist = (id, pl)
    }
    
    func cleanMusicCache() {
        let fm = FileManager.default
        let path = VideoCacheManager.directory
        let contents = (try? fm.contentsOfDirectory(atPath: path)) ?? []
        guard contents.count > 0 else { return }
        
        let maxSize = UInt64(Preferences.shared.cacheSize) * 1_000_000
        
        var size: UInt64 = 0
        var isfull = false
        var deleteList = [String]()
        
        contents.filter {
            NSString(string: $0).pathExtension != "cfg"
        }.compactMap { name -> (String, Date, Int)? in
            guard let attributes = try? fm.attributesOfItem(atPath: path + "/" + name),
                  let date = attributes[FileAttributeKey.creationDate] as? Date,
                  let size = attributes[FileAttributeKey.size] as? Int
            else {
                return nil
            }
            return (name, date, size)
        }.sorted { f1, f2 in
            f1.1 > f2.1
        }.forEach {
            size += UInt64($0.2)
            if !isfull, size > maxSize {
                isfull = true
            }
            
            if isfull {
                deleteList.append($0.0)
            }
        }
        
        deleteList.forEach {
            let path = path + "/" + $0
            try? fm.removeItem(atPath: path)
            try? fm.removeItem(atPath: path + ".cfg")
        }
    }
}

extension NSTableView {
    func selectedIndexs() -> IndexSet{
        if clickedRow != -1 {
            if selectedRowIndexes.contains(clickedRow) {
                return selectedRowIndexes
            } else {
                return IndexSet(integer: clickedRow)
            }
        } else {
            return selectedRowIndexes
        }
    }
}

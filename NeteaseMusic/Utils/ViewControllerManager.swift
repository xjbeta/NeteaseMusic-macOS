//
//  ViewControllerManager.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/16.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import HotKey

class ViewControllerManager: NSObject {
    static let shared = ViewControllerManager()
    
    private override init() {
    }
    
    @objc dynamic var selectedSidebarItem: SidebarViewController.SidebarItem? = nil
    
    var searchFieldString = ""
    
    var userId = -233
    
    var hotKeys = [HotKey]()
    
    func selectSidebarItem(_ itemType: SidebarViewController.ItemType,
                           _ id: Int = -1) {
        print(#function, "\(itemType)", "ID: \(id)")
        NotificationCenter.default.post(name: .selectSidebarItem, object: nil, userInfo: ["itemType": itemType, "id": id])
    }
    
    func copyToPasteboard(_ str: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([str as NSString])
    }
    
    func initHotKeys() {
        hotKeys.forEach {
            $0.keyDownHandler = nil
        }
        hotKeys.removeAll()
        
        Preferences.shared.hotKeys.forEach {
            guard let keyCode = $0.value["keyCode"] else {
                return
            }
            guard let kCode = UInt32(keyCode), let key = Key(carbonKeyCode: kCode) else {
                print($0.key)
                return
            }
            
            if $0.key.rawValue.contains("Global") {
                guard let flags = $0.value["flags"], let fValue = UInt(flags) else { return }
                let hotKey = HotKey(key: key, modifiers: .init(rawValue: fValue))
                let k = $0.key
                hotKey.keyDownHandler = {
                    let playCore = PlayCore.shared
                    switch k {
                    case .playGlobal:
                        playCore.continuePlayOrPause()
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
                hotKeys.append(hotKey)
            } else {
                guard let mainMenu = (NSApp.delegate as? AppDelegate)?.mainMenu else { return }
                
                var menuItem: NSMenuItem?
                switch $0.key {
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
                item.keyEquivalent = keyCode == "49" ? " " : key.description
                if let flags = $0.value["flags"], let fValue = UInt(flags) {
                    item.keyEquivalentModifierMask = .init(rawValue: fValue)
                } else {
                    item.keyEquivalentModifierMask = .init(rawValue: 0)
                }
            }
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

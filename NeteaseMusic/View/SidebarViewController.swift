//
//  SidebarViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/5.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class SidebarViewController: NSViewController {
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet var outlineViewMenu: NSMenu!
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var playNextMenuItem: NSMenuItem!
    @IBOutlet weak var copyLinkMenuItem: NSMenuItem!
    @IBOutlet weak var deletePlaylistMenuItem: NSMenuItem!
    
    @IBAction func menuAction(_ sender: NSMenuItem) {
        guard let item = (outlineView.item(atRow: outlineView.clickedRow) as? NSTreeNode)?.representedObject as? SidebarItem else {
            return
        }
        
        switch sender {
        case playMenuItem:
            break
        case playNextMenuItem:
            break
        case copyLinkMenuItem:
            let str = "https://music.163.com/playlist?id=\(item.id)"
            ViewControllerManager.shared.copyToPasteboard(str)
        case deletePlaylistMenuItem:
            guard let w = view.window else { return }
            let alert = NSAlert()
            alert.messageText = "Delete Playlist."
            alert.informativeText = "\(item.title) will be deleted."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            alert.beginSheetModal(for: w) { [weak self] in
                if $0 == .alertFirstButtonReturn,
                    let parentItem = self?.sidebarItems.filter ({
                    $0.childrenItems.contains(item)
                }).first {
                    var re: Promise<()>
                    switch parentItem.type {
                    case .createdPlaylists:
                        re = PlayCore.shared.api.playlistDelete(item.id)
                    case .subscribedPlaylists:
                        re = PlayCore.shared.api.playlistSubscribe(item.id, unSubscribe: true)
                    default:
                        return
                    }
                    re.done {
                        parentItem.childrenItems.removeAll {
                            $0.id == item.id
                        }
                        print("Delete / Unsubscribe playlist \(item.id) done.")
                        }.catch {
                            print("Delete / Unsubscribe playlist \(item.id) error \($0).")
                    }
                }
            }
        default:
            break
        }
    }
    
    @objc class SidebarItem: NSObject {
        @objc dynamic var title: String
        @objc var icon: NSImage? {
            get {
                switch type {
                case .discover:
                    return NSImage(named: NSImage.Name("sidebar.sp#icn-discover"))
                case .fm:
                    return NSImage(named: NSImage.Name("sidebar.sp#icn-fm"))
                case .favourite:
                    return NSImage(named: NSImage.Name("sidebar.sp#icn-love"))
                case .playlist:
                    return NSImage(named: NSImage.Name("sidebar.sp#icn-song"))
                default:
                    return nil
                }
            }
        }
        var id: Int = 0
        var type: ItemType = .none
        
        @objc var isLeaf: Bool
        @objc var childrenCount = 0
        @objc dynamic var childrenItems = [SidebarItem]() {
            didSet {
                isLeaf = childrenItems.isEmpty
                childrenCount = childrenItems.count
            }
        }
        
        init(title: String = "", id: Int = -1, type: ItemType) {
            self.type = type
            isLeaf = true
            switch type {
            case .discover:
                self.title = "发现音乐"
            case .fm:
                self.title = "私人FM"
            case .mySubscription:
                self.title = "我的收藏"
            case .createdPlaylists:
                self.title = "创建的歌单"
                isLeaf = false
            case .subscribedPlaylists:
                self.title = "收藏的歌单"
                isLeaf = false
            default:
                self.title = title
            }
            
            self.id = id
        }
    }
    
    enum ItemType {
        case discover, fm, favourite, playlist, none, discoverPlaylist, album, artist, topSongs, searchResults, fmTrash, createdPlaylists, subscribedPlaylists, preferences, mySubscription
    }
    
    let defaultItems = [SidebarItem(type: .discover),
                        SidebarItem(type: .fm),
                        SidebarItem(type: .mySubscription),
                        SidebarItem(type: .createdPlaylists),
                        SidebarItem(type: .subscribedPlaylists)]
    @objc dynamic var sidebarItems = [SidebarItem]()
    
    let outlineViewNotification = Notification(name: NSOutlineView.selectionDidChangeNotification, object: nil, userInfo: nil)
    var selectSidebarItemObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sidebarItems = defaultItems
        
        selectSidebarItemObserver = NotificationCenter.default.addObserver(forName: .selectSidebarItem, object: nil, queue: .main) { [weak self] in
            guard let dic = $0.userInfo as? [String: Any],
                let itemType = dic["itemType"] as? ItemType,
                let id = dic["id"] as? Int,
                let notification = self?.outlineViewNotification else { return }
            switch itemType {
            case .fm:
                if let index = self?.sidebarItems.firstIndex(where: { $0.type == itemType }) {
                    self?.outlineView.deselectAll(self)
                    self?.outlineView.selectRowIndexes(.init(integer: index), byExtendingSelection: true)
                    self?.outlineViewSelectionIsChanging(notification)
                }
            case .album, .artist, .topSongs, .searchResults, .playlist, .fmTrash, .discoverPlaylist, .preferences:
                self?.outlineView.deselectAll(self)
                ViewControllerManager.shared.selectedSidebarItem = .init(title: "", id: id, type: itemType)
            default:
                break
            }
        }
    }
    
    func updatePlaylists() {
        PlayCore.shared.api.userPlaylist().done(on: .main) {
            var created = $0.filter {
                !$0.subscribed
                }.map {
                    SidebarItem(title: $0.name, id: $0.id, type: .playlist)
            }
            
            if let item = created.first, item.title.contains("喜欢的音乐") {
                created[0].title = "我喜欢的音乐"
                created[0].type = .favourite
            }
            
            self.sidebarItems.filter({
                $0.title == "创建的歌单"
            }).first?.childrenItems = created
            
            let subscribed = $0.filter {
                $0.subscribed
                }.map {
                    SidebarItem(title: $0.name, id: $0.id, type: .playlist)
            }
            
            self.sidebarItems.filter({
                $0.title == "收藏的歌单"
            }).first?.childrenItems = subscribed
            
            self.outlineView.expandItem(nil, expandChildren: true)
            }.catch {
                print($0)
        }
    }
    
    deinit {
        if let obs = selectSidebarItemObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

extension SidebarViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return nil
        }
        if !node.isLeaf {
            if let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SidebarHeaderCell"), owner: self) as? NSTableCellView {
                view.textField?.stringValue = node.title
                
                return view
            }
        } else {
            if let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SidebarDataCell"), owner: self) as? NSTableCellView {
                view.textField?.stringValue = node.title
                view.imageView?.image = node.icon
                return view
            }
        }
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return 0
        }
        if node.isLeaf {
            return 21
        } else {
            return 17
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return false
        }
        return node.isLeaf
    }
    
    func outlineViewSelectionIsChanging(_ notification: Notification) {
        guard let item = (outlineView.item(atRow: outlineView.selectedRow) as? NSTreeNode)?.representedObject as? SidebarItem else {
            return
        }
        
        ViewControllerManager.shared.selectedSidebarItem = item
    }
}

extension SidebarViewController: NSMenuItemValidation, NSMenuDelegate {
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let item = (outlineView.item(atRow: outlineView.clickedRow) as? NSTreeNode)?.representedObject as? SidebarItem,
            let type = sidebarItems.filter({ $0.childrenItems.contains(item) }).first?.type else {
            return
        }
        
        switch type {
        case .createdPlaylists:
            deletePlaylistMenuItem.title = "Delete Playlist"
        case .subscribedPlaylists:
            deletePlaylistMenuItem.title = "Unsubscribe Playlist"
        default:
            break
        }
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let item = (outlineView.item(atRow: outlineView.clickedRow) as? NSTreeNode)?.representedObject as? SidebarItem else {
            return false
        }
        
        switch item.type {
        case .playlist, .favourite:
            return true
        default:
            break
        }
        return false
    }
}

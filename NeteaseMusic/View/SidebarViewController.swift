//
//  SidebarViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/5.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {
    @IBOutlet weak var outlineView: NSOutlineView!
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
        
        init(title: String, id: Int = -1, type: ItemType) {
            self.title = title
            self.id = id
            self.type = type
            isLeaf = type != .header
        }
    }
    
    enum ItemType {
        case discover, fm, favourite, playlist, header, none, discoverPlaylist, album, artist, topSongs, searchResults, fmTrash
    }
    
    let defaultItems = [SidebarItem(title: "发现音乐", type: .discover),
                        SidebarItem(title: "私人FM", type: .fm),
                        SidebarItem(title: "创建的歌单", type: .header),
                        SidebarItem(title: "收藏的歌单", type: .header)]
    @objc dynamic var sidebarItems = [SidebarItem]()
    
    let outlineViewNotification = Notification(name: NSOutlineView.selectionDidChangeNotification, object: nil, userInfo: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sidebarItems = defaultItems
        updatePlaylists()
        
        NotificationCenter.default.addObserver(forName: .selectSidebarItem, object: nil, queue: .main) { [weak self] in
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
            case .album, .artist, .topSongs, .searchResults, .playlist, .fmTrash:
                self?.outlineView.deselectAll(self)
                self?.outlineViewSelectionIsChanging(notification)
                ViewControllerManager.shared.selectedSidebarItem = .init(title: "", id: id, type: itemType)
            default:
                break
            }
        }
    }
    
    func updatePlaylists() {
        PlayCore.shared.api.isLogin().then { _ in
            PlayCore.shared.api.userPlaylist()
            }.done(on: .main) {
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
    
}

extension SidebarViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return nil
        }
        if node.type == .header {
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
        if node.type == .header {
            return 17
        } else {
            return 21
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return false
        }
        return node.type != .header
    }
    
    func outlineViewSelectionIsChanging(_ notification: Notification) {
        guard let item = (outlineView.item(atRow: outlineView.selectedRow) as? NSTreeNode)?.representedObject as? SidebarItem else {
            return
        }
        
        ViewControllerManager.shared.selectedSidebarItem = item
    }
}

//
//  SidebarViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/5.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    class TableViewItem: NSObject {
        var title: String
        var icon: NSImage? {
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
        
        init(title: String, id: Int = -1, type: ItemType) {
            self.title = title
            self.id = id
            self.type = type
        }
    }
    
    enum ItemType {
        case discover, fm, favourite, playlist, header, none
    }
    
    let defaultItems = [TableViewItem(title: "发现音乐", type: .discover),
                        TableViewItem(title: "私人FM", type: .fm),
                        TableViewItem(title: "创建的歌单", type: .header),
                        TableViewItem(title: "收藏的歌单", type: .header)]
    var tableViewItems = [TableViewItem]()
    var tableViewSelectedRow = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewItems = defaultItems
        
        PlayCore.shared.api.isLogin().then { _ in
            PlayCore.shared.api.userPlaylist()
            }.done(on: .main) {
                var created = $0.filter {
                    !$0.subscribed
                    }.map {
                        TableViewItem(title: $0.name, id: $0.id, type: .playlist)
                }
                
                if let item = created.first, item.title.contains("喜欢的音乐") {
                    created[0].title = "我喜欢的音乐"
                    created[0].type = .favourite
                }
                
                guard let indexOfCreated = self.tableViewItems.enumerated().filter({
                    $0.element.title == "创建的歌单"
                }).first?.offset else {
                    return
                }
                
                self.tableViewItems.insert(contentsOf: created, at: indexOfCreated + 1)
                
                let subscribed = $0.filter {
                    $0.subscribed
                    }.map {
                        TableViewItem(title: $0.name, id: $0.id, type: .playlist)
                }
                self.tableViewItems.append(contentsOf: subscribed)
                self.tableView.reloadData()
            }.catch {
                print($0)
        }
    }
    
}

extension SidebarViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tableViewItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let item = tableViewItems[safe: row] else { return nil }
        
        if item.type == .header {
            guard let view = tableView.makeView(withIdentifier: .sidebarHeaderTableCellView, owner: self) as? SidebarHeaderTableCellView else { return nil }
            view.titleButton.title = item.title
            return view
        } else {
            guard let view =  tableView.makeView(withIdentifier: .sidebarTableCellView, owner: self) as? SidebarTableCellView else { return nil }
            view.textField?.stringValue = item.title
            view.imageView?.image = item.icon
            return view
        }
        
    }

    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard let item = tableViewItems[safe: row] else { return false }
        return item.type != .header
    }
    
    func tableViewSelectionIsChanging(_ notification: Notification) {
        if tableViewSelectedRow >= 0, tableViewSelectedRow < tableView.numberOfRows,
            let view = tableView.view(atColumn: tableView.selectedColumn, row: tableViewSelectedRow, makeIfNecessary: false) as? SidebarTableCellView {
            view.isSelected = false
        }
        if tableView.selectedRow >= 0, tableView.selectedRow < tableView.numberOfRows,
            let view = tableView.view(atColumn: tableView.selectedColumn, row: tableView.selectedRow, makeIfNecessary: false) as? SidebarTableCellView {
            view.isSelected = true
        }
        
        tableViewSelectedRow = tableView.selectedRow
        PlayCore.shared.selectedSidebarItem = tableViewItems[safe: tableView.selectedRow]
    }
}

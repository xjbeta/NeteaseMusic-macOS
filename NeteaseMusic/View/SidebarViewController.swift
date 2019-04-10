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
        let icon: NSImage?
        var id: Int = 0
        var type: ItemType = .none
        
        init(title: String, icon: NSImage? = nil, id: Int, type: ItemType) {
            self.title = title
            self.icon = icon
            self.id = id
            self.type = type
        }
    }
    
    enum ItemType {
        case discover, fm, favourite, playlist, header, none
    }
    
    let defaultItems = [TableViewItem(title: "发现音乐", icon: nil, id: -1, type: .discover),
                        TableViewItem(title: "私人FM", icon: nil, id: -1, type: .fm),
                        TableViewItem(title: "创建的歌单", icon: nil, id: -1, type: .header),
                        TableViewItem(title: "收藏的歌单", icon: nil, id: -1, type: .header)]
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
                        TableViewItem(title: $0.name, icon: nil, id: $0.id, type: .playlist)
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
                        TableViewItem(title: $0.name, icon: nil, id: $0.id, type: .playlist)
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

//
//  SearchSuggestionsViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/3.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SearchSuggestionsViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!

    enum SuggestItemType {
        case song, album, artist, playlist, mv, groupItem
    }
    
    struct SuggestItem {
        let id: Int
        let name: String
        let secondName: String?
        let image: NSImage?
        let type: SuggestItemType
        var withSecondLabel : Bool {
            return type == .song || type == .album
        }
        
        init(id: Int = -1, name: String, secondName: String? = nil, type: SuggestItemType = .groupItem, image: NSImage? = nil) {
            self.id = id
            self.name = name
            self.secondName = secondName
            self.type = type
            self.image = image
        }
    }
    
    var suggestItems = [SuggestItem]()
    
    var suggestResult: SearchSuggest.Result? {
        didSet {
            guard let re = suggestResult else { return }
            suggestItems.removeAll()
            if let songs = re.songs {
                suggestItems.append(.init(name: "Songs"))
                suggestItems.append(contentsOf: songs.map ({ SuggestItem(id: $0.id, name: $0.name, secondName: $0.artists.map({ $0.name }).joined(separator: " "), type: .song) }))
            }
            if let albums = re.albums {
                suggestItems.append(.init(name: "Albums"))
                suggestItems.append(contentsOf: albums.map ({ SuggestItem(id: $0.id, name: $0.name, secondName: $0.artist.name, type: .album) }))
            }
            if let artists = re.artists {
                suggestItems.append(.init(name: "Artists"))
                suggestItems.append(contentsOf: artists.map ({ SuggestItem(id: $0.id, name: $0.name, type: .artist) }))
            }
            if let playlists = re.playlists {
                suggestItems.append(.init(name: "Playlists"))
                suggestItems.append(contentsOf: playlists.map ({ SuggestItem(id: $0.id, name: $0.name, type: .playlist) }))
            }
            tableView.reloadData()
        }
    }
    
    func initViewHeight(_ popover: NSPopover?) {
        var size = view.frame.size
        let height = tableView.intrinsicContentSize.height
        size.height = height > 800 ? 800 : height
        popover?.contentSize = size
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.refusesFirstResponder = true
    }
}

extension SearchSuggestionsViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return suggestItems.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let item = suggestItems[safe: row] else { return 0 }
        return item.type == .groupItem ? 21 : 30
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return tableView.makeView(withIdentifier: .init("SearchSuggestTableCellView"), owner: nil)
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let item = suggestItems[safe: row] else { return nil }
        return ["name": item.name,
                "secondName": item.secondName ?? "None",
                "withSecondLabel": item.withSecondLabel]
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return suggestItems[safe: row]?.type == .groupItem
    }
}

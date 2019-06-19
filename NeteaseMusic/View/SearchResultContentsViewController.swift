//
//  SearchSongsResultViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/6.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SearchResultContentsViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    var dataType: SearchSuggestionsViewController.GroupType = .none
    
    var songs = [Track]()
    var albums = [Track.Album]()
    var artists = [Track.Artist]()
    
    var headerView: NSTableHeaderView? = nil
    var tableViewColumnWidths = [(width: CGFloat, minWidth: CGFloat, maxWidth: CGFloat)]()
    var tableViewColumns = [NSTableColumn]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerView = tableView.headerView
    }
    
    func reloadTableView() {
        tableView.reloadData()
    }
    
    func resetData(_ type: SearchSuggestionsViewController.GroupType) {
        if dataType == .songs, type != .songs {
            tableViewColumnWidths.removeAll()
            tableViewColumnWidths = tableView.tableColumns.map {
                ($0.width, $0.minWidth, $0.maxWidth)
            }
            tableViewColumns = tableView.tableColumns
            tableViewColumns.removeFirst()
            tableView.tableColumns.enumerated().forEach {
                if $0.offset != 0 {
                    tableView.removeTableColumn($0.element)
                }
            }
        }
        
        dataType = type
        songs.removeAll()
        albums.removeAll()
        
        switch type {
        case .songs:
            tableView.headerView = headerView
            tableViewColumns.forEach {
                tableView.addTableColumn($0)
            }
            
            tableView.tableColumns.enumerated().forEach {
                $0.element.isHidden = false
                if let widths = tableViewColumnWidths[safe: $0.offset] {
                    $0.element.minWidth = widths.minWidth
                    $0.element.maxWidth = widths.maxWidth
                    $0.element.width = widths.width
                }
            }
        case .albums, .artists:
            tableView.headerView = nil
            tableView.tableColumns.enumerated().forEach {
                $0.element.isHidden = $0.offset != 0
            }
            tableView.tableColumns.first?.maxWidth = 99999999
            tableView.tableColumns.first?.width = tableView.frame.width
        default:
            break
            
        }
        tableView.reloadData()
    }
}

extension SearchResultContentsViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch dataType {
        case .songs:
            return songs.count
        case .albums:
            return albums.count
        case .artists:
            return artists.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch dataType {
        case .songs:
            return 17
        case .albums, .artists:
            return 80
        default:
            return 0
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        switch dataType {
        case .songs:
            guard let identifier = tableColumn?.identifier else { return nil }
            return tableView.makeView(withIdentifier: identifier, owner: self)
        case .albums:
            return tableView.makeView(withIdentifier: .init("SearchAlbumInfoTableCellView"), owner: self)
        case .artists:
            return tableView.makeView(withIdentifier: .init("SearchArtistInfoTableCellView"), owner: self)
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch dataType {
        case .songs:
            guard let song = songs[safe: row] else { return nil }
            
            return ["index": song.index,
                    "name": song.name,
                    "artist": song.artists.artistsString(),
                    "album": song.album.name,
                    "time": song.duration]
        case .albums:
            guard let album = albums[safe: row],
                let cover = NSImage(named: .init("calendar_bg")) else { return nil }
            
            return ["image": album.cover ?? cover,
                    "name": album.name,
                    "artist": album.artists?.artistsString() ?? ""]
        case .artists:
            guard let artist = artists[safe: row],
                let cover = NSImage(named: .init("user_150")) else { return nil }
            
            print(artist.alias)
            
            return ["image": artist.cover ?? cover,
                    "name": artist.name,
                    "secondName": artist.alias?.first ?? ""]
        default:
            return nil
        }
    }
}


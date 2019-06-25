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
    var playlists = [Playlist]()
    
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
        
        switch type {
        case .songs:
            if dataType == .songs {
                break
            }
            
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
        case .albums, .artists, .playlists:
            if dataType != .songs {
                break
            }
            
            tableView.headerView = nil
            tableView.tableColumns.enumerated().forEach {
                $0.element.isHidden = $0.offset != 0
            }
            tableView.tableColumns.first?.maxWidth = 99999999
            tableView.tableColumns.first?.width = tableView.frame.width
        default:
            break
            
        }
        
        songs.removeAll()
        albums.removeAll()
        artists.removeAll()
        playlists.removeAll()
        
        dataType = type
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
        case .playlists:
            return playlists.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch dataType {
        case .songs:
            return 17
        case .albums, .artists, .playlists:
            return 80
        default:
            return 0
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view: NSTableCellView? = nil
        switch dataType {
        case .songs:
            guard let identifier = tableColumn?.identifier else { return nil }
            view = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        case .albums:
            view = tableView.makeView(withIdentifier: .init("SearchAlbumInfoTableCellView"), owner: self) as? NSTableCellView
            view?.imageView?.setImage(albums[safe: row]?.picUrl?.absoluteString ?? "", true)
        case .artists:
            view = tableView.makeView(withIdentifier: .init("SearchArtistInfoTableCellView"), owner: self) as? NSTableCellView
            view?.imageView?.setImage(artists[safe: row]?.picUrl?.absoluteString ?? "", true)
        case .playlists:
            view = tableView.makeView(withIdentifier: .init("SearchPlaylistInfoTableCellView"), owner: self) as? NSTableCellView
            view?.imageView?.setImage(playlists[safe: row]?.coverImgUrl.absoluteString ?? "", true)
        default:
            return nil
        }
        
        return view
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
            guard let album = albums[safe: row] else { return nil }
            
            return ["name": album.name,
                    "artist": album.artists?.artistsString() ?? ""]
        case .artists:
            guard let artist = artists[safe: row] else { return nil }
            
            var secondName = ""
            if let name = artist.alias?.first {
                secondName = "(\(name))"
            }
            
            return ["name": artist.name,
                    "secondName": secondName]
        case .playlists:
            guard let playlist = playlists[safe: row] else { return nil }
            
            let name = playlist.creator?.nickname ?? "unknown"
            return ["name": playlist.name,
                    "songCount": playlist.trackCount,
                    "creatorName": "         by \(name)"]
        default:
            return nil
        }
    }
}


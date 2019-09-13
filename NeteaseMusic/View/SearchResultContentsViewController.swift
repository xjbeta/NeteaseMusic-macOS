//
//  SearchSongsResultViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/6.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SearchResultContentsViewController: NSViewController {
    
    @IBOutlet weak var songsTableView: NSTableView!
    @IBOutlet weak var tableView: NSTableView!
    
    var dataType: SearchSuggestionsViewController.GroupType = .none
    
    var songs = [Track]()
    var albums = [Track.Album]()
    var artists = [Track.Artist]()
    var playlists = [Playlist]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func reloadTableView() {
        if dataType == .songs {
            songsTableView.reloadData()
        } else {
            tableView.reloadData()
        }
    }
    
    func resetData(_ type: SearchSuggestionsViewController.GroupType) {
        songs.removeAll()
        albums.removeAll()
        artists.removeAll()
        playlists.removeAll()
        
        dataType = type
        songsTableView.reloadData()
        tableView.reloadData()
        
        songsTableView.enclosingScrollView?.isHidden = type != .songs
        tableView.enclosingScrollView?.isHidden = type == .songs
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
            return 25
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
            view?.imageView?.setImage(artists[safe: row]?.picUrl ?? "", true)
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


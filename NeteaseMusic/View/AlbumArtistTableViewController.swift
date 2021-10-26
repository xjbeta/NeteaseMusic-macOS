//
//  AlbumArtistTableViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/12/11.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class AlbumArtistTableViewController: NSViewController {
    
    @IBOutlet weak var scrollView: UnresponsiveScrollView!
    @IBOutlet weak var tableView: NSTableView!
    
    var dataType: TAAPItemsType = .none
    
    var albums = [Track.Album]()
    var artists = [Track.Artist]()
    var playlists = [Playlist]()
    
    @IBAction func tableViewAction(_ sender: NSTableView) {
        let row = sender.selectedRow
        let vcManaget = ViewControllerManager.shared
        switch dataType {
        case .album:
            guard let id = albums[safe: row]?.id else { return }
            vcManaget.selectSidebarItem(.album, id)
        case .artist:
            guard let id = artists[safe: row]?.id else { return }
            vcManaget.selectSidebarItem(.artist, id)
        case .playlist:
            guard let id = playlists[safe: row]?.id else { return }
            vcManaget.selectSidebarItem(.subscribedPlaylist, id)
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func reloadTableView() {
        tableView.reloadData()
    }
    
    func resetData(_ type: TAAPItemsType, responsiveScrolling: Bool) {
        albums.removeAll()
        artists.removeAll()
        playlists.removeAll()
        
        dataType = type
        tableView.reloadData()
        
        scrollView.responsiveScrolling = responsiveScrolling
    }
}

extension AlbumArtistTableViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch dataType {
        case .album:
            return albums.count
        case .artist:
            return artists.count
        case .playlist:
            return playlists.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view: NSTableCellView? = nil
        switch dataType {
        case .album:
            view = tableView.makeView(withIdentifier: .init("SearchAlbumInfoTableCellView"), owner: self) as? NSTableCellView
            view?.imageView?.setImage(albums[safe: row]?.picUrl?.absoluteString, true)
        case .artist:
            view = tableView.makeView(withIdentifier: .init("SearchArtistInfoTableCellView"), owner: self) as? NSTableCellView
            view?.imageView?.setImage(artists[safe: row]?.picUrl, true)
        case .playlist:
            view = tableView.makeView(withIdentifier: .init("SearchPlaylistInfoTableCellView"), owner: self) as? NSTableCellView
            view?.imageView?.setImage(playlists[safe: row]?.coverImgUrl.absoluteString, true)
        default:
            return nil
        }
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch dataType {
        case .album:
            guard let album = albums[safe: row] else { return nil }
            
            return ["name": album.name,
                    "artist": album.artists?.artistsString() ?? ""]
        case .artist:
            guard let artist = artists[safe: row] else { return nil }
            
            var secondName = ""
            if let name = artist.alias?.first {
                secondName = "(\(name))"
            }
            
            return ["name": artist.name,
                    "secondName": secondName]
        case .playlist:
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

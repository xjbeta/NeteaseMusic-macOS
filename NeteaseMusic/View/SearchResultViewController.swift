//
//  SearchResultViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/29.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SearchResultViewController: NSViewController {
    
    @IBOutlet weak var contentTabView: NSTabView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableHeightLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBAction func selectNewType(_ sender: NSSegmentedControl) {
        guard let type = SearchSuggestionsViewController.GroupType(rawValue: sender.selectedSegment + 1),
            type != resultType else { return }
        
        ViewControllerManager.shared.selectedSidebarItem = .init(title: "", id: sender.selectedSegment + 1, type: .searchResults)
    }
    
    lazy var newPlaylistViewController: NewPlaylistViewController? = {
        let sb = NSStoryboard(name: "NewPlaylist", bundle: nil)
        let vc = sb.instantiateController(withIdentifier: "NewPlaylistViewController") as? NewPlaylistViewController
        vc?.updateSidebarItems = { [weak self] in
            (self?.view.window?.windowController as? MainWindowController)?.initSidebarItems()
        }
        return vc
    }()
    
    var sidebarItemObserver: NSKeyValueObservation?
    var pageData = (count: 0, current: 0)
    var resultType: SearchSuggestionsViewController.GroupType = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { [weak self] core, changes in
            guard let newV = changes.newValue,
                let newValue = newV else { return }
            let id = newValue.id
            guard newValue.type == .searchResults,
                let type = SearchSuggestionsViewController.GroupType(rawValue: id) else { return }
            self?.initContentView(type)
        }
        
    }
    
    func initContentView(_ type: SearchSuggestionsViewController.GroupType) {
        let index = type.rawValue - 1
        guard index >= 0 else { return }
        segmentedControl.setSelected(true, forSegment: index)
        
        resultType = type
        initResults()
    }
    
    func initResults(_ offset: Int = 0) {
        guard let pageVC = pageSegmentedControlViewController(),
            let trackVC = trackTableVC(),
            let albumArtistVC = albumArtistTableVC() else {
                return
        }
        
        let type = resultType
        switch type {
        case .songs:
            trackVC.resetData()
            trackVC.scrollView.responsiveScrolling = false
            contentTabView.selectTabViewItem(at: 0)
        default:
            albumArtistVC.resetData(type, responsiveScrolling: false)
            contentTabView.selectTabViewItem(at: 1)
        }
        
        pageVC.delegate = self
        let keywords = ViewControllerManager.shared.searchFieldString
        let limit = resultType == .songs ? 100 : 20
        pageData.current = offset
        
        PlayCore.shared.api.search(keywords, limit: limit, page: offset, type: resultType).done {
            guard type == self.resultType,
                offset == self.pageData.current else { return }
            
            print("Update search result with \(keywords), page \(offset), limit \(limit).")
            
            var pageCount = 0
            
            switch type {
            case .songs:
                trackVC.playlistType = .searchResults
                let tracks = $0.songs
                tracks.enumerated().forEach {
                    tracks[$0.offset].index = $0.offset + (offset * limit)
                }
                trackVC.tracks = tracks
                pageCount = Int(ceil(Double($0.songCount) / Double(limit)))
            case .albums:
                albumArtistVC.albums = $0.albums
                pageCount = Int(ceil(Double($0.albumCount) / Double(limit)))
            case .artists:
                albumArtistVC.artists = $0.artists
                pageCount = Int(ceil(Double($0.artistCount) / Double(limit)))
            case .playlists:
                albumArtistVC.playlists = $0.playlists
                pageCount = Int(ceil(Double($0.playlistCount) / Double(limit)))
            default:
                break
            }
            
            self.pageData = (pageCount, offset)
            pageVC.reloadData()
            
            if type == .songs {
                trackVC.tableView.reloadData()
                if trackVC.delegate == nil {
                    trackVC.delegate = self
                }
                self.initLayoutConstraint(trackVC.tableView)
            } else {
                albumArtistVC.tableView.reloadData()
                self.initLayoutConstraint(albumArtistVC.tableView)
            }
            
            }.catch {
                print($0)
        }
    }
    
    func pageSegmentedControlViewController() -> PageSegmentedControlViewController? {
        let vc = children.compactMap {
            $0 as? PageSegmentedControlViewController
            }.first
        return vc
    }
    
    func trackTableVC() -> TrackTableViewController? {
        let vc = children.compactMap {
            $0 as? TrackTableViewController
            }.first
        return vc
    }
    
    func albumArtistTableVC() -> AlbumArtistTableViewController? {
        let vc = children.compactMap {
            $0 as? AlbumArtistTableViewController
            }.first
        return vc
    }
    
    func initLayoutConstraint(_ tableView: NSTableView) {
        let headerViewHeight = tableView.headerView?.frame.height ?? 0
        let height = tableView.intrinsicContentSize.height + tableView.intercellSpacing.height + headerViewHeight
        tableHeightLayoutConstraint.constant = height
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}


extension SearchResultViewController: PageSegmentedControlDelegate {
    func currentPage() -> Int {
        return pageData.current
    }
    
    func numberOfPages() -> Int {
        return pageData.count
    }
    
    func clickedPage(_ number: Int) {
        initResults(number)
    }
}

extension SearchResultViewController: TrackTableViewDelegate {
    func trackTableView(_ tableView: NSTableView, startPlaying tracks: [Track], with track: Track?) {
        let pc = PlayCore.shared
        guard tracks.count >= 1 else { return }
        if let t = track,
            let i = tracks.firstIndex(of: t) {
            // DoubleClick action
            pc.playlist = tracks
            pc.start(i)
        } else if let c = pc.currentTrack,
            let i = pc.playlist.firstIndex(of: c) {
            // add to next and play
            pc.playlist.insert(contentsOf: tracks, at: i + 1)
            pc.start(i + 1)
        } else {
            pc.playlist = tracks
            pc.start()
        }
    }
    
    func trackTableView(_ tableView: NSTableView, playNext tracks: [Track]) {
        let pc = PlayCore.shared
        guard tracks.count >= 1 else { return }
        if let c = pc.currentTrack,
            let i = pc.playlist.firstIndex(of: c) {
            pc.playlist.insert(contentsOf: tracks, at: i + 1)
        } else {
            pc.playlist = tracks
            pc.start()
        }
    }
    
    func trackTableView(_ tableView: NSTableView, copyLink track: Track) {
        let str = "https://music.163.com/song?id=\(track.id)"
        ViewControllerManager.shared.copyToPasteboard(str)
    }
    
    func trackTableView(_ tableView: NSTableView, remove tracks: [Track], completionHandler: (() -> Void)?) {
    }
    
    func trackTableView(_ tableView: NSTableView, createPlaylist tracks: [Track], completionHandler: (() -> Void)?) {
        guard let newPlaylistVC = newPlaylistViewController else { return }
        self.presentAsSheet(newPlaylistVC)
    }
    
    func trackTableView(_ tableView: NSTableView, add tracks: [Track], to playlist: Int) {
        let ids = tracks.map {
            $0.id
        }
        PlayCore.shared.api.playlistTracks(add: true, ids, to: playlist).done {
            print("Add \(ids) to playlist \(playlist) done.")
        }.catch {
            print("Add \(ids) to playlist \(playlist) error \($0).")
        }
    }
}

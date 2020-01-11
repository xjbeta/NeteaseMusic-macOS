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
    
    lazy var menuContainer: (menu: NSMenu?, menuController: TAAPMenuController?) = {
        var objects: NSArray?
        Bundle.main.loadNibNamed(.init("TAAPMenu"), owner: nil, topLevelObjects: &objects)
        let mc = objects?.compactMap {
            $0 as? TAAPMenuController
        }.first
        let m = objects?.compactMap {
            $0 as? NSMenu
        }.first
        return (m, mc)
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
            albumArtistVC.resetData(type.taapItemType(), responsiveScrolling: false)
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
                trackVC.tableView.menu = self.menuContainer.menu
                self.menuContainer.menuController?.delegate = self
                self.initLayoutConstraint(trackVC.tableView)
            } else {
                albumArtistVC.tableView.reloadData()
                albumArtistVC.tableView.menu = self.menuContainer.menu
                self.menuContainer.menuController?.delegate = self
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

extension SearchResultViewController: TAAPMenuDelegate {
    func selectedItemIDs() -> [Int] {
        guard let trackVC = trackTableVC(),
            let albumArtistVC = albumArtistTableVC() else {
                return []
        }
        let selectedIndexs = resultType == .songs ? trackVC.tableView.selectedIndexs() : albumArtistVC.tableView.selectedIndexs()
        switch resultType {
        case .songs:
            return trackVC.tracks.enumerated().filter {
                selectedIndexs.contains($0.offset)
            }.map {
                $0.element.id
            }
        case .albums:
            return albumArtistVC.albums.enumerated().filter {
                selectedIndexs.contains($0.offset)
            }.map {
                $0.element.id
            }
        case .artists:
            return albumArtistVC.artists.enumerated().filter {
                selectedIndexs.contains($0.offset)
            }.map {
                $0.element.id
            }
        case .playlists:
            return albumArtistVC.playlists.enumerated().filter {
                selectedIndexs.contains($0.offset)
            }.map {
                $0.element.id
            }
        default:
            return []
        }
    }
    
    func tracksForPlay() -> [Track] {
        guard let trackVC = trackTableVC(),
            resultType == .songs else {
                return []
        }
        let selectedIndexs = trackVC.tableView.selectedIndexs()
        return trackVC.tracks.enumerated().filter {
            selectedIndexs.contains($0.offset)
        }.map {
            $0.element
        }
    }
    
    func presentNewPlaylist(_ newPlaylisyVC: NewPlaylistViewController) {
        guard let pvcs = presentedViewControllers,
            !pvcs.contains(newPlaylisyVC) else { return }
        self.presentAsSheet(newPlaylisyVC)
    }
    
    func removeSuccess(ids: [Int], newItem: Track?) {
        return
    }
    
    func shouldReloadData() {
        return
    }
    
    func tableViewList() -> (type: SidebarViewController.ItemType, id: Int, contentType: TAAPItemsType) {
        return (.searchResults, 0, resultType.taapItemType())
    }
}

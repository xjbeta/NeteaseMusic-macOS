//
//  SearchResultViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/29.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SearchResultViewController: NSViewController {
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableHeightLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBAction func selectNewType(_ sender: NSSegmentedControl) {
        
        
    }
    
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
            self?.initTabView(type)
        }
    }
    
    func initTabView(_ type: SearchSuggestionsViewController.GroupType) {
        let index = type.rawValue - 1
        guard index >= 0 else { return }
        segmentedControl.setSelected(true, forSegment: index)
        
        resultType = type
        switch type {
        case .songs:
            initSongsContent()
        default:
            break
        }
        
    }
    
    func initSongsContent(_ offset: Int = 0) {
        guard let pageSegmentedControlVC = pageSegmentedControlViewController(),
            let songsResultVC = songsResultViewController() else {
                return
        }
        
        pageSegmentedControlVC.delegate = self
        let keywords = ViewControllerManager.shared.searchFieldString
        let limit = 100
        
        songsResultVC.songs.removeAll()
        PlayCore.shared.api.search(keywords, limit: limit, page: offset, type: .songs).done {
            print("Update songs result with \(keywords), page \(offset), limit \(limit).")
            guard let pageSegmentedControlVC = self.pageSegmentedControlViewController(),
                let songsResultVC = self.songsResultViewController() else {
                    return
            }
            
            songsResultVC.songs = $0.songs.initIndexs()
            let pageCount = Int(ceil(Double($0.songCount) / Double(limit)))
            self.pageData = (pageCount, offset)
            pageSegmentedControlVC.reloadData()
            songsResultVC.reloadTableView()
            self.initLayoutConstraint(songsResultVC.tableView)
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
    
    func songsResultViewController() -> SearchResultContentsViewController? {
        let vc = children.compactMap {
            $0 as? SearchResultContentsViewController
            }.first
        return vc
    }
    
    func initLayoutConstraint(_ tableView: NSTableView) {
        guard let headerView = tableView.headerView else { return }
        let height = tableView.intrinsicContentSize.height + headerView.frame.height + tableView.intercellSpacing.height

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
        initSongsContent(number)
    }
}

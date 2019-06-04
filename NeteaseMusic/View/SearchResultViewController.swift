//
//  SearchResultViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/5/29.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SearchResultViewController: NSViewController {
    
    @IBOutlet weak var tabView: NSTabView!
    var sidebarItemObserver: NSKeyValueObservation?
    
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
        tabView.selectTabViewItem(at: index)
        print(ViewControllerManager.shared.searchFieldString)
        
        
        
        
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}

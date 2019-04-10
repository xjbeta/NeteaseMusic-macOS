//
//  MainViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet weak var tabView: NSTabView!
    enum TabItems: Int {
        case playlist, playingMusic, fm, preferences, discover, favourite
    }
    
    var sidebarItemObserver: NSKeyValueObservation?
    override func viewDidLoad() {
        super.viewDidLoad()
        sidebarItemObserver = PlayCore.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { core, changes in
            guard let newType = changes.newValue??.type, newType != changes.oldValue??.type else { return }
            DispatchQueue.main.async {
                switch newType {
                case .discover:
                    break
                case .fm:
                    self.updateTabView(.fm)
                case .playlist, .favourite:
                    self.updateTabView(.playlist)
                default:
                    break
                }
            }
        }
    }
    
    func updateTabView(_ item: TabItems) {
        tabView.selectTabViewItem(at: item.rawValue)
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}

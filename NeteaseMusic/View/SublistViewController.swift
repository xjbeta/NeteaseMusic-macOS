//
//  SublistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/12/11.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class SublistViewController: NSViewController {
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var containerView: NSView!
    @IBAction func actions(_ sender: NSSegmentedControl) {
        initContent()
    }
    
    var sidebarItemObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initContent()
        sidebarItemObserver = ViewControllerManager.shared.observe(\.selectedSidebarItem, options: [.initial, .old, .new]) { core, changes in
            guard let newType = changes.newValue??.type,
                newType != changes.oldValue??.type,
                newType == .mySubscription else { return }
            
            self.initContent()
            
        }
    }
    
    func initContent() {
        containerView.isHidden = true
        guard let vc = albumArtistTableVC() else { return }
        let api = PlayCore.shared.api
        switch segmentedControl.selectedSegment {
        case 0:
            vc.resetData(.album, responsiveScrolling: true)
            api.albumSublist().done(on: .main) {
                self.containerView.isHidden = $0.count == 0
                vc.albums = $0
                vc.reloadTableView()
            }.catch {
                print($0)
            }
        case 1:
            vc.resetData(.artist, responsiveScrolling: true)
            api.artistSublist().done(on: .main) {
                self.containerView.isHidden = $0.count == 0
                vc.artists = $0
                vc.reloadTableView()
            }.catch {
                print($0)
            }
        default:
            return
        }
    }
    
    func albumArtistTableVC() -> AlbumArtistTableViewController? {
        let vc = children.compactMap {
            $0 as? AlbumArtistTableViewController
            }.first
        return vc
    }
    
    deinit {
        sidebarItemObserver?.invalidate()
    }
}

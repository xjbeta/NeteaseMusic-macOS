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
    @IBAction func actions(_ sender: NSSegmentedControl) {
        initContent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initContent()
    }
    
    func initContent() {
        guard let vc = albumArtistTableVC() else { return }
        switch segmentedControl.selectedSegment {
        case 0:
            vc.dataType = .albums
            vc.albums = []
        case 1:
            vc.dataType = .artists
            vc.artists = []
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
}

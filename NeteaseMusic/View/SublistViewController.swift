//
//  SublistViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/12/11.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class SublistViewController: NSViewController, ContentTabViewController {
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var containerView: NSView!
    @IBAction func actions(_ sender: NSSegmentedControl) {
        initContent().done {
            
        }.catch {
            Log.error($0)
        }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        albumArtistTableVC()?.menu = menuContainer.menu
    }
    
    func initContent() -> Promise<()> {
        containerView.isHidden = true
        guard let vc = albumArtistTableVC() else { return .init() }
        let api = PlayCore.shared.api
        vc.tableView.menu = menuContainer.menu
        menuContainer.menuController?.delegate = self

        switch segmentedControl.selectedSegment {
        case 0:
            vc.resetData(.album, responsiveScrolling: true)
            return api.albumSublist().done(on: .main) {
                self.containerView.isHidden = $0.count == 0
                vc.albums = $0
                vc.reloadTableView()
            }
        case 1:
            vc.resetData(.artist, responsiveScrolling: true)
            return api.artistSublist().done(on: .main) {
                self.containerView.isHidden = $0.count == 0
                vc.artists = $0
                vc.reloadTableView()
            }
        default:
            return .init()
        }
    }
    
    func startPlay(_ all: Bool) {
        guard let items = selectedItems().items as? [Track.Album],
              let item = items.first,
              !all
        else { return }
        let pc = PlayCore.shared
        pc.api.album(item.id).map {
            $0.songs
        }.done {
            pc.start($0)
        }.catch {
            Log.error($0)
        }
    }
    
    func albumArtistTableVC() -> AlbumArtistTableViewController? {
        let vc = children.compactMap {
            $0 as? AlbumArtistTableViewController
            }.first
        return vc
    }
}

extension SublistViewController: TAAPMenuDelegate {
    func selectedItems() -> (id: [Int], items: [Any]) {
        guard let vc = albumArtistTableVC() else {
            return ([], [])
        }
        switch vc.dataType {
        case .album:
            let items = vc.albums.enumerated().filter {
                vc.tableView.selectedIndexs().contains($0.offset)
            }.map {
                $0.element
            }
            return (items.map({ $0.id }), items)
        case .artist:
            let items = vc.artists.enumerated().filter {
                vc.tableView.selectedIndexs().contains($0.offset)
            }.map {
                $0.element
            }
            return (items.map({ $0.id }), items)
        default:
            return ([], [])
        }
    }
    
    func presentNewPlaylist(_ newPlaylisyVC: NewPlaylistViewController) {
        guard newPlaylisyVC.presentingViewController == nil else { return }
        self.presentAsSheet(newPlaylisyVC)
    }
    
    func removeSuccess(ids: [Int], newItem: Any?) {
        guard let vc = albumArtistTableVC() else {
            return
        }
        switch vc.dataType {
        case .album:
            vc.albums.removeAll {
                ids.contains($0.id)
            }
            vc.tableView.reloadData()
        case .artist:
            vc.artists.removeAll {
                ids.contains($0.id)
            }
            vc.tableView.reloadData()
        default:
            return
        }
    }
    
    func shouldReloadData() {
        initContent().done {
            
        }.catch {
            Log.error($0)
        }
    }
    
    func tableViewList() -> (type: SidebarViewController.ItemType, id: Int, contentType: TAAPItemsType) {
        guard let vc = albumArtistTableVC() else {
            return (.none, 0, .none)
        }
        return (.mySubscription, 0, vc.dataType)
    }
    
}

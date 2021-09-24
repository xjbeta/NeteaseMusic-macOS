//
//  DiscoverViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/19.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class DiscoverViewController: NSViewController, ContentTabViewController {
    @IBOutlet weak var collectionView: DailyCollectionView!
    
    class RecommendItem: NSObject {
        var title: String
        var imageUrl: URL?
        var id: Int = 0
        var alg: String
        var type: TAAPItemsType
        
        init(title: String, id: Int = -1, alg: String = "", type: TAAPItemsType = .playlist, imageU: URL? = nil) {
            self.title = title
            self.id = id
            self.type = type
            self.alg = alg
            self.imageUrl = imageU
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
    
    var recommendedItems = [RecommendItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.menu = menuContainer.menu
        menuContainer.menuController?.delegate = self
    }
    
    func initContent() -> Promise<()> {
        PlayCore.shared.api.recommendResource().map(on: .global()) { [weak self] res in
            self?.initRecommendedItems(res)
        }.done(on: .main) { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    func startPlay(_ all: Bool) {
        guard let items = selectedItems().items as? [DiscoverViewController.RecommendItem],
              let item = items.first else {
            return
        }
        
        let pc = PlayCore.shared
        
        firstly {
            item.id == -114514 ?
                pc.api.recommendSongs() :
                pc.api.playlistDetail(item.id).compactMap({ $0.tracks })
        }.done {
            pc.start($0)
        }.catch {
            print($0)
        }
    }
    
    func initRecommendedItems(_ playlists: [RecommendResource.Playlist]) {
        recommendedItems.removeAll()
        
        var items = [RecommendItem]()
        items.append(RecommendItem(title: "每日歌曲推荐", type: .dailyPlaylist))
        items.append(contentsOf: playlists.map({
            RecommendItem(title: $0.name, id: $0.id, alg: $0.alg, imageU: $0.picUrl)
        }))
        
        recommendedItems = items
    }
    
}

extension DiscoverViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendedItems.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if indexPath.item == 0 {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DailyCollectionViewItem"), for: indexPath)
            guard let itemm = item as? DailyCollectionViewItem,
                let rItem = recommendedItems[safe: indexPath.item] else {
                    return item
            }
            itemm.textField?.stringValue = rItem.title
            
            return item
        } else {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PlaylistCollectionViewItem"), for: indexPath)
            guard let selectVideoItem = item as? PlaylistCollectionViewItem,
                let rItem = recommendedItems[safe: indexPath.item] else {
                    return item
            }
            selectVideoItem.initItem(rItem)
            return item
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        // show playlist
        guard let item = indexPaths.first?.item,
            let rItem = recommendedItems[safe: item] else { return }
        
        let vcm = ViewControllerManager.shared
        if item == 0 {
            rItem.id = -114514
            vcm.selectSidebarItem(.discoverPlaylist, rItem.id)
        } else {
            vcm.selectSidebarItem(.subscribedPlaylist, rItem.id)
        }
        collectionView.deselectAll(nil)
    }
}

extension DiscoverViewController: TAAPMenuDelegate {
    func selectedItems() -> (id: [Int], items: [Any]) {
        guard let index = collectionView.clickedIndex,
            let item = recommendedItems[safe: index] else { return ([], []) }
        return ([item.id], [item])
    }
    
    func tableViewList() -> (type: SidebarViewController.ItemType, id: Int, contentType: TAAPItemsType) {
        guard let index = collectionView.clickedIndex,
            let item = recommendedItems[safe: index] else {
                return (.none, 0, .none)
        }
        return (.discover, item.id, item.type)
    }
    
    func removeSuccess(ids: [Int], newItem: Any?) {
        if let item = newItem as? RecommendResource.Playlist {
            guard let i = recommendedItems.firstIndex(where: { $0.id == ids.first }) else { return }
            recommendedItems[i] = .init(title: item.name, id: item.id, alg: item.alg, imageU: item.picUrl)
            collectionView.reloadItems(at: [IndexPath(item: i, section: 0)])
        } else {
            recommendedItems.removeAll {
                ids.contains($0.id)
            }
            collectionView.reloadData()
        }
    }
    
    func shouldReloadData() {
        initContent().done {
            
        }.catch {
            print($0)
        }
    }
    
    func presentNewPlaylist(_ newPlaylisyVC: NewPlaylistViewController) {
        return
    }

}

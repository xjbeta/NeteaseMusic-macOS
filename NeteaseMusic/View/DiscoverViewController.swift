//
//  DiscoverViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/19.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class DiscoverViewController: NSViewController {

    @IBOutlet weak var collectionView: NSCollectionView!
    enum RecommendPlaylist {
        case daily, normal
    }
    
    class RecommendItem: NSObject {
        var title: String
        var imageUrl: URL?
        var id: Int = 0
        var type: RecommendPlaylist
        
        init(title: String, id: Int = -1, type: RecommendPlaylist = .normal, imageU: URL? = nil) {
            self.title = title
            self.id = id
            self.type = type
            self.imageUrl = imageU
        }   
    }
    
    var recommendedItems = [RecommendItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func initRecommend() {
        PlayCore.shared.api.recommendResource().map(on: .global()) { [weak self] res in
            self?.recommendedItems.removeAll()
            self?.recommendedItems.append(RecommendItem(title: "每日歌曲推荐", type: .daily))
            res.forEach {
                self?.recommendedItems.append(RecommendItem(title: $0.name, id: $0.id, imageU: $0.picUrl))
            }
            }.done(on: .main) { [weak self] in
                self?.collectionView.reloadData()
            }.catch {
                print($0)
        }
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
        if item == 0 {
            rItem.id = -114514
        }
        
        ViewControllerManager.shared.selectSidebarItem(.discoverPlaylist, rItem.id)
        collectionView.deselectAll(nil)
    }
}

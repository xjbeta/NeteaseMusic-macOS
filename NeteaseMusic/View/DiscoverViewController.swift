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
    @IBOutlet var collectionViewMenu: NSMenu!
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var playNextMenuItem: NSMenuItem!
    @IBOutlet weak var subscribeMenuItem: NSMenuItem!
    @IBOutlet weak var copyLinkMenuItem: NSMenuItem!
    @IBOutlet weak var notInterestedMenuItem: NSMenuItem!
    
    @IBAction func menuItemAction(_ sender: NSMenuItem) {
        guard let index = collectionView.clickedIndex,
            let item = recommendedItems[safe: index] else { return }
        let playCore = PlayCore.shared
        
        switch sender {
        case playMenuItem:
            break
        case playNextMenuItem:
            break
        case subscribeMenuItem:
            playCore.api.playlistSubscribe(item.id).done {
                print("Subscribe playlist \(item.id) success.")
                }.catch {
                    print("Subscribe playlist \(item.id) error \($0).")
            }
        case copyLinkMenuItem:
            let str = "https://music.163.com/playlist?id=\(item.id)"
            ViewControllerManager.shared.copyToPasteboard(str)
        case notInterestedMenuItem:
            playCore.api.discoveryRecommendDislike(item.id, isPlaylist: true, alg: item.alg).done {
                print("Dislike playlist \(item.id) success.")
                guard let playlist = $0.1 else { return }
                
                if self.recommendedItems.contains(where: {
                    $0.id == playlist.id
                }) {
                    //        code == 432, msg == "今日暂无更多推荐"
                    
                    
                    return
                }
                
                
                self.recommendedItems[index] = .init(title: playlist.name, id: playlist.id, alg: playlist.alg, imageU: playlist.picUrl)
                self.collectionView.reloadData()
                }.catch {
                   print("Dislike playlist \(item.id) error \($0).")
            }
        default:
            break
        }
    }
    
    @IBOutlet weak var collectionView: DailyCollectionView!
    enum RecommendPlaylist {
        case daily, normal
    }
    
    class RecommendItem: NSObject {
        var title: String
        var imageUrl: URL?
        var id: Int = 0
        var alg: String
        var type: RecommendPlaylist
        
        init(title: String, id: Int = -1, alg: String = "", type: RecommendPlaylist = .normal, imageU: URL? = nil) {
            self.title = title
            self.id = id
            self.type = type
            self.alg = alg
            self.imageUrl = imageU
        }   
    }
    
    var recommendedItems = [RecommendItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func initRecommend() {
        PlayCore.shared.api.recommendResource().map(on: .global()) { [weak self] res in
            self?.initRecommendedItems(res)
            }.done(on: .main) { [weak self] in
                self?.collectionView.reloadData()
            }.catch {
                print($0)
        }
    }
    
    func initRecommendedItems(_ playlists: [RecommendResource.Playlist]) {
        recommendedItems.removeAll()
        recommendedItems.append(RecommendItem(title: "每日歌曲推荐", type: .daily))
        playlists.forEach {
            recommendedItems.append(RecommendItem(title: $0.name, id: $0.id, alg: $0.alg, imageU: $0.picUrl))
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

extension DiscoverViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let index = collectionView.clickedIndex,
            let item = recommendedItems[safe: index] else { return false }
        if index == 0 {
            return false
        } else {
            switch menuItem {
            case playMenuItem:
                break
            case playNextMenuItem:
                break
            case copyLinkMenuItem:
                return true
            case subscribeMenuItem:
                return true
            case notInterestedMenuItem:
                return true
            default:
                break
            }
        }
        return false
    }
}

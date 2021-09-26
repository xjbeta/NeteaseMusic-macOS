//
//  SidebarViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/5.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class SidebarViewController: NSViewController {

    @IBOutlet var topVisualEffectView: NSVisualEffectView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var searchField: NSSearchField!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet var outlineHeightLayoutConstraint: NSLayoutConstraint!
    
    @IBAction func search(_ sender: NSSearchField) {
        let pc = PlayCore.shared
        let str = sender.stringValue
        guard !str.isEmpty else {
            return
        }
        searchFieldDidStartSearching(sender)
        
        ViewControllerManager.shared.searchFieldString = str
        
        pc.api.searchSuggest(str).done {
            guard self.searchMode,
                  str == self.searchField.stringValue else {
                return
            }
            var items = [SidebarItem]()
            let re = $0
            if let songs = re.songs {
                let item = SidebarItem(title: "单曲", type: .searchSuggestionHeaderSongs)
                item.childrenItems = songs.map { song -> SidebarItem in
                    let i = SidebarItem(title: song.name, id: song.id, type: .searchSuggestionCellSong)
                    i.secondTitle = song.artists.map({ $0.name }).joined(separator: " ")
                    return i
                }
                items.append(item)
            }
            if let albums = re.albums {
                let item = SidebarItem(title: "专辑", type: .searchSuggestionHeaderAlbums)
                item.childrenItems = albums.map {
                    SidebarItem(title: $0.name, id: $0.id, type: .searchSuggestionCellAlbum)
                }
                items.append(item)
            }
            if let artists = re.artists {
                let item = SidebarItem(title: "歌手", type: .searchSuggestionHeaderArtists)
                item.childrenItems = artists.map {
                    SidebarItem(title: $0.name, id: $0.id, type: .searchSuggestionCellArtist)
                }
                items.append(item)
            }
            if let playlists = re.playlists {
                let item = SidebarItem(title: "歌单", type: .searchSuggestionHeaderPlaylists)
                
                item.childrenItems = playlists.map {
                    SidebarItem(title: $0.name, id: $0.id, type: .searchSuggestionCellPlaylist)
                }
                items.append(item)
            }
            
            self.sidebarItems = items
            self.outlineView.deselectAll(nil)
            self.outlineView.expandItem(nil, expandChildren: true)
            }.catch {
                Log.error("\($0)")
        }
    }
    
    @objc class SidebarItem: NSObject {
        @objc dynamic var title: String
        @objc dynamic var secondTitle = ""

        @objc dynamic var icon: NSImage? {
            get {
                var i: NSImage?
                switch type {
                case .discover:
                    i = NSImage(named: NSImage.Name("sidebar.sp#icn-discover"))
                case .fm:
                    i = NSImage(named: NSImage.Name("sidebar.sp#icn-fm"))
                case .favourite:
                    i = NSImage(named: NSImage.Name("sidebar.sp#icn-love"))
                case .createdPlaylist, .subscribedPlaylist:
                    i = NSImage(named: NSImage.Name("sidebar.sp#icn-song"))
                case .mySubscription:
                    i = NSImage(named: NSImage.Name("sidebar.sp#icn-myfav"))
                default:
                    break
                }
                
                return i?.tint(color: .nColor)
            }
        }
        var id: Int = 0
        var type: ItemType = .none
        @objc dynamic var selected = false
        
        @objc var isLeaf: Bool
        @objc var childrenCount = 0
        @objc dynamic var childrenItems = [SidebarItem]() {
            didSet {
                isLeaf = childrenItems.isEmpty
                childrenCount = childrenItems.count
            }
        }
        
        init(title: String = "", id: Int = -1, type: ItemType) {
            self.type = type
            isLeaf = true
            switch type {
            case .discover:
                self.title = "发现音乐"
            case .fm:
                self.title = "私人FM"
            case .mySubscription:
                self.title = "我的收藏"
            case .createdPlaylists:
                self.title = "创建的歌单"
                isLeaf = false
            case .subscribedPlaylists:
                self.title = "收藏的歌单"
                isLeaf = false
            default:
                self.title = title
            }
            
            self.id = id
        }
        
        override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
            switch key {
            case "icon", "titleColor":
                return Set(["selected"])
            default:
                return super.keyPathsForValuesAffectingValue(forKey: key)
            }
        }
    }
    
    enum ItemType {
        case discover,
             fm,
             favourite,
             none,
             discoverPlaylist,
             album,
             artist,
             topSongs,
             searchResults,
             fmTrash,
             createdPlaylists,
             createdPlaylist,
             subscribedPlaylists,
             subscribedPlaylist,
             preferences,
             mySubscription,
             sidebar,
             sidePlaylist,
             
             // SearchMode
             searchSuggestionHeaderSongs,
             searchSuggestionCellSong,
             searchSuggestionHeaderAlbums,
             searchSuggestionCellAlbum,
             searchSuggestionHeaderArtists,
             searchSuggestionCellArtist,
             searchSuggestionHeaderPlaylists,
             searchSuggestionCellPlaylist
    }
    
    let defaultItems = [SidebarItem(type: .discover),
                        SidebarItem(type: .fm),
                        SidebarItem(type: .mySubscription),
                        SidebarItem(type: .createdPlaylists),
                        SidebarItem(type: .subscribedPlaylists)]
    @objc dynamic var sidebarItems = [SidebarItem]()
    
    var outlineViewFrameObserver: NSObjectProtocol?
    var scrollViewObserver: NSObjectProtocol?
    var selectSidebarItemObserver: NSObjectProtocol?
    
    private var searchMode = false
    private var savedSidebarItems = [SidebarItem]()
    private var savedOutlineExpand = [Bool]()
    
    
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
        outlineView.menu = menuContainer.menu
        menuContainer.menuController?.delegate = self
        
        sidebarItems = defaultItems
        
        selectSidebarItemObserver = NotificationCenter.default.addObserver(forName: .selectSidebarItem, object: nil, queue: .main) { [weak self] in
            guard let dic = $0.userInfo as? [String: Any],
                let itemType = dic["itemType"] as? ItemType,
                let id = dic["id"] as? Int else { return }
            switch itemType {
            case .favourite:
                if let index = self?.sidebarItems.firstIndex(where: { $0.type == .createdPlaylists }) {
                    self?.outlineView.deselectAll(self)
                    self?.outlineView.selectRowIndexes(.init(integer: index + 1), byExtendingSelection: true)
                }
            case .fm:
                if let index = self?.sidebarItems.firstIndex(where: { $0.type == itemType }) {
                    self?.outlineView.deselectAll(self)
                    self?.outlineView.selectRowIndexes(.init(integer: index), byExtendingSelection: true)
                }
            case .album,
                 .artist,
                 .topSongs,
                 .createdPlaylist,
                 .subscribedPlaylist,
                 .fmTrash,
                 .discoverPlaylist,
                 .preferences,
                 
                 
                 .searchSuggestionHeaderSongs,
                 .searchSuggestionHeaderAlbums,
                 .searchSuggestionHeaderArtists,
                 .searchSuggestionHeaderPlaylists:
                
                self?.outlineView.deselectAll(self)
                ViewControllerManager.shared.selectedSidebarItem = .init(title: "", id: id, type: itemType)
            default:
                break
            }
            self?.updateSidebarItemsSelection()
        }
        
        topVisualEffectView.shadow = nil
        
        (outlineView.enclosingScrollView as? UnresponsiveScrollView)?.responsiveScrolling = false
        outlineView.enclosingScrollView?.documentView?.postsFrameChangedNotifications = true
        
        outlineViewFrameObserver = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: nil, queue: .main) {

            guard let view = $0.object as? NSView,
                  view == self.scrollView.documentView else {
                return
            }

            self.updateScrollViews()
        }
        
        scrollViewObserver = NotificationCenter.default.addObserver(forName: NSScrollView.didLiveScrollNotification, object: nil, queue: .main) {
            guard let sView = $0.object as? NSScrollView,
                  sView == self.scrollView,
                  let veView = self.topVisualEffectView else {
                return
            }
            
            let visibleRect = sView.contentView.documentVisibleRect
            let documentRect = sView.contentView.documentRect
            
            let y = documentRect.height - visibleRect.height - visibleRect.origin.y
            
            
            
            // top - 12 - searchField
            if y > 12,
               veView.shadow == nil {
                let s = NSShadow()
                s.shadowColor = .black
                s.shadowOffset = .init(width: 0, height: 2)
                s.shadowBlurRadius = 2
                veView.shadow = s
            } else if y <= 12, veView.shadow != nil {
                veView.shadow = nil
            }
        }
        

        updateSidebarItemsSelection()
        
        
        searchField.delegate = self
    }
    
    func updatePlaylists() -> Promise<()> {
        PlayCore.shared.api.userPlaylist().done(on: .main) {
            let created = $0.filter {
                !$0.subscribed
            }.map {
                SidebarItem(title: $0.name, id: $0.id, type: .createdPlaylist)
            }
            
            if let item = created.first, item.title.contains("喜欢的音乐") {
                created[0].title = "我喜欢的音乐"
                created[0].type = .favourite
            }
            
            self.sidebarItems.filter({
                $0.title == "创建的歌单"
            }).first?.childrenItems = created
            
            let subscribed = $0.filter {
                $0.subscribed
            }.map {
                SidebarItem(title: $0.name, id: $0.id, type: .subscribedPlaylist)
            }
            
            self.sidebarItems.filter({
                $0.title == "收藏的歌单"
            }).first?.childrenItems = subscribed
            
            self.outlineView.expandItem(nil, expandChildren: true)
        }
    }
    
    func updateScrollViews() {
        let h = outlineViewHeight()
        guard let docView = scrollView.documentView else {
            return
        }
        
        outlineHeightLayoutConstraint.constant = h + scrollView.pageHeader.size().height
        var size = docView.frame.size
        
        // top - 12 - searchField - 4 - outlineView
        size.height = h + (12 + searchField.frame.height + 4)
        
        let min = scrollView.frame.height
        
        if size.height < min {
            size.height = min
        }
        
        docView.setFrameSize(size)
        docView.scroll(.init(x: 0, y: size.height))
    }
    
    deinit {
        if let obs = selectSidebarItemObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

extension SidebarViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return nil
        }
        
        var identifier = ""
        
        if searchMode {
            switch node.type {
            case .searchSuggestionHeaderSongs,
                 .searchSuggestionHeaderAlbums,
                 .searchSuggestionHeaderArtists,
                 .searchSuggestionHeaderPlaylists:
                identifier = "SidebarSearchHeaderCell"
            case .searchSuggestionCellSong,
                 .searchSuggestionCellAlbum,
                 .searchSuggestionCellArtist,
                 .searchSuggestionCellPlaylist:
                identifier = "SidebarSearchDataCell"
            default:
                break
            }
        } else if !node.isLeaf {
            identifier = "SidebarHeaderCell"
        } else {
            identifier = "SidebarDataCell"
        }
        
        guard let view = outlineView.makeView(
                withIdentifier: .init(identifier),
                owner: self) as? NSTableCellView else {
            return nil
        }
        
        return view
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        guard searchMode,
              let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return nil
        }
        
        
        
        
        return ["title": node.title,
                "secondName": node.secondTitle,
                "withSecondLabel": node.type == .searchSuggestionCellSong]
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return 0
        }
        
        if searchMode {
            return 15
        } else if node.isLeaf {
            return 21
        } else {
            return 17
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let node = (item as? NSTreeNode)?.representedObject as? SidebarItem else {
            return false
        }
        
        return node.isLeaf || searchMode
    }
    
    func outlineViewItemDidExpand(_ notification: Notification) {
        updateScrollViews()
    }
    
    func outlineViewItemDidCollapse(_ notification: Notification) {
        updateScrollViews()
    }
    
    
    func outlineViewHeight() -> CGFloat {
        guard outlineView.numberOfRows > 0 else {
            return 0
        }
        let hs = (0..<outlineView.numberOfRows).compactMap {
            outlineView.item(atRow: $0)
        }.map {
            outlineView(outlineView, heightOfRowByItem: $0)
        }
        
        var height = hs.reduce(0, +)
        height += CGFloat(outlineView.numberOfRows) * outlineView.intercellSpacing.height
//        height += outlineView.headerView?.frame.height ?? 0
        
        height += 10
        return height
    }
    
    
    func updateSidebarItemsSelection() {
        let outlineViewNotification = Notification(name: NSOutlineView.selectionDidChangeNotification, object: nil, userInfo: nil)
        outlineViewSelectionIsChanging(outlineViewNotification)
    }
    
    func outlineViewSelectionIsChanging(_ notification: Notification) {
        
        guard let item = (outlineView.item(atRow: outlineView.selectedRow) as? NSTreeNode)?.representedObject as? SidebarItem else {
            return
        }
        
        if searchMode {
            
            Log.info(item.id, item.title)
            
            let pc = PlayCore.shared
            let vcm =  ViewControllerManager.shared
            switch item.type {
            case .searchSuggestionCellSong:
                pc.api.songDetail([item.id]).done {
                    $0.forEach {
                        $0.from = (.searchResults, 0, "Search Suggestions")
                    }
                    pc.playNow($0)
                    }.catch {
                        Log.error("\($0)")
                }
            case .searchSuggestionCellAlbum:
                vcm.selectSidebarItem(.album, item.id)
            case .searchSuggestionCellArtist:
                vcm.selectSidebarItem(.artist, item.id)
            case .searchSuggestionCellPlaylist:
                vcm.selectSidebarItem(.subscribedPlaylist, item.id)
            case .searchSuggestionHeaderSongs,
                 .searchSuggestionHeaderAlbums,
                 .searchSuggestionHeaderArtists,
                 .searchSuggestionHeaderPlaylists:
                vcm.selectSidebarItem(item.type, item.id)
            default:
                break
            }
            
            searchField.stringValue = "" 
            
            usleep(useconds_t(500))
            searchFieldDidEndSearching(searchField)
        } else {
            
            ViewControllerManager.shared.selectedSidebarItem = item
        }
    }
}

extension SidebarViewController: TAAPMenuDelegate {
    func selectedItems() -> (id: [Int], items: [Any]) {
        guard let item = (outlineView.item(atRow: outlineView.clickedRow) as? NSTreeNode)?.representedObject as? SidebarItem else {
            return ([], [])
        }
        return ([item.id], [item])
    }
    
    func tableViewList() -> (type: SidebarViewController.ItemType, id: Int, contentType: TAAPItemsType) {
        guard let item = (outlineView.item(atRow: outlineView.clickedRow) as? NSTreeNode)?.representedObject as? SidebarItem else {
            return (.none, 0, .none)
        }
        
        switch item.type {
        case .subscribedPlaylist:
            return (.sidebar, item.id, .playlist)
        case .createdPlaylist:
            return (.sidebar, item.id, .createdPlaylist)
        case .favourite:
            return (.sidebar, item.id, .favouritePlaylist)
        default:
            return (.sidebar, item.id, .none)
        }
    }
    
    func removeSuccess(ids: [Int], newItem: Any?) {
        sidebarItems.filter {
            $0.type == .createdPlaylists || $0.type == .subscribedPlaylists
        }.forEach {
            $0.childrenItems.removeAll {
                ids.contains($0.id)
            }
        }
        
        if let item = ViewControllerManager.shared.selectedSidebarItem,
            item.type == .createdPlaylist || item.type == .subscribedPlaylist,
            ids.contains(item.id) {
            ViewControllerManager.shared.selectSidebarItem(.favourite)
        }
    }
    
    func shouldReloadData() {
        updatePlaylists().done {
            
        }.catch {
            Log.error("\($0)")
        }
    }
    
    func presentNewPlaylist(_ newPlaylisyVC: NewPlaylistViewController) {
        guard newPlaylisyVC.presentingViewController == nil else { return }
        self.presentAsSheet(newPlaylisyVC)
    }
    
    func startPlay() {
        guard let item = (outlineView.item(atRow: outlineView.clickedRow) as? NSTreeNode)?.representedObject as? SidebarItem else {
            return
        }
        let pc = PlayCore.shared
        switch item.type {
        case .createdPlaylist, .subscribedPlaylist, .favourite:
            pc.api.playlistDetail(item.id).compactMap {
                $0.tracks
            }.done {
                pc.start($0)
            }.catch {
                Log.error("\($0)")
            }
        default:
            break
        }
    }
}


extension SidebarViewController: NSSearchFieldDelegate {
    func searchFieldDidStartSearching(_ sender: NSSearchField) {
        guard !searchMode else { return }
        searchMode = true
        savedOutlineExpand = (0..<outlineView.numberOfRows).compactMap {
            outlineView.item(atRow: $0)
        }.map {
            outlineView.isItemExpanded($0)
        }
        
        savedSidebarItems = sidebarItems
        sidebarItems = []
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        guard searchMode else { return }
        searchMode = false
        sidebarItems = savedSidebarItems
        
        savedOutlineExpand.enumerated().forEach {
            guard let item = outlineView.item(atRow: $0.offset) else { return }
            if $0.element {
                outlineView.expandItem(item)
            } else {
                outlineView.collapseItem(item)
            }
        }
        
        savedSidebarItems = []
        savedOutlineExpand = []
    }
}

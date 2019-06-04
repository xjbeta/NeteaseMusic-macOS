//
//  MainWindowController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/9.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    @IBOutlet weak var searchField: NSSearchField!
    
    @IBAction func search(_ sender: NSSearchField) {
        let str = sender.stringValue
        ViewControllerManager.shared.searchFieldString = str
        if str.isEmpty {
            popover.close()
            return
        }
        
        PlayCore.shared.api.searchSuggest(str).done { [weak self] in
            guard str == self?.searchField.stringValue else { return }
            self?.searchSuggestionsVC.suggestResult = $0
            self?.searchSuggestionsVC.initViewHeight(self?.popover)
            }.catch {
                print($0)
        }
        
        guard !popover.isShown else { return }
        popover.show(relativeTo: sender.frame, of: sender, preferredEdge: .minY)
    }
    
    let searchSuggestionsVC = NSStoryboard(name: .init("SearchSuggestionsView"), bundle: nil).instantiateController(withIdentifier: .init("SearchSuggestionsViewController")) as! SearchSuggestionsViewController
    
    lazy var popover: NSPopover = {
        let p = NSPopover()
        searchSuggestionsVC.dismissPopover = {
            p.close()
        }
        p.contentViewController = searchSuggestionsVC
        return p
    }()
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.isMovableByWindowBackground = true
    }

}

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
        if sender.stringValue.isEmpty {
            searchSuggestionsVC.dismiss(nil)
            return
        }
        let str = sender.stringValue
        PlayCore.shared.api.searchSuggest(str).done {
            guard str == self.searchField.stringValue else { return }
            self.searchSuggestionsVC.suggestResult = $0
            }.catch {
                print($0)
        }
        
        guard !searchSuggestionsVC.displayed else { return }
        contentViewController?.present(searchSuggestionsVC,
                                       asPopoverRelativeTo: sender.frame,
                                       of: sender,
                                       preferredEdge: .minY,
                                       behavior: .transient)
    }
    
    let searchSuggestionsVC = NSStoryboard(name: .init("Main"), bundle: nil).instantiateController(withIdentifier: .init("SearchSuggestionsViewController")) as! SearchSuggestionsViewController
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.isMovableByWindowBackground = true
    }

}

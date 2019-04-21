//
//  DailyCollectionViewItem.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/21.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class DailyCollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak var dateTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 5
        imageView?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        imageView?.layer?.borderWidth = 0.5
        initDateTextField()
    }
    
    func initDateTextField() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        dateTextField.stringValue = formatter.string(from: date)
    }
    
}

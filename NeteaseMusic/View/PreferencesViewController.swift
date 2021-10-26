//
//  PreferencesViewController.swift
//  Netease Music
//
//  Created by xjbeta on 10/10/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

class PreferencesViewController: NSViewController, ContentTabViewController {

    @IBOutlet var scrollView: NSScrollView!
    var uid = -1
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
    }
    
    func initContent() -> Promise<()> {
        let api = PlayCore.shared.api
        let vc = subVC()
        
        if uid == -1 || api.uid != uid {
            return api.nuserAccount().done {
                guard let name = $0?.nickname,
                      let uid = $0?.userId
                else {
                    vc?.userNameTextField.stringValue = "未知"
                    return
                }
                vc?.userNameTextField.stringValue = name
                self.uid = uid
                
                guard let str = $0?.avatarUrl.https,
                      let u = URL(string: str),
                      let img = NSImage(contentsOf: u)
                else {
                    vc?.userImageView.image = NSImage(named: .init("user_150"))
                    return
                }
                vc?.userImageView.image = img
            }
        } else {
            return .init()
        }
    }
    
    func startPlay(_ all: Bool) {
    }
    
    func subVC() -> PreferencesSubViewController? {
        children.compactMap({ $0 as? PreferencesSubViewController }).first
    }
    
}

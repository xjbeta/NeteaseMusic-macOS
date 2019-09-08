//
//  LogoutViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/8.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class LogoutViewController: NSViewController {

    @IBAction func logout(_ sender: NSButton) {
        PlayCore.shared.api.logout().done {
            print("Logout success.")
            NotificationCenter.default.post(name: .updateLoginStatus, object: nil, userInfo: ["logout": true])
            }.ensure(on: .main) {
                self.dismiss(self)
            }.catch {
                print("Logout error \($0).")
                NotificationCenter.default.post(name: .updateLoginStatus, object: nil, userInfo: ["logout": false])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

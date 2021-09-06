//
//  ContentTabViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 9/4/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Cocoa
import PromiseKit

enum ContentTabInitError: Error {
    case wrongTab
    case noneID
    
}


protocol ContentTabViewController {
    func initContent() -> Promise<()>
}

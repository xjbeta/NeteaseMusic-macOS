//
//  NMStructs.swift
//  NeteaseMusic
//
//  Created by xjbeta on 8/15/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Foundation

struct NMEapiParams: Codable {
    var header: String
    var os = "OSX"
    var deviceId: String
    var verifyId = 1
}

struct NMEapiHeader: Codable {
    var os = "osx"
    var appver: String
    var deviceId: String
    var requestId: String
    var clientSign = ""
}



//
//  HttpsURL.swift
//  NeteaseMusic
//
//  Created by xjbeta on 7/22/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Foundation

extension URL {
    var https: URL? {
        get {
            let str = self.absoluteString
                .replacingOccurrences(of: "http://", with: "https://")
            return URL(string: str)
        }
    }
}

//
//  HttpsExtensions.swift
//  NeteaseMusic
//
//  Created by xjbeta on 7/22/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Foundation

extension String {
    var https: String {
        get {
            if starts(with: "http://") {
                return replacingOccurrences(of: "http://", with: "https://")
            } else {
                return self
            }
        }
    }
}

extension URL {
    var https: URL? {
        get {
            return URL(string: absoluteString.https)
        }
    }
}

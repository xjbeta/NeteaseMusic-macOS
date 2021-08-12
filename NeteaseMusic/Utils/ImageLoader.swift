//
//  ImageLoader.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/25.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import Kingfisher
import Alamofire

class ImageLoader: NSObject {
    static func image(_ url: String,
                      _ autoSize: Bool = false,
                      _ width: CGFloat = 0) -> KF.Builder {
        var u = url
        
        if autoSize {
            let w = Int(width * (NSScreen.main?.backingScaleFactor ?? 1))
            let p = "?param=\(w)y\(w)"
            u += p
        }
        
        let uu = URL(string: u)
        let key = key(uu)
        
        return KF.url(uu, cacheKey: key)
    }
    
    static func key(_ url: URL?) -> String? {
        guard let url = url else { return nil }
        var key = url.lastPathComponent
        if let query = URLComponents(url: url, resolvingAgainstBaseURL: true)?.query {
            key.append(query)
        }
        return key
    }
}


extension NSImageView {
    public func setImage(_ url: String?, _ autoSize: Bool = false, _ width: CGFloat? = nil) {
        self.image = nil
        guard let u = url, u != "" else {
            return
        }
        ImageLoader.image(u, autoSize, width ?? frame.width).set(to: self)
    }
}

extension NSButton {
    public func setImage(_ url: String?, _ autoSize: Bool = false, _ width: CGFloat? = nil) {
        self.image = nil
        guard let u = url, u != "" else {
            return
        }
        ImageLoader.image(u, autoSize, width ?? frame.width).set(to: self)
    }
}

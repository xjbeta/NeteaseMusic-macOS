//
//  ImageLoader.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/25.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import Alamofire
import AlamofireImage

class ImageLoader: NSObject {
    static let imageCache = AutoPurgingImageCache(memoryCapacity: 200_000_000)
    
    static func request(_ url: String, complete: @escaping ((NSImage) -> ())) {
        AF.request(url).responseData {
            guard let d = $0.data,
                let image = NSImage(data: d) else { return }
            complete(image)
        }
    }
    
    static func image(_ url: String,
                      _ autoSize: Bool = false,
                      _ width: CGFloat = 0,
                      complete: @escaping ((NSImage) -> ())) {
        var u = url
        
        if autoSize {
            let w = Int(width * (NSScreen.main?.backingScaleFactor ?? 1))
            u += "?param=\(w)y\(w)"
        }
        
        if let image = imageCache.image(withIdentifier: u) {
            complete(image)
        } else {
            ImageLoader.request(u) { image in
                imageCache.add(image, withIdentifier: u)
                complete(image)
            }
        }
    }
}


extension NSImageView {
    public func setImage(_ url: String, _ autoSize: Bool = false, _ width: CGFloat? = nil) {
        self.image = nil
        guard url != "" else {
            return
        }
        ImageLoader.image(url, autoSize, width ?? frame.width) {
            self.image = $0
        }
    }
}

extension NSButton {
    public func setImage(_ url: String, _ autoSize: Bool = false, _ width: CGFloat? = nil) {
        self.image = nil
        guard url != "" else {
            return
        }
        ImageLoader.image(url, autoSize, width ?? frame.width) {
            self.image = $0
        }
    }
}

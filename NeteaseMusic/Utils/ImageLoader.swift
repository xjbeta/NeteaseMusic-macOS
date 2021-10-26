//
//  ImageLoader.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/25.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import SDWebImage
import Alamofire

class ImageLoader: NSObject {
    static func image(_ url: String?,
                      _ autoSize: Bool = false,
                      _ width: CGFloat = 0,
                      completion: @escaping (NSImage?) -> Void) {
        guard var u = url else {
            completion(nil)
            return
        }
        
        if autoSize {
            let w = Int(width * (NSScreen.main?.backingScaleFactor ?? 1))
            let p = "?param=\(w)y\(w)"
            u += p
        }
        
        let uu = URL(string: u)
        let key = key(uu)
        
        let imageCache = SDImageCache.shared
        
        if let image = imageCache.imageFromDiskCache(forKey: key) {
            completion(image)
        } else {
            SDWebImageManager.shared.loadImage(with: uu, progress: nil) { img,_,_,_,_,_ in
                
                completion(img)
            }
        }
    }
    
    static func key(_ url: URL?) -> String? {
        guard let url = url else { return nil }
        var key = url.lastPathComponent
        if let query = URLComponents(url: url, resolvingAgainstBaseURL: true)?.query {
            key.append(query)
        }
        key += ".jpg"
        return key
    }
    
}


extension NSImageView {
    public func setImage(_ url: String?, _ autoSize: Bool = false, _ width: CGFloat? = nil) {
        self.image = nil
        ImageLoader.image(url, autoSize, width ?? frame.width) {
            self.image = $0
        }
    }
}

extension NSButton {
    public func setImage(_ url: String?, _ autoSize: Bool = false, _ width: CGFloat? = nil) {
        self.image = nil
        ImageLoader.image(url, autoSize, width ?? frame.width) {
            self.image = $0
        }
    }
}

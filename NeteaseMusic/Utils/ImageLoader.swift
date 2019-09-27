//
//  ImageLoader.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/25.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import Cache
import Alamofire

class ImageLoader: NSObject {
    static var storage: DiskStorage<Image> {
        get {
            
            let diskConfig = DiskConfig(name: Bundle.main.bundleIdentifier! + ".imageCache",
                                        expiry: .seconds(3600 * 24 * 7),  // a week
                maxSize: 100*1000000)
            
            let storage = try! DiskStorage<Image>(config: diskConfig,
                                                  transformer: TransformerFactory.forImage())
            return storage
        }
    }
    
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
        
        if let image = try? ImageLoader.storage.object(forKey: u) {
            complete(image)
        } else {
            ImageLoader.request(u) { image in
                try? ImageLoader.storage.setObject(image, forKey: u)
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

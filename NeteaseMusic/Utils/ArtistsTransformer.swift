//
//  ArtistsTransformer.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/10.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

@objc(ArtistsTransformer)
class ArtistsTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let track = value as? Track else {
            return nil
        }
        return track.artists.artistsString()
    }
}


extension Array where Element: Track.Artist {
    func artistsString() -> String {
        return self.map {
            $0.name
            }.joined(separator: " / ")
    }
}

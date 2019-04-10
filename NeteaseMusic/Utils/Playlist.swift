//
//  Playlist.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/10.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Foundation

struct PlayList: Decodable {
    let subscribed: Bool
    let coverImgUrl: URL
    let playCount: Int
    let name: String
    let trackCount: Int
    let description: String?
    let tags: [String]
    let id: Int
    let tracks: [Track]?
    let trackIds: [trackId]?
    
    @objc(Track)
    class Track: NSObject, Decodable {
        @objc let name: String
        let id: Int
        // 2: No copyright, 1: copyright , 0: ?
        let copyright: Int
        @objc let al: Album
        // duration, ms
        @objc let dt: Int
        let ar: [Artist]
    }
    
    @objc(Album)
    class Album: NSObject, Decodable {
        @objc let name: String
        let id: Int
        let picUrl: URL?
    }
    
    struct Artist: Decodable {
        let name: String
        let id: Int
    }
    
    struct trackId: Decodable {
        let id: Int
    }
}

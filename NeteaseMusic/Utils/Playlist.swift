//
//  Playlist.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/10.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Foundation
import AVFoundation

struct Playlist: Decodable {
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
        
        var song: Song?
        @objc var index = -1
        
        @objc lazy var artistsString: String = {
            return ar.artistsString()
        }()
        
        enum CodingKeys: String, CodingKey {
            case name, id, copyright, al, dt, ar, song
        }
    }
    
    @objc(Album)
    class Album: NSObject, Decodable {
        @objc let name: String
        let id: Int
        @objc let picUrl: URL?
    }
    
    @objc(Artist)
    class Artist: NSObject, Decodable {
        let name: String
        let id: Int
    }
    
    struct trackId: Decodable {
        let id: Int
    }
}


@objc(Song)
class Song: NSObject, Decodable {
    let id: Int
    let url: URL?
    // 320kbp  =>  320,000
    let br: Int
    
    lazy var playerItem: AVPlayerItem? = {
        guard let uStr = url?.absoluteString.replacingOccurrences(of: "http://", with: "https://"),
            let url = URL(string: uStr) else {
                return nil
        }
        
        let avAsset = AVURLAsset(url: url)
        return AVPlayerItem(asset: avAsset)
    }()
}

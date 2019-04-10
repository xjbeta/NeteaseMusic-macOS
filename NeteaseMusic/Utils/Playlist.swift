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



struct Song: Decodable {
    let id: Int
    let url: URL
    // 320kbp  =>  320,000
    let br: Int
    //        {
    //            "data": [{
    //            "id": 21311956,
    //            "url": "http://m701.music.126.net/20190410200850/e986731210da149ee747a367a38c6ed9/jdyyaac/0452/545c/0158/384f8e1a3ac69235d5ff6214e3e849a3.m4a",
    //            "br": 96000,
    //            "size": 3744977,
    //            "md5": "384f8e1a3ac69235d5ff6214e3e849a3",
    //            "code": 200,
    //            "expi": 1200,
    //            "type": "m4a",
    //            "gain": -7.2279,
    //            "fee": 8,
    //            "uf": null,
    //            "payed": 0,
    //            "flag": 128,
    //            "canExtend": false,
    //            "freeTrialInfo": null,
    //            "level": "standard",
    //            "encodeType": "aac"
    //            }],
    //            "code": 200
    //        }
}

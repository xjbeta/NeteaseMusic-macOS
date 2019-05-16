//
//  CodableObjects.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/10.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Foundation
import AVFoundation
import AppKit
import PromiseKit

@objc(Track)
class Track: NSObject, Decodable {
    @objc let name: String
    @objc let secondName: String
    let id: Int
    @objc let artists: [Artist]
    @objc let album: Album
    @objc let duration: Int
    var song: Song?
    
    // 2: No copyright, 1: copyright , 0: ?
    let copyright: Int?
    
    let pop: Int?
    
    @objc var index = -1
    
    @objc lazy var artistsString: String = {
        return artists.artistsString()
    }()
    
    lazy var albumCover: NSImage? = {
        guard let urlStr = album.picUrl?.absoluteString,
            let u = URL(string: urlStr.replacingOccurrences(of: "http://", with: "https://")) else {
            return nil
        }
        return NSImage(contentsOf: u)
    }()
    
    func playerItemm() -> Promise<AVPlayerItem?> {
        return Promise { resolver in
            PlayCore.shared.api.songUrl([id]).get {
                self.song = $0.first
                }.done {
                    guard let uStr = $0.first?.url?.absoluteString.replacingOccurrences(of: "http://", with: "https://"),
                        let url = URL(string: uStr) else {
                            resolver.fulfill(nil)
                            return
                    }
                    let avAsset = AVURLAsset(url: url)
                    resolver.fulfill(AVPlayerItem(asset: avAsset))
                }.catch {
                    resolver.reject($0)
            }
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
    
    enum CodingKeys: String, CodingKey {
        case name, id, copyright, pop, artists, album, duration
    }
    
    enum SortCodingKeys: String, CodingKey {
        case artists = "ar", album = "al", duration = "dt"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sortContainer = try decoder.container(keyedBy: SortCodingKeys.self)
        let fullName = try container.decode(String.self, forKey: .name)
        if fullName.contains("("), fullName.last == ")" {
            name = fullName.subString(to: "(")
            secondName = "(" + fullName.subString(from: "(", to: ")") + ")"
        } else {
            name = fullName
            secondName = ""
        }
        self.id = try container.decode(Int.self, forKey: .id)
        
        self.copyright = try container.decodeIfPresent(Int.self, forKey: .copyright)
        self.pop = try container.decodeIfPresent(Int.self, forKey: .pop)
        
        self.artists = try container.decodeIfPresent([Artist].self, forKey: .artists) ?? sortContainer.decode([Artist].self, forKey: .artists)
        self.album = try container.decodeIfPresent(Album.self, forKey: .album) ?? sortContainer.decode(Album.self, forKey: .album)
        self.duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? sortContainer.decode(Int.self, forKey: .duration)
    }
}

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
}

struct RecommendResource: Decodable {
    let code: Int
    let recommend: [Playlist]
    
    struct Playlist: Decodable {
        let id: Int
        let name: String
        let copywriter: String
        let picUrl: URL
        let trackCount: Int
        let playcount: Int
    }
}

struct RecommendSongs: Decodable {
    let code: Int
    let recommend: [Track]
}

struct LyricResult: Decodable {
    let code: Int
    let lrc: Lrc?
    let tlyric: Lrc?
    let nolyric: Bool?
    let uncollected: Bool?
    
    struct Lrc: Decodable {
        let version: Int
        let lyric: String?
    }
}

struct SearchSuggest: Decodable {
    let code: Int
    let result: Result
    
    struct Result: Decodable {
        let songs: [Song]?
        let albums: [Album]?
        let mvs: [MV]?
        let artists: [Artist]?
        let playlists: [Playlist]?
        let order: [String]?
    }
    
    struct Song: Decodable {
        let name: String
        let id: Int
        let album: Album
        let artists: [Artist]
    }
    
    struct Album: Decodable {
        let name: String
        let id: Int
        let artist: Artist
    }
    
    struct MV: Decodable {
        let name: String
        let id: Int
        let cover: URL
    }
    
    struct Artist: Decodable {
        let name: String
        let id: Int
        let img1v1Url: URL
    }
    
    struct Playlist: Decodable {
        let name: String
        let id: Int
        let coverImgUrl: URL
    }
}

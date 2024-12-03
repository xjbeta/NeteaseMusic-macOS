//
//  NeteaseMusicAPI.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/31.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import Alamofire
import PromiseKit

class NeteaseMusicAPI: NSObject {
    
    let nmDeviceId: String
    let nmAppver: String
    let channel: NMChannel
    let nmSession: Session
    var reachabilityManager: NetworkReachabilityManager?
    
    override init() {
        nmDeviceId = "\(UUID().uuidString)|\(UUID().uuidString)"
        nmAppver = "1.5.10"
        channel = NMChannel(nmDeviceId, nmAppver)
        
        let session = Session(configuration: .default)
        let cookies = ["deviceId",
                       "os",
                       "appver",
                       "MUSIC_U",
                       "__csrf",
                       "ntes_kaola_ad",
                       "channel",
                       "__remember_me",
                       "NMTID",
                       "osver"]
        
        session.sessionConfiguration.httpCookieStorage?.cookies?.filter {
            !cookies.contains($0.name)
        }.forEach {
            session.sessionConfiguration.httpCookieStorage?.deleteCookie($0)
        }
        
        
        ["deviceId": nmDeviceId,
         "os": "osx",
         "appver": nmAppver,
         "channel": "netease",
         "osver": "Version%2010.16%20(Build%2020G165)",
        ].compactMap {
            HTTPCookie(properties: [
                .domain : ".music.163.com",
                .name: $0.key,
                .value: $0.value,
                .path: "/"
            ])
        }.forEach {
            session.sessionConfiguration.httpCookieStorage?.setCookie($0)
        }
        
        session.sessionConfiguration.headers = HTTPHeaders.default
        session.sessionConfiguration.headers.update(name: "user-agent", value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_16) AppleWebKit/605.1.15 (KHTML, like Gecko)")
        nmSession = session
    }

    
    var uid = -1
    var csrf: String {
        get {
            return HTTPCookieStorage.shared.cookies?.filter({ $0.name == "__csrf" }).first?.value ?? ""
        }
    }
    
    struct CodeResult: Decodable {
        let code: Int
        let msg: String?
    }
    
    func startNRMListening() {
        stopNRMListening()
        
        reachabilityManager = NetworkReachabilityManager(host: "music.163.com")
        reachabilityManager?.startListening { status in
            switch status {
            case .reachable(.cellular):
                Log.error("NetworkReachability reachable cellular.")
            case .reachable(.ethernetOrWiFi):
                Log.error("NetworkReachability reachable ethernetOrWiFi.")
            case .notReachable:
                Log.error("NetworkReachability notReachable.")
            case .unknown:
                break
            }
        }
    }
    
    func stopNRMListening() {
        reachabilityManager?.stopListening()
        reachabilityManager = nil
    }
    
    func nuserAccount() -> Promise<NUserProfile?> {
        struct Result: Decodable {
            let code: Int
            let profile: NUserProfile?
        }
        
        return eapiRequest(
            "https://music.163.com/eapi/nuser/account/get",
            [:],
            Result.self).map {
                $0.profile
            }.get {
                if self.uid == -1, let id = $0?.userId {
                    self.uid = id
                }
            }
    }
    
    func userPlaylist() -> Promise<[Playlist]> {
        struct Result: Decodable {
            let playlist: [Playlist]
            let code: Int
        }
        
        let p = [
            "uid": uid,
            "offset": 0,
            "limit": 1000
        ]
        
        return eapiRequest("https://music.163.com/eapi/user/playlist/",
            p,
            Result.self).map {
                $0.playlist
        }
    }
    
    func playlistDetail(_ id: Int) -> Promise<(Playlist)> {
        struct Result: Decodable {
            let playlist: Playlist
            let privileges: [Track.Privilege]?
            let code: Int
        }

        let p = [
            "id": id,
            "n": 0,
            "s": 0,
            "t": -1
        ]
        
        
        var playlist: Playlist?
        
        return eapiRequest(
            "https://music.163.com/eapi/v3/playlist/detail",
            p,
            Result.self).get {
                playlist = $0.playlist
            }.compactMap { re -> [Promise<[Track]>]? in
                guard let ids = re.playlist.trackIds?.map({ $0.id }) else {
                    return nil
                }
                let list = stride(from: 0, to: ids.count, by: 500).map {
                    Array(ids[$0..<($0+500 >= ids.count ? ids.count : $0+500)])
                }
                return list.map {
                    self.songDetail($0)
                }
            }.then {
                when(fulfilled: $0)
            }.compactMap { re -> Playlist? in
                let tracks = re.flatMap { $0 }
                guard var pl = playlist else {
                    return nil
                }
                let type: SidebarViewController.ItemType = pl.creator?.userId == self.uid ? .createdPlaylist: .subscribedPlaylist
                pl.tracks = tracks
                pl.tracks?.forEach { t in
                    t.from = (type, pl.id, pl.name)
                }
                return pl
            }
    }
    
    /*
    func playlistDetail(_ id: Int) -> Promise<(Playlist)> {
        struct P: Encodable {
            let id: Int
            let n: Int
            let s: Int
            let t = -1
        }
        
        struct Result: Decodable {
            let playlist: Playlist
            let privileges: [Track.Privilege]
            let code: Int
        }
        
        let p = P(id: id, n: 0, s: 0)
        
        return eapiRequest("https://music.163.com/eapi/v3/playlist/detail",
                           p,
                           Result.self).map { re -> Playlist in
                            let p = re.playlist
                            let type: SidebarViewController.ItemType = p.creator?.userId == self.uid ? .createdPlaylist: .subscribedPlaylist
                            p.tracks?.forEach { t in
                                t.privilege = re.privileges.first(where: {
                                    $0.id == t.id
                                })
                                t.from = (type, p.id, re.playlist.name)
                            }
                            return p
                           }
    }
 */
    
    func songUrl(_ ids: [Int], _ br: Int) -> Promise<([Song])> {
        struct Result: Decodable {
            let data: [Song]
            let code: Int
        }
        
        let p: [String : Any] = [
            "ids": ids,
            "br": br,
            "e_r": true
        ]
        
        return eapiRequest("https://music.163.com/eapi/song/enhance/player/url",
            p,
            Result.self,
            shouldDeSerial: true).map {
                $0.data
        }
    }
    
    func recommendResource() -> Promise<[RecommendResource.Playlist]> {
        eapiRequest(
            "https://music.163.com/eapi/v1/discovery/recommend/resource",
            [:],
            RecommendResource.self).map {
                $0.recommend
            }
    }
    
    func recommendSongs() -> Promise<[Track]> {
        eapiRequest(
            "https://music.163.com/eapi/v1/discovery/recommend/songs",
            [:],
            RecommendSongs.self).map {
                $0.recommend
            }.map {
                $0.forEach {
                    $0.from = (.discoverPlaylist, -114514, "recommend songs")
                }
                return $0
            }
    }
    
    func lyric(_ id: Int) -> Promise<(LyricResult)> {
        let u = "https://music.163.com/api/song/lyric?os=osx&id=\(id)&lv=-1&kv=-1&tv=-1"
        
        return Promise { resolver in
            AF.request(u).responseDecodable(of: LyricResult.self) {
                do {
                    resolver.fulfill(try $0.result.get())
                } catch let error {
                    resolver.reject(error)
                }
            }
        }
    }
    
    func searchSuggest(_ keywords: String) -> Promise<(SearchSuggest.Result)> {
        
        let p = [
            "s": keywords,
//            "limit": 6
        ]
        return eapiRequest("https://music.163.com/eapi/search/suggest/web",
            p,
            SearchSuggest.self).map {
                $0.result
        }
    }
    
    func search(_ keywords: String,
                limit: Int,
                page: Int,
                type: SearchResultViewController.ResultType) -> Promise<SearchResult.Result> {
        var p: [String: Any] = [
            "s": keywords,
            "limit": limit,
            "offset": page * limit,
            "total": true
        ]

        
        var u = "https://music.163.com/eapi/search/pc"
        
        // 1: 单曲, 10: 专辑, 100: 歌手, 1000: 歌单, 1002: 用户, 1004: MV, 1006: 歌词, 1009: 电台, 1014: 视频
        switch type {
        case .songs:
            p["type"] = 1
            u = "https://music.163.com/eapi/cloudsearch/pc"
        case .albums:
            p["type"] = 10
        case .artists:
            p["type"] = 100
        case .playlists:
            p["type"] = 1000
        default:
            p["type"] = 0
        }
        
        return eapiRequest(u,
                           p,
                           SearchResult.self).map {
                            $0.result.songs.forEach {
                                $0.from = (.searchResults, 0, "Search Result")
                            }
                            return $0.result
        }
    }
    
    func subscribe(_ id: Int, unsubscribe: Bool = false, type: TAAPItemsType) -> Promise<()> {
        
        var p = [String: Any]()
        var apiString = ""
        var subString = ""
        
        switch type {
        case .playlist:
            p["id"] = id
            apiString = "playlist"
            subString = unsubscribe ? "unsubscribe" : "subscribe"
        case .album:
            p["id"] = id
            apiString = "album"
            subString = unsubscribe ? "unsub" : "sub"
        case .artist:
            p = [
                "artistId": "\(id)",
                "artistIds": "[\(id)]"
            ]
            apiString = "artist"
            subString = unsubscribe ? "unsub" : "sub"
        default:
            return Promise { resolver in
                resolver.reject(RequestError.errorCode((0, "Unknow Type.")))
            }
        }
        
        let u = "https://music.163.com/eapi/\(apiString)/\(subString)"
        
        return eapiRequest(u,
            p,
            CodeResult.self).map {
                if $0.code == 200 {
                    return ()
                } else {
                    throw RequestError.errorCode(($0.code, $0.msg ?? ""))
                }
        }
    }

    func radioGet() -> Promise<[Track]> {
        struct Result: Decodable {
            let data: [Track]
            let code: Int
        }
        let u = "https://music.163.com/eapi/v1/radio/get"
        return eapiRequest(u,
                           [:],
                           Result.self).map {
                $0.data.forEach {
                    $0.from = (.fm, 0, "FM")
                }
                return $0.data
        }
    }
    
    func radioSkip(_ id: Int, _ time: Int = 0) -> Promise<()> {
        struct Result: Decodable {
            let code: Int
        }
        
        let p: [String: Any] = [
            "alg": "itembased",  //"alg_fm_rt_view_comment"
            "songId": id,
            "time": time
        ]

        let u = "https://music.163.com/eapi/v1/radio/skip"
        return eapiRequest(u,
            p,
            Result.self).map {
                if $0.code == 200 {
                    return ()
                } else {
                    throw RequestError.errorCode(($0.code, ""))
                }
        }
    }
    
    func album(_ id: Int) -> Promise<AlbumResult> {
        let u = "https://music.163.com/eapi/v1/album/\(id)"
        return eapiRequest(
            u,
            [:],
            AlbumResult.self).map { al in
                al.songs.forEach {
                    $0.from = (.album, id, al.album.name)
                    if $0.album.picUrl == nil {
                        $0.album.picUrl = al.album.picUrl
                    }
                }
                return al
            }
    }
    
    func albumSublist() -> Promise<[Track.Album]> {
        struct Result: Decodable {
            let code: Int
            let data: [Track.Album]
            let hasMore: Bool
        }
        
        let p: [String: Any] = [
            "limit": 1000,
            "offset": 0,
            "total": true
        ]
        return eapiRequest(
            "https://music.163.com/eapi/album/sublist",
            p,
            Result.self).map {
                $0.data
        }
    }
    
    func artistSublist() -> Promise<[Track.Artist]> {
        struct Result: Decodable {
            let code: Int
            let data: [Track.Artist]
            let hasMore: Bool
        }
        
        let p: [String: Any] = [
            "limit": 1000,
            "offset": 0,
            "total": true
        ]
        return eapiRequest(
            "https://music.163.com/eapi/artist/sublist",
            p,
            Result.self).map {
                $0.data.forEach {
                    $0.picUrl = $0.picUrl?.https
                }
                return $0.data
        }
    }
    

    func artist(_ id: Int) -> Promise<ArtistResult> {
        let p: [String: Any] = [
            "id": id,
            "ext": "true",
            "top": "50",
            "private_cloud": "true",
        ]
        return eapiRequest(
            "https://music.163.com/eapi/v1/artist/\(id)",
            p,
            ArtistResult.self)
    }
    
    func artistAlbums(_ id: Int) -> Promise<ArtistAlbumsResult> {
        let p: [String: Any] = [
            "limit": 1000,
            "offset": 0,
            "total": true
        ]
        
        return eapiRequest(
            "https://music.163.com/eapi/artist/albums/\(id)",
            p,
            ArtistAlbumsResult.self)
    }
    
    func like(_ id: Int, _ like: Bool = true, _ time: Int = 25) -> Promise<()> {
        struct Result: Decodable {
            let code: Int
            let playlistId: Int
        }
        
        let p: [String: Any] = [
            "time": time,
            "trackId": id,
            "alg": "itembased",
            "like": like,
        ]

        return eapiRequest(
            "https://music.163.com/eapi/radio/like",
            p,
            Result.self).map {
                if $0.code == 200 {
                    return ()
                } else {
                    throw RequestError.errorCode(($0.code, ""))
                }
        }
    }
    
    func likeList() -> Promise<[Int]> {
        struct Result: Decodable {
            let code: Int
            let ids: [Int]
        }
        let p = ["uid": uid]
        
        return eapiRequest(
            "https://music.163.com/eapi/song/like/get",
            p,
            Result.self).map {
                if $0.code == 200 {
                    return $0.ids
                } else {
                    throw RequestError.errorCode(($0.code, ""))
                }
        }
        
    }
    
    func fmTrash(id: Int, _ time: Int = 25, _ add: Bool = true) -> Promise<()> {
        struct Result: Decodable {
            let code: Int
        }
        
        var p = [String: Any]()
        if add {
            p = [
                "songId": id,
                "alg": "redRec",
                "time": time,
            ]
        } else {
            p = [
                "songIds": "[\(id)]",
            ]
        }
        
        let u = add ?
            "https://music.163.com/eapi/radio/trash/add" :
            "https://music.163.com/eapi/radio/trash/del/batch"
        
        return eapiRequest(
            u,
            p,
            Result.self).map {
                if $0.code == 200 {
                    return ()
                } else {
                    throw RequestError.errorCode(($0.code, ""))
                }
        }
    }
    
    func fmTrashList() -> Promise<([Track])> {
        struct Result: Decodable {
            let code: Int
            let data: [Track]
        }
        
        return eapiRequest(
            "https://music.163.com/eapi/v3/radio/trash/get",
            [:],
            Result.self).map {
            $0.data
        }
    }
    
    func playlistTracks(add: Bool, _ trackIds: [Int], to playlistId: Int) -> Promise<()> {
        let p: [String: Any] = [
            "op": add ? "add" : "del",
            "pid": playlistId,
            "trackIds": "\(trackIds)",
            "imme": true
        ]
        
        return eapiRequest(
            "https://music.163.com/eapi/v1/playlist/manipulate/tracks",
            p,
            CodeResult.self).map {
                if $0.code == 200 {
                    return ()
                } else {
                    throw RequestError.errorCode(($0.code, $0.msg ?? ""))
                }
        }
    }
    
    func playlistCreate(_ name: String, privacy: Bool = false) -> Promise<()> {
        let p: [String: Any] = [
            "name": name,
            "uid": uid,
            "privacy": privacy ? 10 : 0
        ]
        
        return eapiRequest(
            "https://music.163.com/eapi/playlist/create",
            p,
            CodeResult.self).map {
                if $0.code == 200 {
                    return ()
                } else {
                    throw RequestError.errorCode(($0.code, $0.msg ?? ""))
                }
            }
    }

    func discoveryRecommendDislike(_ id: Int, isPlaylist: Bool = false, alg: String = "") -> Promise<((Track?, RecommendResource.Playlist?))> {
        var p: [String: Any] = [
            "resId": id,
            "resType": isPlaylist ? 1 : 4, // daily 4  playlist 1
        ]
        
        p["sceneType"] = isPlaylist ? nil : 1 // daily 1  playlist nil
        p["alg"] = isPlaylist ? alg : nil // daily 1  playlist nil

        class Result: Decodable {
            let code: Int
            let track: Track?
            let playlist: RecommendResource.Playlist?
            
            enum CodingKeys: String, CodingKey {
                case code, data
            }
            
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.code = try container.decode(Int.self, forKey: .code)
                self.track = try? container.decodeIfPresent(Track.self, forKey: .data)
                self.playlist = try? container.decodeIfPresent(RecommendResource.Playlist.self, forKey: .data)
            }
        }
        
//        code == 432, msg == "今日暂无更多推荐"
        return eapiRequest(
            "https://music.163.com/eapi/discovery/recommend/dislike",
            p,
            Result.self).map {
                if $0.code == 200 {
                    return (($0.track, $0.playlist))
                } else {
                    throw RequestError.errorCode(($0.code, ""))
                }
            }
    }
    
    func playlistDelete(_ id: Int) -> Promise<()> {
        struct Result: Decodable {
            let code: Int
            let id: Int
        }
        let p = [
            "pid": id,
            "id": id
        ]
        
        return eapiRequest(
            "https://music.163.com/eapi/playlist/delete",
            p,
            Result.self).map {
                if $0.code == 200, $0.id == id {
                    return ()
                } else {
                    throw RequestError.errorCode(($0.code, ""))
                }
            }
    }
    
    func logout() -> Promise<()> {
        return eapiRequest(
            "https://music.163.com/eapi/logout",
            [:],
            CodeResult.self).map {
                if $0.code == 200 {
                    return ()
                } else {
                    throw RequestError.errorCode(($0.code, $0.msg ?? ""))
                }
            }
    }
    
    func songDetail(_ ids: [Int]) -> Promise<[Track]> {
        struct Result: Decodable {
            let songs: [Track]
            let code: Int
            let privileges: [Track.Privilege]
        }
        
        let c = "[" + ids.map({ "{\"id\":\"\($0)\", \"v\":\"\(0)\"}" }).joined(separator: ",") + "]"
        
        let p = [
            "c": c
        ]
        
        return eapiRequest(
            "https://music.163.com/eapi/v3/song/detail",
                   p,
                   Result.self).map {
                    guard $0.code == 200, $0.songs.count == $0.privileges.count else {
                        throw RequestError.errorCode(($0.code, ""))
                    }
                    
                    let re = $0.songs
                    let p = $0.privileges
                    re.enumerated().forEach {
                        guard $0.element.id == p[$0.offset].id else { return }
                        re[$0.offset].privilege = p[$0.offset]
                    }
                    return re
        }
    }
    
    /*
    func artistPrivilege(_ id: Int) -> Promise<[Track.Privilege]> {
        let u = "https://music.163.com/api/artist/privilege?top=50&id=\(id)"
        
        struct Result: Decodable {
            let data: [Track.Privilege]
            let code: Int
        }
        
        
        return request(u, nil, headers: nil, Result.self, method: .get).map {
            $0.data
        }
    }
     */
    
    /*
    private func request<T: Decodable>(
        _ url: String,
        _ parameters: String? = nil,
        headers: HTTPHeaders? = nil,
        _ resultType: T.Type,
        method: HTTPMethod = .post,
        pcOS: Bool = false,
        debug: Bool = false) -> Promise<T> {
        return Promise { resolver in
            let session = pcOS ? pcOSSession : defaultSession
            
            var req: DataRequest
                
            switch method {
            case .get:
                req = session.request(url, method: method, headers: headers)
            case .post where parameters != nil:
                req = session.request(url, method: method, parameters: crypto(parameters!), headers: headers)
            default:
                resolver.reject(RequestError.unknown)
                return
            }
                
            req.response { re in
                if debug, let d = re.data, let str = String(data: d, encoding: .utf8) {
                    print(str)
                }
                
                if let error = re.error {
                    resolver.reject(RequestError.error(error))
                    return
                }
                guard let data = re.data else {
                    resolver.reject(RequestError.noData)
                    return
                }
                
                do {
                    if let re = try? JSONDecoder().decode(ServerError.self, from: data),
                       re.code != 200 {
                        throw re
                    }
                    
                    let re = try JSONDecoder().decode(resultType.self, from: data)
                    
                    resolver.fulfill(re)
                } catch let error where error is ServerError {
                    guard let re = error as? ServerError else { return }

                    var msg = re.msg ?? re.message ?? ""
                    
                    if re.code == -462 {
                        msg = "绑定手机号或短信验证成功后，可进行下一步操作哦~🙃"
                    }
                    resolver.reject(RequestError.errorCode((re.code, msg)))
                } catch let error {
                    resolver.reject(error)
                }
            }
        }
    }
    */
    
    private func eapiRequest<T: Decodable>(
        _ url: String,
        _ params: [String: Any],
        _ resultType: T.Type,
        shouldDeSerial: Bool = false,
        debug: Bool = false) -> Promise<T> {
        

        
        return Promise { resolver in
            let p = try channel.serialData(params, url: url)
            
            nmSession.request(url, method: .post, parameters: ["params": p]).response { re in
                
                if debug, let d = re.data,
                    let str = String(data: d, encoding: .utf8) {
                    Log.verbose(str)
                }
                
                if let error = re.error {
                    resolver.reject(RequestError.error(error))
                    return
                }
                guard var data = re.data else {
                    resolver.reject(RequestError.noData)
                    return
                }
                
                do {
                    if shouldDeSerial {
                        if let d = try self.channel.deSerialData(data.toHexString(), split: false)?.data(using: .utf8) {
                            data = d
                        } else {
                            throw RequestError.noData
                        }
                    }
                    
                    if let re = try? JSONDecoder().decode(ServerError.self, from: data),
                       re.code != 200 {
                        throw re
                    }
                    
                    let re = try JSONDecoder().decode(resultType.self, from: data)
                    
                    resolver.fulfill(re)
                } catch let error where error is ServerError {
                    guard let err = error as? ServerError else { return }
                    
                    var msg = err.msg ?? err.message ?? ""
                    
                    if err.code == -462 {
                        msg = "绑定手机号或短信验证成功后，可进行下一步操作哦~🙃"
                    }
                    
                    let u = re.request?.url?.absoluteString ?? ""
                    resolver.reject(RequestError.errorCode((err.code, "\(u)  \(msg)")))
                } catch let error {
                    resolver.reject(error)
                }
            }
        }
    }
    
    enum RequestError: Error {
        case error(Error)
        case noData
        case errorCode((Int, String))
        case unknown
    }
    
    
    enum APIError: Error {
        case errorCode(Int)
    }
    
}

extension Encodable {
    func jsonString() -> String {
        guard let data = try? JSONEncoder().encode(self),
            let str = String(data: data, encoding: .utf8) else {
                return ""
        }
        return str
    }
}

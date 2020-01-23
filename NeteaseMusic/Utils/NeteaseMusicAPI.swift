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
import JavaScriptCore

class NeteaseMusicAPI: NSObject {
    
    lazy var pcOSSession: Session = {
        let session = Session(configuration: .ephemeral)
        let cookie = HTTPCookie(properties: [.domain : "music.163.com",
                                             .name: "os",
                                             .value: "pc",
                                             .path: "/"])!
        
        URLSessionConfiguration.default.httpCookieStorage?.cookies?.forEach {
            session.sessionConfiguration.httpCookieStorage?.setCookie($0)
        }
        session.sessionConfiguration.httpCookieStorage?.setCookie(cookie)
        session.sessionConfiguration.headers = HTTPHeaders.default
        session.sessionConfiguration.headers.update(name: "user-agent", value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15")
        return session
    }()
    
    lazy var defaultSession: Session = {
        let session = Session(configuration: .default)
        session.sessionConfiguration.httpCookieStorage?.cookies?.filter {
            $0.name == "os" && $0.value == "pc"
            }.forEach {
                session.sessionConfiguration.httpCookieStorage?.deleteCookie($0)
        }
        session.sessionConfiguration.headers = HTTPHeaders.default
        session.sessionConfiguration.headers.update(name: "user-agent", value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15")
        return session
    }()
    
    var uid = -1
    var csrf: String {
        get {
            return HTTPCookieStorage.shared.cookies?.filter({ $0.name == "__csrf" }).first?.value ?? ""
        }
    }
    
    lazy var cryptoJSContext: JSContext? = {
        guard let jsContext = JSContext(),
            let cryptoFilePath = Bundle.main.path(forResource: "Crypto", ofType: "js"),
            let content = try? String(contentsOfFile: cryptoFilePath) else {
                return nil
        }
        jsContext.evaluateScript(content)
        return jsContext
    }()
    
    
    struct DefaultParameters: Encodable {
        let csrfToken: String
        enum CodingKeys: String, CodingKey {
            case csrfToken = "csrf_token"
        }
    }
    
    struct User {
        var nickname: String
        var userId: Int
        var avatarImage: String?
    }
    
    struct CodeResult: Decodable {
        let code: Int
        let msg: String?
    }
    
    func isLogin() -> Promise<(Bool)> {
        return userInfo().map {
            $0.userId != -1
        }
    }
    
    
    func userInfo() -> Promise<(User)> {
        return Promise { resolver in
            AF.request("https://music.163.com").responseString {
                let gUserStr = $0.value?.subString(from: "var GUser={", to: "};").replacingOccurrences(of: "\"", with: "")
                
                var user = User(nickname: "", userId: -1, avatarImage: nil)
                gUserStr?.split(separator: ",").map(String.init).forEach {
                    let pars = $0.split(separator: ":", maxSplits: 1).map(String.init)
                    guard pars.count == 2, let key = pars.first else { return }
                    let value = pars[1]
                    switch key {
                    case "userId":
                        user.userId = Int(value) ?? -1
                        self.uid = user.userId
                    case "nickname":
                        user.nickname = value
                    case "avatarUrl":
                        let s = value.replacingOccurrences(of: "http://", with: "https://")
                        user.avatarImage = s
                    default:
                        break
                    }
                }
                resolver.fulfill(user)
            }
        }
    }
    
    func userPlaylist() -> Promise<[Playlist]> {
        struct P: Encodable {
            let uid: Int
            let limit: Int
            let offset: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case uid, limit, offset, csrfToken = "csrf_token"
            }
        }
        
        struct Result: Decodable {
            let playlist: [Playlist]
            let code: Int
        }
        
        let p = P(uid: uid, limit: 1000, offset: 0, csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/user/playlist?csrf_token=\(csrf)",
            p,
            Result.self).map {
                $0.playlist
        }
    }
    
    func playlistDetail(_ id: Int) -> Promise<(Playlist)> {
        struct P: Encodable {
            let id: Int
            let n: Int
            let s: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case id, n, s, csrfToken = "csrf_token"
            }
        }

        struct Result: Decodable {
            let playlist: Playlist
            let privileges: [Track.Privilege]
            let code: Int
        }

        let p = P(id: id, n: 1000, s: 0, csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/v3/playlist/detail",
            p,
            Result.self, pcOS: true).map { re -> Playlist in
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
    
    func songUrl(_ ids: [Int], _ br: Int) -> Promise<([Song])> {
        struct P: Encodable {
            let ids: [Int]
            let encodeType = "aac"
            let br: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case ids, br, encodeType, csrfToken = "csrf_token"
            }
        }
        
        let p = P(ids: ids, br: br, csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let data: [Song]
            let code: Int
        }
        
        return request("https://music.163.com/weapi/song/enhance/player/url",
            p,
            Result.self, pcOS: true).map {
                $0.data
        }
    }
    
    func recommendResource() -> Promise<[RecommendResource.Playlist]> {
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/v1/discovery/recommend/resource",
            p,
            RecommendResource.self).map {
                $0.recommend
        }
    }
    
    func recommendSongs() -> Promise<[Track]> {
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/v1/discovery/recommend/songs",
            p,
            RecommendSongs.self, pcOS: true).map {
                $0.recommend
        }.map {
            $0.forEach {
                $0.from = (.discoverPlaylist, -114514, "recommend songs")
            }
            return $0
        }
    }
    
    func lyric(_ id: Int) -> Promise<(LyricResult)> {
        struct P: Encodable {
            let id: Int
            let lv = -1
            let tv = -1
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case id, lv, tv, csrfToken = "csrf_token"
            }
        }
        let p = P(id: id, csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/song/lyric",
            p,
            LyricResult.self)
    }
    
    func searchSuggest(_ keywords: String) -> Promise<(SearchSuggest.Result)> {
        struct P: Encodable {
            let s: String
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case s, csrfToken = "csrf_token"
            }
        }
        
        let p = P(s: keywords, csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/search/suggest/web",
            p,
            SearchSuggest.self).map {
                $0.result
        }
    }
    
    func search(_ keywords: String,
                limit: Int,
                page: Int,
                type: SearchSuggestionsViewController.GroupType) -> Promise<SearchResult.Result> {
        struct P: Encodable {
            let s: String
            // 1: 单曲, 10: 专辑, 100: 歌手, 1000: 歌单, 1002: 用户, 1004: MV, 1006: 歌词, 1009: 电台, 1014: 视频
            let type: Int
            let limit: Int
            let offset: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case s, type, limit, offset, csrfToken = "csrf_token"
            }
        }
        
        var typeInt = 0
        switch type {
        case .songs:
            typeInt = 1
        case .albums:
            typeInt = 10
        case .artists:
            typeInt = 100
        case .playlists:
            typeInt = 1000
        default:
            typeInt = 0
        }
        
        let p = P(s: keywords, type: typeInt, limit: limit, offset: page * limit, csrfToken: csrf).jsonString()
        
        
        return request("https://music.163.com/weapi/cloudsearch/get/web",
                       p, SearchResult.self).map {
                        $0.result.songs.forEach {
                            $0.from = (.searchResults, 0, "Search Result")
                        }
                        return $0.result
        }
    }
    
    func subscribe(_ id: Int, unsubscribe: Bool = false, type: TAAPItemsType) -> Promise<()> {
        struct P1: Encodable {
            let id: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case id, csrfToken = "csrf_token"
            }
        }
        struct P2: Encodable {
            let artistId: String
            let artistIds: String
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case artistId, artistIds, csrfToken = "csrf_token"
            }
        }
        
        var p = ""
        var apiString = ""
        var subString = ""
        
        switch type {
        case .playlist:
            p = P1(id: id, csrfToken: csrf).jsonString()
            apiString = "playlist"
            subString = unsubscribe ? "unsubscribe" : "subscribe"
        case .album:
            p = P1(id: id, csrfToken: csrf).jsonString()
            apiString = "album"
            subString = unsubscribe ? "unsub" : "sub"
        case .artist:
            p = P2(artistId: "\(id)", artistIds: "[\(id)]", csrfToken: csrf).jsonString()
            apiString = "artist"
            subString = unsubscribe ? "unsub" : "sub"
        default:
            return Promise { resolver in
                resolver.reject(RequestError.errorCode((0, "Unknow Type.")))
            }
        }
        
        return request("https://music.163.com/weapi/\(apiString)/\(subString)",
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
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let data: [Track]
            let code: Int
        }
        
        return request("https://music.163.com/weapi/v1/radio/get",
            p,
            Result.self, pcOS: true).map {
                $0.data.forEach {
                    $0.from = (.fm, 0, "FM")
                }
                return $0.data
        }
    }
    
    func radioSkip(_ id: Int, _ time: Int = 0) -> Promise<()> {
        struct P: Encodable {
            let alg = "itembased" //"alg_fm_rt_view_comment"
            let songId: Int
            let time: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case alg, songId, time, csrfToken = "csrf_token"
            }
        }
        
        let p = P(songId: id, time: time, csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let code: Int
        }
        
        return request("https://music.163.com/weapi/v1/radio/skip",
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
        
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        return request("https://music.163.com/weapi/v1/album/\(id)",
            p,
            AlbumResult.self, pcOS: true).map { al in
                al.songs.forEach {
                    $0.from = (.album, id, al.album.name)
                }
                return al
        }
    }
    
    func albumSublist() -> Promise<[Track.Album]> {
        struct P: Encodable {
            let limit = 1000
            let offset = 0
            let total = true
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case limit, offset, total, csrfToken = "csrf_token"
            }
        }
        
        struct Result: Decodable {
            let code: Int
            let data: [Track.Album]
            let hasMore: Bool
        }
        
        let p = P(csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/album/sublist",
            p,
            Result.self).map {
                $0.data
        }
    }
    
    func artistSublist() -> Promise<[Track.Artist]> {
        struct P: Encodable {
            let limit = 1000
            let offset = 0
            let total = true
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case limit, offset, total, csrfToken = "csrf_token"
            }
        }
        
        struct Result: Decodable {
            let code: Int
            let data: [Track.Artist]
            let hasMore: Bool
        }
        
        let p = P(csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/artist/sublist",
            p,
            Result.self).map {
                $0.data
        }
    }
    

    func artist(_ id: Int) -> Promise<ArtistResult> {
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        return request("https://music.163.com/weapi/artist/\(id)",
            p,
            ArtistResult.self)
    }
    
    func artistAlbums(_ id: Int) -> Promise<ArtistAlbumsResult> {
        struct P: Encodable {
            let limit: Int = 1000
            let offset: Int = 0
            let total: Bool = true
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case total, limit, offset, csrfToken = "csrf_token"
            }
        }
        
        let p = P(csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/artist/albums/\(id)",
            p,
            ArtistAlbumsResult.self)
    }
    
    func like(_ id: Int, _ like: Bool = true, _ time: Int = 25) -> Promise<()> {
        struct P: Encodable {
            let trackId: Int
            let like: String
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case trackId, like, csrfToken = "csrf_token"
            }
        }
        let p = P(trackId: id, like: "\(like)", csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let code: Int
            let playlistId: Int
        }

        return request("https://music.163.com/weapi/radio/like?alg=itembased&trackId=\(id)&time=\(time)",
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
        struct P: Encodable {
            let uid: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case uid, csrfToken = "csrf_token"
            }
        }
        
        let p = P(uid: uid, csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let code: Int
            let ids: [Int]
        }
        
        return request("https://music.163.com/weapi/song/like/get",
            p,
            Result.self, debug: true).map {
                if $0.code == 200 {
                    return $0.ids
                } else {
                    throw RequestError.errorCode(($0.code, ""))
                }
        }
        
    }
    
    func fmTrash(id: Int, _ time: Int = 25, _ add: Bool = true) -> Promise<()> {
        struct P: Encodable {
            let songId: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case songId, csrfToken = "csrf_token"
            }
        }
        let p = P(songId: id, csrfToken: csrf).jsonString()

        struct Result: Decodable {
            let code: Int
        }
        let u = add ? "https://music.163.com/weapi/radio/trash/add?alg=RT&songId=\(id)&time=\(time)" : "https://music.163.com/weapi/radio/trash/del"
        
        return request(u,
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

//https://music.163.com/api/v3/radio/trash/get?pagesize=100&from=1&to=1&offset=0&total=true&limit=100&currsize=26&addTime=1491740318242
        return Promise { resolver in
            AF.request("https://music.163.com/api/v3/radio/trash/get?pagesize=1000&from=1&to=1&offset=0&total=true&limit=1000", method: .get).response { re in
                if let error = re.error {
                    resolver.reject(RequestError.error(error))
                    return
                }
                guard let data = re.data else {
                    resolver.reject(RequestError.noData)
                    return
                }
                
                do {
                    let re = try JSONDecoder().decode(Result.self, from: data)
                    resolver.fulfill(re.data)
                } catch let error {
                    if let re = try? JSONDecoder().decode(ServerError.self, from: data), re.code != 200 {
                        resolver.reject(RequestError.errorCode((re.code, re.msg ?? re.message ?? "")))
                    } else {
                        resolver.reject(RequestError.error(error))
                    }
                }
            }
        }
    }
    
    func playlistTracks(add: Bool, _ trackIds: [Int], to playlistId: Int) -> Promise<()> {
        struct P: Encodable {
            let op: String  // del,add
            let pid: Int
            let trackIds: String
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case op, pid, trackIds, csrfToken = "csrf_token"
            }
        }
        
        let p = P(op: add ? "add" : "del", pid: playlistId, trackIds: "\(trackIds)", csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/playlist/manipulate/tracks",
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
        struct P: Encodable {
            let name: String
            let privacy: Int  // privacy 10
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case name, privacy, csrfToken = "csrf_token"
            }
        }

        let p = P(name: name, privacy: privacy ? 10 : 0, csrfToken: csrf).jsonString()
        
        return request("https://music.163.com/weapi/playlist/create",
                       p,
                       CodeResult.self, pcOS: true).map {
                        if $0.code == 200 {
                            return ()
                        } else {
                            throw RequestError.errorCode(($0.code, $0.msg ?? ""))
                        }
        }
    }

    func discoveryRecommendDislike(_ id: Int, isPlaylist: Bool = false, alg: String = "") -> Promise<((Track?, RecommendResource.Playlist?))> {
        struct P: Encodable {
            let resId: Int
            let resType: Int  // daily 4  playlist 1
            let sceneType: Int?  // daily 1  playlist nil
            let alg: String?  // daily nil
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case resId, resType, sceneType, alg, csrfToken = "csrf_token"
            }
        }

        let p = P(resId: id,
                  resType: isPlaylist ? 1 : 4,
                  sceneType: isPlaylist ? nil : 1,
                  alg: isPlaylist ? alg : nil,
                  csrfToken: csrf).jsonString()

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
        return request("https://music.163.com/weapi/v2/discovery/recommend/dislike",
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
        struct P: Encodable {
            let pid: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case pid, csrfToken = "csrf_token"
            }
        }
        
        let p = P(pid: id, csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let code: Int
            let id: Int
        }
        
        return request("https://music.163.com/weapi/playlist/delete",
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
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        return request("https://music.163.com/weapi/logout",
                       p,
                       CodeResult.self).map {
                        if $0.code == 200 {
                            return ()
                        } else {
                            throw RequestError.errorCode(($0.code, $0.msg ?? ""))
                        }
        }
    }
    
    func songDetail(_ ids: [Int]) -> Promise<[Track]> {
        struct P: Encodable {
            let ids: String
            let c: String
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case ids, c, csrfToken = "csrf_token"
            }
        }
        let c = "[" + ids.map({ "{\"id\":\"\($0)\"}" }).joined(separator: ",") + "]"
        let idsStr = "[" + ids.map(String.init).joined(separator: ",") + "]"
        
        let p = P(ids: idsStr, c: c, csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let songs: [Track]
            let code: Int
        }
        
        // Can't get album picUrl if cookies contains pc=os.
        return request("https://music.163.com/weapi/v3/song/detail",
                   p,
                   Result.self).map {
                    if $0.code == 200 {
                        return ($0.songs)
                    } else {
                        throw RequestError.errorCode(($0.code, ""))
                    }
        }
    }
    
    private func request<T: Decodable>(_ url: String, _ parameters: String, headers: HTTPHeaders? = nil, _ resultType: T.Type, pcOS: Bool = false, debug: Bool = false) -> Promise<T> {
        return Promise { resolver in
            let session = pcOS ? pcOSSession : defaultSession
            session.request(url, method: .post,
                       parameters: crypto(parameters),
                       headers: headers).response { re in
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
                            let re = try JSONDecoder().decode(resultType.self, from: data)
                            resolver.fulfill(re)
                        } catch let error {
                            if let re = try? JSONDecoder().decode(ServerError.self, from: data), re.code != 200 {
                                resolver.reject(RequestError.errorCode((re.code, re.msg ?? re.message ?? "")))
                            } else {
                                resolver.reject(RequestError.error(error))
                            }
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
    
    
    private func crypto(_ text: String, _ useJSCore: Bool = false) -> [String: String] {
        if useJSCore {
            guard let data = cryptoJSContext?.evaluateScript("p('\(text)')")?.toString().data(using: .utf8),
                var json = try? JSONDecoder().decode([String: String].self, from: data) else {
                    return [:]
            }
            json["params"] = json["encText"]
            json["encText"] = nil
            return json
        } else {
            return Crypto.paramsEncrypt(text)
        }
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

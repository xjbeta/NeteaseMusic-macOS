//
//  NeteaseMusicAPI.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/31.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import Alamofire
import Marshal
import PromiseKit
import JavaScriptCore

class NeteaseMusicAPI: NSObject {
    
    var uid = -1
    var csrf: String {
        get {
            return HTTPCookieStorage.shared.cookies?.filter({ $0.name == "__csrf" }).first?.value ?? ""
        }
    }
    
    struct DefaultParameters: Encodable {
        let csrfToken: String
        enum CodingKeys: String, CodingKey {
            case csrfToken = "csrf_token"
        }
    }
    
    struct User {
        var nickname: String
        var userId: Int
        var avatarImage: NSImage?
    }
    
    struct CodeResult: Decodable {
        let code: Int
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
                        if let u = URL(string: s) {
                            user.avatarImage = NSImage(contentsOf: u)
                        }
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
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/user/playlist?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<Result>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(result.playlist)
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
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
            let code: Int
        }

        let p = P(id: id, n: 1000, s: 0, csrfToken: csrf).jsonString()
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/v3/playlist/detail?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<Result>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(result.playlist)
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
        }
    }
    
    func songUrl(_ ids: [Int]) -> Promise<([Song])> {
        struct P: Encodable {
            let ids: [Int]
            let br = 9990000
//            let level = "standard";
//            let encodeType = "aac";
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
//                case ids, level, encodeType, csrfToken = "csrf_token"
                case ids, br, csrfToken = "csrf_token"
            }
        }
        
        let p = P(ids: ids, csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let data: [Song]
            let code: Int
        }
        //        https://music.163.com/weapi/song/enhance/player/url/v1?csrf_token=
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/song/enhance/player/url?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<Result>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(result.data)
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
        }
    }
    
    func recommendResource() -> Promise<[RecommendResource.Playlist]> {
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/v1/discovery/recommend/resource?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<RecommendResource>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(result.recommend)
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
        }
    }
    
    func recommendSongs() -> Promise<[Track]> {
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/v1/discovery/recommend/songs?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<RecommendSongs>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(result.recommend)
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
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
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/song/lyric?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<LyricResult>) in
                if let error = re.error {
                    resolver.reject(error)
                    return
                }
                do {
                    let result = try re.result.get()
                    if result.code == 200 {
                        resolver.fulfill(result)
                    } else {
                        resolver.reject(APIError.errorCode(result.code))
                    }
                } catch let error {
                    resolver.reject(error)
                }
            }   
        }
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
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/search/suggest/web?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<SearchSuggest>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(result.result)
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
        }
    }
    
    func playlistSubscribe(_ id: Int, unSubscribe: Bool = false) -> Promise<()> {
        struct P: Encodable {
            let id: Int
            let csrfToken: String
            enum CodingKeys: String, CodingKey {
                case id, csrfToken = "csrf_token"
            }
        }
        let p = P(id: id, csrfToken: csrf).jsonString()
        let apiStr = unSubscribe ? "unsubscribe" : "subscribe"
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/playlist/\(apiStr)?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<CodeResult>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(())
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
        }
    }
    
    func radioGet() -> Promise<[Track]> {
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        
        struct Result: Decodable {
            let data: [Track]
            let code: Int
        }
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/v1/radio/get?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<Result>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(result.data)
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
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
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/v1/radio/skip?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<Result>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(())
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
        }
    }
    
    func album(_ id: Int) -> Promise<[Track]> {
        struct Result: Decodable {
            let songs: [Track]
            let code: Int
        }
        
        let p = DefaultParameters(csrfToken: csrf).jsonString()
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/v1/album/\(id)?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(p)).responseDecodable { (re: DataResponse<Result>) in
                    if let error = re.error {
                        resolver.reject(error)
                        return
                    }
                    do {
                        let result = try re.result.get()
                        if result.code == 200 {
                            resolver.fulfill(result.songs)
                        } else {
                            resolver.reject(APIError.errorCode(result.code))
                        }
                    } catch let error {
                        resolver.reject(error)
                    }
            }
        }
    }
    
    func crypto(_ text: String) -> [String: String] {
        guard let jsContext = JSContext(),
            let cryptoFilePath = Bundle.main.path(forResource: "Crypto", ofType: "js"),
            let content = try? String(contentsOfFile: cryptoFilePath) else {
                return [:]
        }
        jsContext.evaluateScript(content)
        guard let data = jsContext.evaluateScript("p('\(text)')")?.toString().data(using: .utf8),
            var json = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
        }
        json["params"] = json["encText"]
        json["encText"] = nil
        return json
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

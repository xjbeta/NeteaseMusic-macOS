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
    
    struct User {
        var nickname: String
        var userId: Int
        var avatarImage: NSImage?
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
    
    struct PlayList: Decodable {
        let subscribed: Bool
        let coverImgUrl: URL
        let playCount: Int
        let name: String
        let trackCount: Int
        let description: String?
        let tags: [String]
    }
    
    func userPlaylist() -> Promise<[PlayList]> {
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
            let playlist: [PlayList]
            let code: Int
        }
        
        let t = P(uid: uid, limit: 1000, offset: 0, csrfToken: csrf).jsonString()
        
        return Promise { resolver in
            AF.request("https://music.163.com/weapi/user/playlist?csrf_token=\(csrf)",
                method: .post,
                parameters: crypto(t)).responseDecodable { (re: DataResponse<Result>) in
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

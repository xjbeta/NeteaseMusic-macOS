//
//  NMChannel.swift
//  NeteaseMusic
//
//  Created by xjbeta on 8/15/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Foundation
import CryptoSwift

class NMChannel: NSObject {
    private let EAPI_AES_KEY = "e82ckenh8dichen8"

    let deviceId = "\(UUID().uuidString)|\(UUID().uuidString)"
    let deviceIdS = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    
    func serialData<T: Encodable>(_ params: T, url: String) throws -> String {
        let key = "36cd479b6b5"
        let u = url.replacingOccurrences(of: "https://music.163.com/eapi", with: "/api")
        
        let pJSON = eapiParams(params).jsonString()
        let str = [u,
                   key,
                   pJSON,
                   key,
                   "nobody\(u)use\(pJSON)md5forencrypt".md5()].joined(separator: "-")
        
        let aes = try AES(key: EAPI_AES_KEY.bytes, blockMode: ECB())

        return try str.encrypt(cipher: aes)
    }
    
    func deSerialData(_ params: String) throws -> String? {
        let aes = try AES(key: EAPI_AES_KEY.bytes, blockMode: ECB())
        let re = try Data(hex: params).decrypt(cipher: aes)
        guard let l = String(data: re, encoding: .utf8)?.components(separatedBy: "-36cd479b6b5-"),
              l.count == 3 else {
            print("DeSerialData failed.", String(data: re, encoding: .utf8) ?? "")
            return nil
        }
        return l[1]
    }
    
    private func eapiParams<T: Encodable>(_ params: T) -> NMParamsCombiner<T> {
        let header = NMEapiHeader(
            deviceId: deviceId,
            requestId: "\(randomInt(8))")
            .jsonString()
        let eParams = NMEapiParams(
            header: header,
            deviceId: deviceIdS)
        
        return NMParamsCombiner(eParams: eParams, params: params)
    }
    
    private func randomInt(_ digits: Int) -> Int {
        let min = Int(pow(10, Double(digits-1))) - 1
        let max = Int(pow(10, Double(digits))) - 1
        return Int.random(in: (min...max))
    }
    
    
}

//
//  Crypto.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/15.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import CryptoSwift

class Crypto: NSObject {
    static let base62 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    static let presetKey = "0CoJUm6Qyw8W8jud"
    static let iv = "0102030405060708"
    static let linuxapiKey = "rFgB&h#%2?^eDg:Q"
    static let publicKey = "-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgtQn2JZ34ZC28NWYpAUd98iZ37BUrX/aKzmFbt7clFSs6sXqHauqKWqdtLkF2KexO40H1YTX8z2lSgBBOAxLsvaklV8k4cBFK9snQXE9/DDaFt6Rr7iVZMldczhC0JNgTz+SHXT6CBHuX3e9SdB1Ua44oncaTWz7OBGLbCiK45wIDAQAB\n-----END PUBLIC KEY-----"
    static let eapiKey = "e82ckenh8dichen8"
    
    
    
    static func rsaEncrypt(_ data: Data, with publicKey: String) -> String? {
        let publicKey = publicKey
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        var error: Unmanaged<CFError>? = nil
        guard let keyData = Data(base64Encoded: publicKey) else {
            Log.error("KeyDataEncodeFailure")
            return nil
        }
        guard let key = SecKeyCreateWithData(keyData as CFData, [
            kSecAttrType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: (keyData.count * 8) as NSNumber,
            ] as CFDictionary, &error) else {
                Log.error("publicKeySecKeyGenerationFailure \(String(describing: error))")
                return nil
        }
        
        guard let d = SecKeyCreateEncryptedData(
            key, .rsaEncryptionRaw, data as CFData, &error) else {
                Log.error("rsaEncryptFailure \(String(describing: error))")
                return nil
        }
        return (d as Data).hexDescription
    }
    
    
    
    static func paramsEncrypt(_ text: String) -> [String: String] {
//        https://github.com/Binaryify/NeteaseCloudMusicApi/blob/master/util/crypto.js
        
        var secretKey = ""
        while secretKey.count < 16 {
            secretKey.append(base62.randomElement()!)
        }
        
        var p: [String: String] = [String: String]()
        do {
            // params
            // aesEncrypt(Buffer.from(aesEncrypt(Buffer.from(text), 'cbc', presetKey, iv).toString('base64')), 'cbc', secretKey, iv).toString('base64'),
            
            let encrypt1 = try AES(key: presetKey, iv: iv, padding: .pkcs7).encrypt(Array(text.utf8)).toBase64()
            
            let encrypt2 = try AES(key: secretKey, iv: iv, padding: .pkcs7).encrypt(Array(encrypt1.utf8)).toBase64()
            p["params"] = encrypt2
            
            // encSecKey
            // buffer = Buffer.concat([Buffer.alloc(128 - buffer.length), buffer])
            var k = secretKey.data(using: .utf8)!
            k.reverse()
            var kk = Data(count: 128 - k.count)
            kk.append(k)
            
            // rsaEncrypt(secretKey.reverse(), publicKey).toString('hex')
            p["encSecKey"] = rsaEncrypt(kk, with: publicKey)
            return p
        } catch let error {
            Log.error(error)
            return [:]
        }
    }
}

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

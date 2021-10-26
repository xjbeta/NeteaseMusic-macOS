//
//  NMChannelTests.swift
//  NMChannelTests
//
//  Created by xjbeta on 8/17/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import XCTest
import CryptoSwift

class NMChannelTests: XCTestCase {
    
    let params = ""

    let EAPI_AES_KEY = "e82ckenh8dichen8"


    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let aes = try AES(key: EAPI_AES_KEY.bytes, blockMode: ECB())
        let data = try Data(hex: params).decrypt(cipher: aes)
        let rawStr = String(data: data, encoding: .utf8)
        
        print(rawStr)
        
        let list = rawStr!.components(separatedBy: "-36cd479b6b5-")

        
        var str = list[1]
        
        if let start = str.lastIndex(of: "{"),
           let end = str.firstIndex(of: "}") {
            str.removeSubrange(start...end)
        }
        str = String(str.dropFirst())
        str = String(str.dropLast())
        
        let ignoreList = ["deviceId", "os", "header", "verifyId"]
        
        print(str)
        
        
        let re = str.split(separator: ",").compactMap { str -> (String, String)? in
            let kv = str.split(separator: ":").map(String.init)
            guard kv.count == 2 else {
                return nil
            }
            
            let key = String(kv[0].dropFirst().dropLast())
            return ignoreList.contains(key) ? nil : (kv[0], kv[1])
        }
        
        print("[")
        re.forEach {
            print("\t\($0.0): \($0.1),")
        }
        print("]")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

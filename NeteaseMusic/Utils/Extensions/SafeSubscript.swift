//
//  SafeSubscript.swift
//  Aria2D
//
//  Created by xjbeta on 2017/2/3.
//  Copyright © 2017年 xjbeta. All rights reserved.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


extension Array where Element: Track {
    func randomItem() -> Element? {
        guard self.count > 0 else { return nil }
        let randomIndex = Int.random(in: 0..<self.count)
        return self[safe: randomIndex]
    }
}

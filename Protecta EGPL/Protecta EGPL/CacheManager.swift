//
//  CacheManager.swift
//  Protecta EGPL
//
//  Created by avinash pandey on 21/03/26.
//

import Foundation

class CacheManager {

    static func setup() {
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "webCache"
        )
    }
}

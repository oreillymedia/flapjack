//
//  Dictionary+ExtensionsTests.swift
//  Flapjack
//
//  Created by Ben Kreeger on 9/12/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import Flapjack

class DictionaryExtensionsTests: XCTestCase {
    func testCacheKeyGeneration() {
        // Sorts keys and then spits out a key
        let source: [String:Any] = ["this": "should", "produce": true, "aCacheKey": 42]
        XCTAssertEqual(source.cacheKey, "aCacheKey.42-produce.true-this.should")

        let empty = [String:Any]()
        XCTAssertEqual(empty.cacheKey, "")
    }
}

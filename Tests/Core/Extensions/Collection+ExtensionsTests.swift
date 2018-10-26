//
//  Collection+ExtensionsTests.swift
//  Flapjack
//
//  Created by Ben Kreeger on 9/12/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import Flapjack

class CollectionExtensionsTests: XCTestCase {
    func testSafeSubscripting() {
        var mutableArray: [String] = []
        XCTAssertNil(mutableArray[safe: 0])

        mutableArray.append("abc")
        XCTAssertEqual(mutableArray[safe: 0], "abc")
    }
}

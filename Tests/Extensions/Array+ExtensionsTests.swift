//
//  Array+ExtensionsTests.swift
//  Flapjack
//
//  Created by Ben Kreeger on 9/12/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest

class ArrayExtensionsTests: XCTestCase {
    func testIndexOfObjectWithIdentityMatch() {
        // WITHOUT using pointer comparison, we settle for equality using index(of:)
        let toFind2 = MockEquatable(string: "peach")
        let array2 = [MockEquatable(string: "raspberry"), MockEquatable(string: "peach"), toFind2]
        XCTAssertEqual(array2.index(of: toFind2, pointerComparison: false), 1)
        XCTAssertEqual(array2.index(of: toFind2), 1)

        // But again, pointer comparison gets us true object identity
        XCTAssertEqual(array2.index(of: toFind2, pointerComparison: true), 2)
    }
}


fileprivate class MockEquatable: NSObject {
    let string: String

    init(string: String) {
        self.string = string
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? MockEquatable else { return false }
        return object.string == self.string
    }
}

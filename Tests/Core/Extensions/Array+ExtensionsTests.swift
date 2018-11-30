//
//  Array+ExtensionsTests.swift
//  Flapjack
//
//  Created by Ben Kreeger on 9/12/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import Flapjack

class ArrayExtensionsTests: XCTestCase {
    func testIndexOfObjectWithIdentityMatch() {
        // WITHOUT using pointer comparison, we settle for equality using index(of:)
        let toFind2 = MockEquatable("peach")
        let array2 = [MockEquatable("raspberry"), MockEquatable("peach"), toFind2]
        XCTAssertEqual(array2.index(of: toFind2, pointerComparison: false), 1)
        XCTAssertEqual(array2.index(of: toFind2), 1)

        // But again, pointer comparison gets us true object identity
        XCTAssertEqual(array2.index(of: toFind2, pointerComparison: true), 2)
    }

    func testSortedUsingDescriptors() {
        let testArray = [MockEquatable("s"), MockEquatable("z"), MockEquatable("y"), MockEquatable("a"), MockEquatable("b")]
        let expected = [MockEquatable("a"), MockEquatable("b"), MockEquatable("s"), MockEquatable("y"), MockEquatable("z")]
        XCTAssertEqual(testArray.sorted(using: [SortDescriptor("string")]), expected)

        let expected2 = Array(expected.reversed())
        XCTAssertEqual(testArray.sorted(using: [SortDescriptor("string", ascending: false)]), expected2)
    }
}


private class MockEquatable: NSObject {
    // To be key-value compliant.
    @objc let string: String

    init(_ string: String) {
        self.string = string
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? MockEquatable else {
            return false
        }
        return object.string == self.string
    }
}

//
//  NSCompoundPredicate+ExtensionsTests.swift
//  Flapjack
//
//  Created by Ben Kreeger on 9/12/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import Flapjack

class NSCompoundPredicateExtensionsTests: XCTestCase {
    func testKeyValueInitializerWithCVarArgTypes() {
        XCTAssertEqual(NSPredicate(key: "keypath", value: "bob").predicateFormat, "keypath == \"bob\"")
        XCTAssertEqual(NSPredicate(key: "self", value: "bob").predicateFormat, "SELF == \"bob\"")
        XCTAssertEqual(NSPredicate(key: "keypath", value: 3).predicateFormat, "keypath == 3")
    }

    func testKeyValueInitializerWithArrays() {
        XCTAssertEqual(NSPredicate(key: "keypath", value: ["bob", "ed"]).predicateFormat, "keypath IN {\"bob\", \"ed\"}")
    }

    func testKeyValueInitializerWithSets() {
        let format = NSPredicate(key: "keypath", value: Set<String>(["bob", "ed"])).predicateFormat
        let oneWay = format == "keypath IN {\"bob\", \"ed\"}"
        let another = format == "keypath IN {\"ed\", \"bob\"}"
        XCTAssertTrue(oneWay || another)
    }

    func testKeyValueInitializerWithRanges() {
        XCTAssertEqual(NSPredicate(key: "keypath", value: 1..<2).predicateFormat, "keypath >= 1 AND keypath < 2")
        XCTAssertEqual(NSPredicate(key: "keypath", value: 1...2).predicateFormat, "keypath >= 1 AND keypath <= 2")
    }

    func testInitializeFromConditions() {
        let predicates = NSPredicate.fromConditions(["one": "two", "three": 4])
        XCTAssertTrue(predicates.contains { $0.predicateFormat == "one == \"two\"" })
        XCTAssertTrue(predicates.contains { $0.predicateFormat == "three == 4" })
    }

    func testInitializeFromNull() {
        XCTAssertEqual(NSPredicate(key: "keypath", value: nil).predicateFormat, "keypath == nil")
        XCTAssertEqual(NSPredicate(key: "self", value: nil).predicateFormat, "SELF == nil")
    }
}

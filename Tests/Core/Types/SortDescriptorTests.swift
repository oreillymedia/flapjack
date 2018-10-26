//
//  SortDescriptorTests.swift
//  Flapjack-Unit-Tests
//
//  Created by Ben Kreeger on 10/26/18.
//

import Foundation
import XCTest
@testable import Flapjack

class SortDescriptorTests: XCTestCase {
    func testInitializeWithKeypath() {
        let initialized = SortDescriptor("abc123")
        XCTAssertEqual(initialized.keyPath, "abc123")
        XCTAssertTrue(initialized.ascending)
        XCTAssertFalse(initialized.caseInsensitive)
        XCTAssertEqual(initialized.asNSSortDescriptor, NSSortDescriptor(key: "abc123", ascending: true, selector: nil))
        XCTAssertEqual(initialized.cacheKey, "abc123.1.0")
    }

    func testInitializeWithKeypathAndAscending() {
        let initialized = SortDescriptor("abc123", ascending: false)
        XCTAssertEqual(initialized.keyPath, "abc123")
        XCTAssertFalse(initialized.ascending)
        XCTAssertFalse(initialized.caseInsensitive)
        XCTAssertEqual(initialized.asNSSortDescriptor, NSSortDescriptor(key: "abc123", ascending: false, selector: nil))
        XCTAssertEqual(initialized.cacheKey, "abc123.0.0")
    }

    func testInitializeWithKeypathAndAscendingAndCaseInsensitivity() {
        let initialized = SortDescriptor("abc123", ascending: false, caseInsensitive: true)
        XCTAssertEqual(initialized.keyPath, "abc123")
        XCTAssertFalse(initialized.ascending)
        XCTAssertTrue(initialized.caseInsensitive)
        XCTAssertEqual(initialized.asNSSortDescriptor, NSSortDescriptor(key: "abc123", ascending: false, selector: #selector(NSString.caseInsensitiveCompare(_:))))
        XCTAssertEqual(initialized.cacheKey, "abc123.0.1")
    }
}

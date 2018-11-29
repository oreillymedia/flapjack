//
//  NSFetchedResultsChangeTypeExtensionsTests.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 10/26/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest
import CoreData

@testable import Flapjack
@testable import FlapjackCoreData

class NSFetchedResultsChangeTypeExtensionsTests: XCTestCase {
    func testDescription() {
        XCTAssertEqual(NSFetchedResultsChangeType.delete.description, "delete")
        XCTAssertEqual(NSFetchedResultsChangeType.insert.description, "insert")
        XCTAssertEqual(NSFetchedResultsChangeType.update.description, "update")
        XCTAssertEqual(NSFetchedResultsChangeType.move.description, "move")
    }

    func testAsDataSourceSectionChange() {
        XCTAssertNil(NSFetchedResultsChangeType.update.asDataSourceSectionChange(section: 0))
        XCTAssertNil(NSFetchedResultsChangeType.move.asDataSourceSectionChange(section: 0))
        XCTAssertEqual(NSFetchedResultsChangeType.insert.asDataSourceSectionChange(section: 0), .insert(section: 0))
        XCTAssertEqual(NSFetchedResultsChangeType.delete.asDataSourceSectionChange(section: 0), .delete(section: 0))
    }

    func testAsDataSourceChangeAtNewPathForInsert() {
        let indexPath = IndexPath(item: 0, section: 0)
        let newPath = IndexPath(item: 1, section: 0)
        XCTAssertNil(NSFetchedResultsChangeType.insert.asDataSourceChange(at: nil, newPath: nil))
        XCTAssertNil(NSFetchedResultsChangeType.insert.asDataSourceChange(at: indexPath, newPath: nil))
        XCTAssertEqual(NSFetchedResultsChangeType.insert.asDataSourceChange(at: nil, newPath: newPath), .insert(path: newPath))
        XCTAssertEqual(NSFetchedResultsChangeType.insert.asDataSourceChange(at: indexPath, newPath: newPath), .insert(path: newPath))
    }

    func testAsDataSourceChangeAtNewPathForDelete() {
        let indexPath = IndexPath(item: 0, section: 0)
        XCTAssertNil(NSFetchedResultsChangeType.delete.asDataSourceChange(at: nil, newPath: indexPath))
        XCTAssertEqual(NSFetchedResultsChangeType.delete.asDataSourceChange(at: indexPath, newPath: nil), .delete(path: indexPath))
    }

    func testAsDataSourceChangeAtNewPathForMove() {
        let indexPath = IndexPath(item: 0, section: 0)
        let newPath = IndexPath(item: 1, section: 0)
        XCTAssertNil(NSFetchedResultsChangeType.move.asDataSourceChange(at: nil, newPath: nil))
        XCTAssertNil(NSFetchedResultsChangeType.move.asDataSourceChange(at: nil, newPath: indexPath))
        XCTAssertNil(NSFetchedResultsChangeType.move.asDataSourceChange(at: indexPath, newPath: nil))
        XCTAssertEqual(NSFetchedResultsChangeType.move.asDataSourceChange(at: indexPath, newPath: newPath), .move(from: indexPath, toPath: newPath))
        XCTAssertEqual(NSFetchedResultsChangeType.move.asDataSourceChange(at: indexPath, newPath: indexPath), .update(path: indexPath))
    }

    func testAsDataSourceChangeAtNewPathForUpdate() {
        let indexPath = IndexPath(item: 0, section: 0)
        XCTAssertNil(NSFetchedResultsChangeType.update.asDataSourceChange(at: nil, newPath: indexPath))
        XCTAssertEqual(NSFetchedResultsChangeType.update.asDataSourceChange(at: indexPath, newPath: nil), .update(path: indexPath))
    }
}

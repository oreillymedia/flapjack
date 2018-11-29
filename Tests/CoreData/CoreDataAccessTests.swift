//
//  CoreDataAccessTests.swift
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

class CoreDataAccessStoreTypeTests: XCTestCase {
    func testStoreTypeSQL() {
        let storeType = CoreDataAccess.StoreType.sql(filename: "abc123.sqlite")
        guard let url = storeType.url else {
            XCTFail("Expected storeType.url.")
            return
        }
        XCTAssertTrue(url.absoluteString.hasSuffix("/data/Library/Application%20Support/abc123.sqlite"))
        XCTAssertEqual(storeType.coreDataType, NSSQLiteStoreType)
        XCTAssertEqual(storeType.storeDescription.type, NSSQLiteStoreType)
    }

    func testStoreTypeMemory() {
        let storeType = CoreDataAccess.StoreType.memory
        XCTAssertNil(storeType.url)
        XCTAssertEqual(storeType.coreDataType, NSInMemoryStoreType)
        XCTAssertEqual(storeType.storeDescription.type, NSInMemoryStoreType)
    }
}


class CoreDataAccessTests: XCTestCase {
    private var dataAccess: CoreDataAccess!
    private var model: NSManagedObjectModel!

    override func setUp() {
        super.setUp()

        model = NSManagedObjectModel(contentsOf: Bundle(for: type(of: self)).url(forResource: "TestModel", withExtension: "momd")!)
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model)
    }

    override func tearDown() {
        dataAccess = nil
        model = nil
        super.tearDown()
    }

    func testStackPreparation() {
        XCTAssertFalse(dataAccess.isStackReady)
        dataAccess.prepareStack(asynchronously: false) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(dataAccess.isStackReady)
    }

    func testAsyncStackPreparation() {
        XCTAssertFalse(dataAccess.isStackReady)
        let expect = expectation(description: "completion")
        dataAccess.prepareStack(asynchronously: true) { [weak self] error in
            guard let self = self else {
                return XCTFail("Expected self.")
            }
            XCTAssertNil(error)
            XCTAssertTrue(self.dataAccess.isStackReady)
            expect.fulfill()
        }
        XCTAssertFalse(dataAccess.isStackReady)
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testPerformInBackgroundContext() {
        let expect = expectation(description: "operation")
        dataAccess.performInBackground { context in
            guard let mergePolicy = (context as? NSManagedObjectContext)?.mergePolicy as? NSObject else {
                XCTFail("Couldn't get mergePolicy which is bad.")
                return
            }
            XCTAssertEqual(mergePolicy, NSMergeByPropertyObjectTrumpMergePolicy as? NSObject)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testVendBackgroundContext() {
        guard let context = dataAccess.vendBackgroundContext() as? NSManagedObjectContext else {
            XCTFail("Expected a managed object context.")
            return
        }
        XCTAssertEqual(context.mergePolicy as? NSObject, NSMergeByPropertyObjectTrumpMergePolicy as? NSObject)
        XCTAssertEqual(context.persistentStoreCoordinator, (dataAccess.mainContext as? NSManagedObjectContext)?.persistentStoreCoordinator)
        XCTAssertNil(context.parent)
    }
}


class CoreDataAccessWithSQLFileTests: XCTestCase {
    private var dataAccess: CoreDataAccess!
    private var storeType: CoreDataAccess.StoreType!
    private var model: NSManagedObjectModel!
    private var storeURL: URL! {
        return storeType.url
    }

    override func setUp() {
        super.setUp()

        model = NSManagedObjectModel(contentsOf: Bundle(for: type(of: self)).url(forResource: "TestModel", withExtension: "momd")!)
        storeType = .sql(filename: UUID().uuidString + ".sqlite")
        dataAccess = CoreDataAccess(name: "TestModel", type: storeType, model: model)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil))
    }

    override func tearDown() {
        dataAccess = nil
        model = nil
        storeType = nil
        super.tearDown()
    }

    func testDeleteDatabaseAndNoRebuild() {
        dataAccess.prepareStack(asynchronously: false) { _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil))

        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: false) { _ in
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testDeleteDatabaseAndRebuild() {
        dataAccess.prepareStack(asynchronously: false) { _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil))

        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: true) { _ in
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testDeleteDatabaseWithoutPersistentStoresNoRebuild() {
        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: false) { _ in
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testDeleteDatabaseWithoutPersistentStoresWithRebuild() {
        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: true) { _ in
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }
}

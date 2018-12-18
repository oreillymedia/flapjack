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
    private var delegate: MockDataAccessDelegate! // swiftlint:disable:this weak_delegate

    override func setUp() {
        super.setUp()

        delegate = MockDataAccessDelegate()
        model = NSManagedObjectModel(contentsOf: Bundle(for: type(of: self)).url(forResource: "TestModel", withExtension: "momd")!)
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model, delegate: delegate)
    }

    override func tearDown() {
        delegate = nil
        dataAccess = nil
        model = nil
        super.tearDown()
    }

    func testStackPreparation() {
        XCTAssertFalse(dataAccess.isStackReady)
        XCTAssertFalse(delegate.wantsMigratorForStoreAtCalled.called)
        dataAccess.prepareStack(asynchronously: false) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(dataAccess.isStackReady)
        XCTAssertTrue(delegate.wantsMigratorForStoreAtCalled.called)
    }

    func testStackPreparationWithMigrator() {
        let migrator = MockMigrator()
        migrator.storeIsUpToDate = true
        delegate.migrator = migrator
        dataAccess.prepareStack(asynchronously: false) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(dataAccess.isStackReady)
        XCTAssertTrue(delegate.wantsMigratorForStoreAtCalled.called)
    }

    func testStackPreparationWithMigratorNeedingMigrations() {
        let migrator = MockMigrator()
        migrator.storeIsUpToDate = false
        delegate.migrator = migrator
        dataAccess.prepareStack(asynchronously: false) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(dataAccess.isStackReady)
        XCTAssertTrue(delegate.wantsMigratorForStoreAtCalled.called)
    }

    func testStackPreparationWithMigratorNeedingMigrationsAndBarfing() {
        let migrator = MockMigrator()
        migrator.storeIsUpToDate = false
        migrator.errorToThrow = .diskPreparationError
        delegate.migrator = migrator
        dataAccess.prepareStack(asynchronously: false) { error in
            switch error {
            case .preparationError(let innerError)?:
                switch innerError as? MigratorError {
                case .diskPreparationError?: break
                default: XCTFail("Expected diskPreparationError")
                }

            default: XCTFail("Expected an error.")
            }
        }
        XCTAssertFalse(dataAccess.isStackReady)
        XCTAssertTrue(delegate.wantsMigratorForStoreAtCalled.called)
    }

    func testAsyncStackPreparation() {
        XCTAssertFalse(dataAccess.isStackReady)
        XCTAssertFalse(delegate.wantsMigratorForStoreAtCalled.called)
        let expect = expectation(description: "completion")
        dataAccess.prepareStack(asynchronously: true) { [weak self] error in
            guard let self = self else {
                return XCTFail("Expected self.")
            }
            XCTAssertNil(error)
            XCTAssertTrue(self.dataAccess.isStackReady)
            XCTAssertTrue(self.delegate.wantsMigratorForStoreAtCalled.called)
            expect.fulfill()
        }
        XCTAssertFalse(dataAccess.isStackReady)
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testAsyncStackPreparationWithMigrator() {
        let migrator = MockMigrator()
        migrator.storeIsUpToDate = true
        delegate.migrator = migrator
        let expect = expectation(description: "completion")
        dataAccess.prepareStack(asynchronously: true) { error in
            XCTAssertNil(error)
            XCTAssertTrue(self.dataAccess.isStackReady)
            expect.fulfill()
        }
        XCTAssertFalse(dataAccess.isStackReady)
        // This gets called on the main thread.
        XCTAssertTrue(delegate.wantsMigratorForStoreAtCalled.called)
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testAsyncStackPreparationWithMigratorNeedingMigrations() {
        let migrator = MockMigrator()
        migrator.storeIsUpToDate = false
        delegate.migrator = migrator
        let expect = expectation(description: "completion")
        dataAccess.prepareStack(asynchronously: true) { error in
            XCTAssertNil(error)
            XCTAssertTrue(self.dataAccess.isStackReady)
            expect.fulfill()
        }
        XCTAssertFalse(dataAccess.isStackReady)
        XCTAssertTrue(delegate.wantsMigratorForStoreAtCalled.called)
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testAsyncStackPreparationWithMigratorNeedingMigrationsAndBarfing() {
        let migrator = MockMigrator()
        migrator.storeIsUpToDate = false
        migrator.errorToThrow = .diskPreparationError
        delegate.migrator = migrator
        let expect = expectation(description: "completion")
        dataAccess.prepareStack(asynchronously: true) { error in
            expect.fulfill()
            switch error {
            case .preparationError(let innerError)?:
                switch innerError as? MigratorError {
                case .diskPreparationError?: break
                default: XCTFail("Expected diskPreparationError")
                }

            default: XCTFail("Expected an error.")
            }
            XCTAssertFalse(self.dataAccess.isStackReady)
        }
        XCTAssertTrue(self.delegate.wantsMigratorForStoreAtCalled.called)
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

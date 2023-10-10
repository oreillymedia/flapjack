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
        #if os(iOS)
        print(url.absoluteString)
        XCTAssertTrue(url.absoluteString.hasSuffix("/Library/Application%20Support/abc123.sqlite"))
        #elseif os(macOS)
        XCTAssertTrue(url.absoluteString.hasSuffix("/Library/Application%20Support/xctest/abc123.sqlite"))
        #elseif os(tvOS)
        XCTAssertTrue(url.absoluteString.hasSuffix("/Library/Caches/abc123.sqlite"))
        #endif
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
    private var bundle: Bundle {
        #if COCOAPODS
        return Bundle(for: type(of: self))
        #else
        return Bundle.module
        #endif
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        delegate = MockDataAccessDelegate()
        let modelPath = try XCTUnwrap(bundle.url(forResource: "TestModel", withExtension: "momd"), "Unable to find TestModel.momd")
        model = NSManagedObjectModel(contentsOf: modelPath)
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model, delegate: delegate)
    }

    override func tearDownWithError() throws {
        delegate = nil
        dataAccess = nil
        model = nil
        try super.tearDownWithError()
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
            defer { expect.fulfill() }
            guard let self = self else {
                return XCTFail("Expected self.")
            }
            XCTAssertNil(error)
            XCTAssertTrue(self.dataAccess.isStackReady)
            XCTAssertTrue(self.delegate.wantsMigratorForStoreAtCalled.called)
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
            defer { expect.fulfill() }
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
            defer { expect.fulfill() }
            guard let mergePolicy = (context as? NSManagedObjectContext)?.mergePolicy as? NSObject else {
                XCTFail("Couldn't get mergePolicy which is bad.")
                return
            }
            XCTAssertEqual(mergePolicy, NSMergeByPropertyStoreTrumpMergePolicy as? NSObject)
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func testAsyncPerformInBackgroundContext() async throws {
        let value = await dataAccess.performBackgroundTask { context in
            guard let mergePolicy = (context as? NSManagedObjectContext)?.mergePolicy as? NSObject else {
                XCTFail("Couldn't get mergePolicy which is bad.")
                return ""
            }
            XCTAssertEqual(mergePolicy, NSMergeByPropertyStoreTrumpMergePolicy as? NSObject)
            return "done"
        }
        XCTAssertEqual(value, "done")
    }

    func testVendBackgroundContext() {
        guard let context = dataAccess.vendBackgroundContext() as? NSManagedObjectContext else {
            XCTFail("Expected a managed object context.")
            return
        }
        XCTAssertEqual(context.mergePolicy as? NSObject, NSMergeByPropertyStoreTrumpMergePolicy as? NSObject)
        XCTAssertEqual(context.persistentStoreCoordinator, (dataAccess.mainContext as? NSManagedObjectContext)?.persistentStoreCoordinator)
        XCTAssertNil(context.parent)
    }

    // MARK: - Context Propagation Testing

    func testMainContextGetsCorrectPolicy() {
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model, delegate: delegate, defaultPolicy: .rollback)
        guard let mergePolicy = (dataAccess.mainContext as? NSManagedObjectContext)?.mergePolicy as? NSObject else {
            XCTFail("Couldn't get mergePolicy which is bad.")
            return
        }
        XCTAssertEqual(mergePolicy, NSRollbackMergePolicy as? NSObject)
    }

    func testVendBackgroundContextGetsCorrectPolicy() {
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model, delegate: delegate, defaultPolicy: .overwrite)
        guard let context = dataAccess.vendBackgroundContext() as? NSManagedObjectContext else {
            XCTFail("Expected a managed object context.")
            return
        }
        XCTAssertEqual(context.mergePolicy as? NSObject, NSOverwriteMergePolicy as? NSObject)
    }

    func testPerformInBackgroundContextGetsCorrectPolicy() {
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model, delegate: delegate, defaultPolicy: .rollback)
        let expect = expectation(description: "operation")
        dataAccess.performInBackground { context in
            defer { expect.fulfill() }
            guard let mergePolicy = (context as? NSManagedObjectContext)?.mergePolicy as? NSObject else {
                XCTFail("Couldn't get mergePolicy which is bad.")
                return
            }
            XCTAssertEqual(mergePolicy, NSRollbackMergePolicy as? NSObject)
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }
}


class CoreDataAccessWithSQLFileTests: XCTestCase {
    private var dataAccess: CoreDataAccess!
    private var storeType: CoreDataAccess.StoreType!
    private var model: NSManagedObjectModel!
    private var bundle: Bundle {
        #if COCOAPODS
        return Bundle(for: type(of: self))
        #else
        return Bundle.module
        #endif
    }

    private var storeURL: URL! {
        return storeType.url
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        let modelPath = try XCTUnwrap(bundle.url(forResource: "TestModel", withExtension: "momd"), "Unable to find TestModel.momd")
        model = NSManagedObjectModel(contentsOf: modelPath)
        storeType = .sql(filename: UUID().uuidString + ".sqlite")
        dataAccess = CoreDataAccess(name: "TestModel", type: storeType, model: model)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil))
    }

    override func tearDownWithError() throws {
        dataAccess = nil
        model = nil
        storeType = nil
        try super.tearDownWithError()
    }

    func testDeleteDatabaseAndNoRebuild() {
        dataAccess.prepareStack(asynchronously: false) { _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil))

        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: false) { error in
            XCTAssertNil(error)
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testDeleteDatabaseAndRebuild() {
        dataAccess.prepareStack(asynchronously: false) { _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil))

        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: true) { error in
            XCTAssertNil(error)
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testDeleteDatabaseWithoutPersistentStoresNoRebuild() {
        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: false) { error in
            XCTAssertNil(error)
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testDeleteDatabaseWithoutPersistentStoresWithRebuild() {
        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: true) { error in
            XCTAssertNil(error)
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testDeleteDatabaseWithoutPersistentStoresJunkSQLNoRebuild() throws {
        try "junk".write(to: storeURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil))

        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: false) { error in
            XCTAssertNil(error)
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testDeleteDatabaseWithoutPersistentStoresJunkSQLWithRebuild() throws {
        try "junk".write(to: storeURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil))

        let expect = expectation(description: "completion")
        dataAccess.deleteDatabase(rebuild: true) { error in
            XCTAssertNil(error)
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.storeURL.path, isDirectory: nil))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }
}

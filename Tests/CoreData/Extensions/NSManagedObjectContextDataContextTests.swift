//
//  NSManagedObjectContextDataContextTests.swift
//  Flapjack-Unit-CoreData-Tests
//
//  Created by Ben Kreeger on 11/1/18.
//

import XCTest
import CoreData

@testable import Flapjack
@testable import FlapjackCoreData

class NSManagedObjectContextDataContextTests: XCTestCase {
    private var bundle: Bundle {
        #if COCOAPODS
        return Bundle(for: type(of: self))
        #else
        return Bundle.module
        #endif
    }

    private var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let modelFile = try XCTUnwrap(bundle.url(forResource: "TestModel", withExtension: "momd"), "Unable to load TestModel.momd")
        let model = NSManagedObjectModel(contentsOf: modelFile)
        let dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model)
        dataAccess.prepareStack(asynchronously: false) { _ in }
        context = dataAccess.mainContext as? NSManagedObjectContext
    }

    override func tearDownWithError() throws {
        context = nil
        try super.tearDownWithError()
    }


    // MARK: - Block perform operations

    func testPerformWithBlock() {
        let expect = expectation(description: "performBlock")
        context.perform { innerContext in
            XCTAssertEqual(innerContext as? NSManagedObjectContext, self.context)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testPerformSyncWithBlock() {
        // No async expectation should be needed.
        context.performSync { innerContext in
            XCTAssertEqual(innerContext as? NSManagedObjectContext, self.context)
        }
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func testAsyncPerformWithBlock() async throws {
        let val = await context.perform { innerContext in
            XCTAssertEqual(innerContext as? NSManagedObjectContext, self.context)
            return "passed"
        }
        XCTAssertEqual(val, "passed")
    }

    // MARK: - Persistence calls

    func testPersist() {
        expectation(forNotification: .NSManagedObjectContextDidSave, object: context, handler: nil)

        // Without changes, a notification is not fired.
        XCTAssertNil(context.persist())

        // With invalid changes, a notification is not fired.
        let mock = context.create(MockEntity.self)
        mock.someProperty = nil
        XCTAssertNotNil(context.persist())

        // With valid changes, a notification is fired.
        mock.someProperty = "valid value"
        XCTAssertNil(context.persist())

        // Thus our expectation should only get called once.
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testPersistOrThrow() throws {
        expectation(forNotification: .NSManagedObjectContextDidSave, object: context, handler: nil)

        // Without changes, a notification is not fired.
        try context.persistOrThrow()

        // With invalid changes, a notification is not fired.
        let mock = context.create(MockEntity.self)
        mock.someProperty = nil
        do {
            try context.persistOrThrow()
            XCTAssertNotNil(nil)
        } catch {
            XCTAssertNotNil(error)
        }

        // With valid changes, a notification is fired.
        mock.someProperty = "valid value"
        try context.persistOrThrow()

        // Thus our expectation should only get called once.
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testPersistOrRollback() {
        expectation(forNotification: .NSManagedObjectContextDidSave, object: context, handler: nil)

        // Without changes, a notification is not fired, but result is true.
        XCTAssertTrue(context.persistOrRollback())

        // With invalid changes, a notification is not fired, and result is false, which represents a rollback.
        let mock = context.create(MockEntity.self)
        mock.someProperty = nil
        XCTAssertFalse(context.persistOrRollback())

        // With valid changes, a notification is fired, and the result is true. Have to create a new mock entity
        //   instance, since rolling our context back would have removed the old one from the context.
        _ = context.create(MockEntity.self)
        XCTAssertTrue(context.persistOrRollback())

        // Thus our expectation should only get called once.
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }

    func testForcePersist() {
        expectation(forNotification: .NSManagedObjectContextDidSave, object: context, handler: nil)
        let result = context.forcePersist()
        XCTAssertNil(result)
        waitForExpectations(timeout: 1.0) { XCTAssertNil($0) }
    }


    // MARK: - Collection fetch operations

    func testObjectsOfTypeWithPredicate() {
        let expect1 = context.create(MockEntity.self, attributes: [#keyPath(MockEntity.someProperty): "some value"])
        let expect2 = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        let expect3 = context.create(MockEntity.self, attributes: ["someProperty": "some other value"])

        let predicate = NSPredicate(format: "someProperty == %@", "some value")
        let results = context.objects(ofType: MockEntity.self, predicate: predicate, prefetch: nil, sortBy: MockEntity.defaultSorters, limit: nil)
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(expect1))
        XCTAssertTrue(results.contains(expect2))
        XCTAssertFalse(results.contains(expect3))
    }

    func testObjectsOfTypeWithObjectIDs() {
        let expect1 = context.create(MockEntity.self, attributes: [#keyPath(MockEntity.someProperty): "some value"])
        let expect2 = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        let expect3 = context.create(MockEntity.self, attributes: ["someProperty": "some other value"])

        let objectIDs = [expect2.objectID, expect3.objectID]
        let results = context.objects(ofType: MockEntity.self, objectIDs: objectIDs, prefetch: nil, sortBy: MockEntity.defaultSorters, limit: nil)
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(expect2))
        XCTAssertTrue(results.contains(expect3))
        XCTAssertFalse(results.contains(expect1))

        context.destroy(object: expect3)
        let results2 = context.objects(ofType: MockEntity.self, objectIDs: objectIDs, prefetch: nil, sortBy: MockEntity.defaultSorters, limit: nil)
        XCTAssertEqual(results2.count, 1)
        XCTAssertTrue(results2.contains(expect2))
        XCTAssertFalse(results2.contains(expect3))
        XCTAssertFalse(results2.contains(expect1))
    }

    func testNumberOfObjectsOfTypeWithPredicate() {
        _ = context.create(MockEntity.self, attributes: [#keyPath(MockEntity.someProperty): "some value"])
        _ = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        _ = context.create(MockEntity.self, attributes: ["someProperty": "some other value"])

        let predicate = NSPredicate(format: "someProperty == %@", "some value")
        let result = context.numberOfObjects(ofType: MockEntity.self, predicate: predicate)
        XCTAssertEqual(result, 2)
    }


    // MARK: - Single fetch operations

    func testObjectOfTypeWithPredicate() {
        let result1 = context.create(MockEntity.self, attributes: [#keyPath(MockEntity.someProperty): "some value"])
        result1.identifier = "bbb"
        let result2 = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        result2.identifier = "aaa"

        let predicate = NSPredicate(format: "someProperty == %@", "some value")
        let result = context.object(ofType: MockEntity.self, predicate: predicate, prefetch: nil, sortBy: MockEntity.defaultSorters)
        XCTAssertEqual(result, result2)
    }

    func testObjectOfTypeWithObjectID() {
        let result1 = context.create(MockEntity.self, attributes: [#keyPath(MockEntity.someProperty): "some value"])
        _ = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        XCTAssertEqual(context.object(ofType: MockEntity.self, objectID: result1.objectID), result1)

        context.destroy(object: result1)
        XCTAssertNil(context.object(ofType: MockEntity.self, objectID: result1.objectID))
    }

    func testRefetch() {
        let result1 = context.create(MockEntity.self, attributes: [#keyPath(MockEntity.someProperty): "some value"])
        _ = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        XCTAssertEqual(context.refetch(result1), result1)

        context.destroy(object: result1)
        XCTAssertNil(context.refetch(result1))
    }


    // MARK: - Creation & destruction operations

    func testCreateSimple() {
        let result1 = context.create(MockEntity.self)
        XCTAssertEqual(result1.managedObjectContext, context)
        XCTAssertTrue(result1.isInserted)
    }

    func testCreateWithAttributes() {
        let result1 = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        XCTAssertEqual(result1.managedObjectContext, context)
        XCTAssertTrue(result1.isInserted)
        XCTAssertEqual(result1.someProperty, "some value")
    }

    func testDestroy() {
        let result1 = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        _ = context.persist()
        context.destroy(object: result1)
        XCTAssertTrue(result1.isDeleted)
    }

    func testDestroyMany() {
        let result1 = context.create(MockEntity.self, attributes: ["someProperty": "some value"])
        let result2 = context.create(MockEntity.self, attributes: ["someProperty": "some other value"])
        _ = context.persist()
        context.destroy(objects: [result1, result2])
        XCTAssertTrue(result1.isDeleted)
        XCTAssertTrue(result2.isDeleted)
    }
}

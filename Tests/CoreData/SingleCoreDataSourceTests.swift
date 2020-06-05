//
//  SingleCoreDataSourceTests.swift
//  Tests
//
//  Created by Ben Kreeger on 11/30/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest
import CoreData

@testable import Flapjack
@testable import FlapjackCoreData

class SingleCoreDataSourceTests: XCTestCase {
    private var dataAccess: DataAccess!
    private var dataSource: SingleCoreDataSource<MockEntity>!
    private var attributes: [String: String] {
        return ["someProperty": "someValue"]
    }
    private var entity: MockEntity!

    override func setUp() {
        super.setUp()
        let model = NSManagedObjectModel(contentsOf: Bundle(for: type(of: self)).url(forResource: "TestModel", withExtension: "momd")!)
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model)
        dataAccess.prepareStack(asynchronously: false, completion: { _ in })

        entity = dataAccess.mainContext.create(MockEntity.self, attributes: attributes)
        dataSource = SingleCoreDataSource<MockEntity>(context: dataAccess.mainContext, attributes: attributes, prefetch: [])
    }

    override func tearDown() {
        dataAccess = nil
        entity = nil
        dataSource = nil
        super.tearDown()
    }

    func testObjectIsNilOnInit() {
        XCTAssertNil(dataSource.object)
        XCTAssertNotNil(dataSource.predicate)
        XCTAssertNil(dataSource.onChange)
    }

    func testExecutionFetchesRightAway() {
        XCTAssertNil(dataSource.object)
        dataSource.startListening()
        XCTAssertEqual(dataSource.object, entity)
    }

    func testCoreDataNotificationNotPickedUpBeforestartListening() {
        let expect = expectation(description: "did change block")
        expect.isInverted = true
        dataSource.onChange = { object in
            expect.fulfill()
        }
        // Should not fire the expectation
        entity.someProperty = "some other value"
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.25) { XCTAssertNil($0) }
    }

    func testExecutionSubscribesToNotificationAndDidChangeFiresRightAway() {
        let expect = expectation(description: "did change block")
        expect.expectedFulfillmentCount = 1
        dataSource.onChange = { object in
            expect.fulfill()
        }
        dataSource.startListening()
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
    }

    func testObjectDidChangeBlockFiresForSavesInvolvingObject() {
        let expect = expectation(description: "did change block")
        dataSource.onChange = { object in
            expect.fulfill()
        }
        dataSource.startListening()
        entity.someProperty = "some new value"
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
    }

    func testObjectDidChangeBlockFiresForChangeProcessesInvolvingObject() {
        let expect = expectation(description: "did change block")
        dataSource.onChange = { object in
            expect.fulfill()
        }
        dataSource.startListening()
        entity.someProperty = "some new value"
        dataAccess.mainContext.processPendingChanges()
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
    }

    func testObjectDidChangeBlockFiresForOnlyChangesAndSavesInvolvingObject() {
        let otherEntity = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "other value"])
        dataAccess.mainContext.persist()

        let expect = expectation(description: "did change block")
        dataSource.onChange = { object in
            expect.fulfill()
        }
        dataSource.startListening()
        entity.someProperty = "some new value"
        otherEntity.someProperty = "other other value"
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
    }

    func testObjectIsNilIfDestroyed() {
        dataAccess.mainContext.destroy(object: entity)
        dataAccess.mainContext.persist()

        dataSource.startListening()
        XCTAssertNil(dataSource.object)
    }

    func testDidChangeIsCalledWithNilIfDestroyed() {
        let expect = expectation(description: "did change block")
        expect.expectedFulfillmentCount = 2
        dataSource.onChange = { object in
            expect.fulfill()
        }
        dataSource.startListening()
        dataAccess.mainContext.destroy(object: entity)
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
        XCTAssertNil(dataSource.object)
    }

    func testObjectDidChangeBlockFiresWhenObjectStartsToExist() {
        dataAccess.mainContext.destroy(object: entity)
        dataAccess.mainContext.persist()

        let expect = expectation(description: "did change block")
        expect.expectedFulfillmentCount = 2
        dataSource.onChange = { object in
            expect.fulfill()
        }
        dataSource.startListening()
        XCTAssertNil(dataSource.object)

        let newEntity = dataAccess.mainContext.create(MockEntity.self, attributes: attributes)
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }

        XCTAssertEqual(dataSource.object, newEntity)
    }

    func testObjectDidChangeBlockFiresWhenObjectMatchingQueryIsReplaced() {
        let newEntity = dataAccess.mainContext.create(MockEntity.self, attributes: attributes)
        dataAccess.mainContext.persist()

        let expect = expectation(description: "did change block")
        expect.expectedFulfillmentCount = 2
        dataSource.onChange = { object in
            expect.fulfill()
        }
        dataSource.startListening()

        entity.someProperty = "some new value"
        newEntity.someProperty = attributes["someProperty"]
        dataAccess.mainContext.persist()

        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
        XCTAssertEqual(dataSource.object, newEntity)
    }

    func testObjectDidChangeBlockFiresTwiceWhenOldObjectIsDeletedAndNewOneCreated() {
        let expect = expectation(description: "did change block")
        expect.expectedFulfillmentCount = 3
        dataSource.onChange = { object in
            expect.fulfill()
        }
        dataSource.startListening()

        let newEntity = dataAccess.mainContext.create(MockEntity.self, attributes: attributes)
        newEntity.someProperty = attributes["someProperty"]
        dataAccess.mainContext.destroy(object: entity)
        dataAccess.mainContext.persist()

        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
        XCTAssertEqual(dataSource.object, newEntity)
    }
}

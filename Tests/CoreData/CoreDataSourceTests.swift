//
//  CoreDataSourceTests.swift
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

class CoreDataSourceTests: XCTestCase {
    private var dataAccess: DataAccess!
    private var entityOne: MockEntity!
    private var entityTwo: MockEntity!
    private var entityThree: MockEntity!
    private var entityFour: MockEntity!
    private var entityFive: MockEntity!

    override func setUp() {
        super.setUp()
        let model = NSManagedObjectModel(contentsOf: Bundle(for: type(of: self)).url(forResource: "TestModel", withExtension: "momd")!)
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model)
        dataAccess.prepareStack(asynchronously: false, completion: { _ in })

        entityOne = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        entityTwo = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        entityThree = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue zzza"])
        entityFour = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue zzzz"])
        entityFive = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue aaaa"])

        dataAccess.mainContext.persist()
    }

    override func tearDown() {
        dataAccess = nil
        entityOne = nil
        entityTwo = nil
        entityThree = nil
        super.tearDown()
    }


    // MARK: Unfiltered

    func testObjectsAreEmptyAtInit() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        XCTAssertEqual(dataSource.numberOfObjects, 0)
        XCTAssertEqual(dataSource.numberOfSections, 0)
        XCTAssertTrue(dataSource.allObjects.isEmpty)
    }

    func testObjectsArePopulatedAfterExecution() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        dataSource.startListening()
        XCTAssertEqual(dataSource.numberOfObjects, 5)
        XCTAssertEqual(dataSource.allObjects.count, 5)
        XCTAssertEqual(dataSource.numberOfSections, 1)
        XCTAssertTrue(dataSource.allObjects.contains(entityOne))
        XCTAssertTrue(dataSource.allObjects.contains(entityTwo))
        XCTAssertTrue(dataSource.allObjects.contains(entityThree))
        XCTAssertTrue(dataSource.allObjects.contains(entityFour))
    }

    func testChangeBlockDoesNotFireBeforeExecution() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        let expect = expectation(description: "on change")
        expect.isInverted = true
        dataSource.onChange = { items, sections in
            expect.fulfill()
        }
        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        dataAccess.mainContext.destroy(object: entityOne)
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.25) { XCTAssertNil($0) }
    }

    func testChangeBlockFiresWhenThereAreChanges() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        let expect = expectation(description: "on change")
        expect.expectedFulfillmentCount = 1
        dataSource.onChange = { items, sections in
            expect.fulfill()
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(sections.count, 0)
        }
        dataSource.startListening()
        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        dataAccess.mainContext.destroy(object: entityOne)
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
    }

    func testChangeBlockDoesNotFireAfterStopListening() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        let expect = expectation(description: "on change")
        expect.expectedFulfillmentCount = 1
        dataSource.onChange = { items, sections in
            expect.fulfill()
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(sections.count, 0)
        }
        dataSource.startListening()
        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        dataAccess.mainContext.destroy(object: entityOne)
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
        dataSource.endListening()
        let expect2 = expectation(description: "on change")
        expect2.isInverted = true
        dataSource.onChange = { items, sections in
            expect2.fulfill()
        }
        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        dataAccess.mainContext.destroy(object: entityTwo)
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
    }

    // MARK: Filtered

    func testFilteredFetchOnlyReturnsThoseMatching() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, attributes: ["someProperty": "someValue alpha"])
        dataSource.startListening()
        XCTAssertEqual(dataSource.numberOfObjects, 2)
        XCTAssertEqual(dataSource.allObjects.count, 2)
        XCTAssertTrue(dataSource.allObjects.contains(entityOne))
        XCTAssertTrue(dataSource.allObjects.contains(entityTwo))
        XCTAssertFalse(dataSource.allObjects.contains(entityThree))
        XCTAssertFalse(dataSource.allObjects.contains(entityFour))
    }

    func testFilteredAutomaticallyUpdatesAllObjectsOnChange() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, attributes: ["someProperty": "someValue alpha"])
        dataSource.startListening()
        XCTAssertEqual(dataSource.numberOfObjects, 2)
        XCTAssertEqual(dataSource.allObjects.count, 2)

        entityOne.someProperty = "someValue beta"
        dataAccess.mainContext.persist()
        XCTAssertEqual(dataSource.numberOfObjects, 1)
        XCTAssertEqual(dataSource.allObjects.count, 1)
    }

    func testFilteredAutomaticallyUpdatesAllObjectsOnDestroy() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, attributes: ["someProperty": "someValue alpha"])
        dataSource.startListening()
        XCTAssertEqual(dataSource.numberOfObjects, 2)
        XCTAssertEqual(dataSource.allObjects.count, 2)
        dataAccess.mainContext.destroy(object: entityOne)
        dataAccess.mainContext.persist()
        XCTAssertEqual(dataSource.numberOfObjects, 1)
        XCTAssertEqual(dataSource.allObjects.count, 1)
    }

    func testFilteredAutomaticallyIncludesNewMatchingObjects() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, attributes: ["someProperty": "someValue alpha"])
        dataSource.startListening()
        XCTAssertEqual(dataSource.numberOfObjects, 2)
        XCTAssertEqual(dataSource.allObjects.count, 2)

        let entitySix = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        dataAccess.mainContext.persist()
        XCTAssertEqual(dataSource.numberOfObjects, 3)
        XCTAssertEqual(dataSource.allObjects.count, 3)
        XCTAssertTrue(dataSource.allObjects.contains(entitySix))
    }


    // MARK: Sorted

    func testSortedReturnsObjectsInProperOrder() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, sorters: [SortDescriptor("someProperty", ascending: false)])
        dataSource.startListening()
        // entityOne and entityTwo could be in either position 1 or 2
        XCTAssertEqual(dataSource.allObjects.first, entityFour)
        XCTAssertEqual(dataSource.allObjects.last, entityFive)
    }

    func testSortedReturnsObjectsInProperOrderEvenWithNewItemsOrChanges() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, sorters: [SortDescriptor("someProperty", ascending: false)])
        dataSource.startListening()
        XCTAssertEqual(dataSource.allObjects.first, entityFour)
        XCTAssertEqual(dataSource.allObjects.last, entityFive)

        entityFour.someProperty = "zzzzzzzzz"
        let entitySix = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "aaaa"])
        dataAccess.mainContext.persist()
        XCTAssertEqual(dataSource.numberOfObjects, 6)
        XCTAssertEqual(dataSource.allObjects.first, entityFour)
        XCTAssertEqual(dataSource.allObjects.last, entitySix)
    }


    // MARK: Grouped

    func testGroupedGroupsObjectsByAPropertyAndReflectsLiveChanges() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, sorters: [SortDescriptor("someProperty", ascending: false)], sectionProperty: "someProperty")

        let expect = expectation(description: "on change")
        expect.expectedFulfillmentCount = 1
        dataSource.onChange = { items, sections in
            expect.fulfill()
            // One section renamed, one inserted, one moved due to reordering
            XCTAssertEqual(sections.count, 3)
        }

        dataSource.startListening()

        XCTAssertEqual(dataSource.numberOfObjects, 5)
        XCTAssertEqual(dataSource.numberOfSections, 4)
        XCTAssertEqual(dataSource.sectionIndexTitles, ["S", "S", "S", "S"])
        XCTAssertEqual(dataSource.sectionNames, ["someValue zzzz", "someValue zzza", "someValue alpha", "someValue aaaa"])

        entityFour.someProperty = "zzzz"
        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "aaaa"])
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.25) { XCTAssertNil($0) }

        XCTAssertEqual(dataSource.numberOfObjects, 6)
        XCTAssertEqual(dataSource.numberOfSections, 5)
        XCTAssertEqual(dataSource.sectionIndexTitles, ["Z", "S", "S", "S", "A"])
        XCTAssertEqual(dataSource.sectionNames, ["zzzz", "someValue zzza", "someValue alpha", "someValue aaaa", "aaaa"])
    }


    // MARK: Limited

    func testLimitedOnlyReturnsThoseFallingInUnderTheLimit() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, sorters: [SortDescriptor("someProperty", ascending: false)], limit: 2)
        dataSource.startListening()
        XCTAssertEqual(dataSource.numberOfObjects, 2)
        XCTAssertEqual(dataSource.allObjects.count, 2)
        XCTAssertFalse(dataSource.allObjects.contains(entityOne))
        XCTAssertFalse(dataSource.allObjects.contains(entityTwo))
        XCTAssertFalse(dataSource.allObjects.contains(entityFive))
        XCTAssertTrue(dataSource.allObjects.contains(entityFour))
        XCTAssertTrue(dataSource.allObjects.contains(entityThree))
    }

    func testLimitedAutomaticallyUpdatesAllObjectsOnChange() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, sorters: [SortDescriptor("someProperty", ascending: false)], limit: 2)
        dataSource.startListening()
        XCTAssertEqual(dataSource.numberOfObjects, 2)
        XCTAssertEqual(dataSource.allObjects.count, 2)

        entityOne.someProperty = "z"
        dataAccess.mainContext.persist()
        XCTAssertEqual(dataSource.numberOfObjects, 2)
        XCTAssertEqual(dataSource.allObjects.count, 2)

        XCTAssertFalse(dataSource.allObjects.contains(entityThree))
        XCTAssertTrue(dataSource.allObjects.contains(entityFour))
        XCTAssertTrue(dataSource.allObjects.contains(entityOne))
    }
}

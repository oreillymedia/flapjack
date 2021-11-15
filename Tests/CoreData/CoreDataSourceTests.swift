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
import Combine

@testable import Flapjack
@testable import FlapjackCoreData

class CoreDataSourceTests: XCTestCase {
    private var dataAccess: DataAccess!
    private var entityOne: MockEntity!
    private var entityTwo: MockEntity!
    private var entityThree: MockEntity!
    private var entityFour: MockEntity!
    private var entityFive: MockEntity!
    private var bundle: Bundle {
        #if COCOAPODS
        return Bundle(for: type(of: self))
        #else
        return Bundle.module
        #endif
    }


    override func setUpWithError() throws {
        try super.setUpWithError()
        let modelFile = try XCTUnwrap(bundle.url(forResource: "TestModel", withExtension: "momd"), "Unable to load TestModel.momd")
        let model = NSManagedObjectModel(contentsOf: modelFile)
        dataAccess = CoreDataAccess(name: "TestModel", type: .memory, model: model)
        dataAccess.prepareStack(asynchronously: false, completion: { _ in })

        entityOne = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        entityTwo = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        entityThree = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue zzza"])
        entityFour = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue zzzz"])
        entityFive = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue aaaa"])

        dataAccess.mainContext.persist()
    }

    override func tearDownWithError() throws {
        dataAccess = nil
        entityOne = nil
        entityTwo = nil
        entityThree = nil
        try super.tearDownWithError()
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
        dataSource.onChange = { _, _ in
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
        dataSource.onChange = { _, _ in
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
        dataSource.onChange = { _, sections in
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

    // MARK: Change predicate

    func testChangePredicate() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, sorters: [SortDescriptor("someProperty", ascending: false)])
        dataSource.startListening()
        XCTAssertEqual(dataSource.numberOfObjects, 5)
        dataSource.predicate = NSPredicate(format: "someProperty contains \"zzzz\"")
        XCTAssertEqual(dataSource.numberOfObjects, 1)
        dataSource.predicate = nil
        XCTAssertEqual(dataSource.numberOfObjects, 5)
    }

    // MARK: Change sorters

    func testChangeSorters() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, sorters: [SortDescriptor("someProperty", ascending: true)])
        dataSource.startListening()
        XCTAssertEqual(dataSource.allObjects.first?.someProperty, "someValue aaaa")
        dataSource.sorters = [SortDescriptor("someProperty", ascending: false)]
        XCTAssertEqual(dataSource.allObjects.first?.someProperty, "someValue zzzz")
    }

    // MARK: Test context destruction

    func testContextDestruction() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        let indexPath = IndexPath(item: 0, section: 0)
        dataSource.startListening()
        XCTAssertNotNil(dataSource.object(at: indexPath))

        let callback = expectation(description: "callback")
        dataAccess.deleteDatabase(rebuild: false) { _ in
            callback.fulfill()
        }
        wait(for: [callback], timeout: 1.0)

        XCTAssertNil(dataSource.object(at: indexPath))
        XCTAssertEqual(dataSource.numberOfObjects, 0)
    }

    func testContextRecreation() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess, attributes: ["someProperty": "someValue alpha"])
        let indexPath = IndexPath(item: 0, section: 0)
        dataSource.startListening()
        XCTAssertNotNil(dataSource.object(at: indexPath))

        let callback = expectation(description: "callback")
        dataAccess.deleteDatabase(rebuild: true) { _ in
            callback.fulfill()
        }
        wait(for: [callback], timeout: 1.0)

        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue beta"])
        dataAccess.mainContext.persist()

        // We're ensuring that the `predicateToSurviveContextWipe` got restored
        XCTAssertEqual(dataSource.numberOfObjects, 1)
    }

    func testContextRecreation_WithoutPredicate() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        let indexPath = IndexPath(item: 0, section: 0)
        dataSource.startListening()
        XCTAssertNotNil(dataSource.object(at: indexPath))

        let callback = expectation(description: "callback")
        dataAccess.deleteDatabase(rebuild: true) { _ in
            callback.fulfill()
        }
        wait(for: [callback], timeout: 1.0)

        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue alpha"])
        _ = dataAccess.mainContext.create(MockEntity.self, attributes: ["someProperty": "someValue beta"])
        dataAccess.mainContext.persist()

        // We're ensuring that the `predicateToSurviveContextWipe` got restored, even if it was `nil`
        XCTAssertEqual(dataSource.numberOfObjects, 2)
    }

    func testOnChangeBlock_FiresWithDeletions_OnContextDestruction() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)

        let indexPaths = (0..<5).map { IndexPath(item: $0, section: 0) }

        let callback = expectation(description: "callback")
        dataSource.onChange = { itemChanges, sectionChanges in
            let expected: [DataSourceChange] = indexPaths.map { .delete(path: $0) }
            XCTAssertEqual(itemChanges, expected)
            XCTAssertEqual(sectionChanges, [.delete(section: 0)])
            XCTAssertEqual(dataSource.numberOfSections, 0)
            XCTAssertEqual(dataSource.numberOfObjects, 0)
            XCTAssertEqual(dataSource.numberOfObjects(in: 0), 0)
            // The objects still exist when direct lookup is used
            indexPaths.forEach { path in
                XCTAssertNotNil(dataSource.object(at: path), "Object at \(path) was supposed to be non-nil")
            }
            callback.fulfill()
        }
        dataSource.startListening()

        let deleteCallback = expectation(description: "callback")
        dataAccess.deleteDatabase(rebuild: false) { _ in
            deleteCallback.fulfill()
        }
        wait(for: [callback, deleteCallback], timeout: 1.0)

        // After deletion completes, objects are definitely gone
        indexPaths.forEach { path in
            XCTAssertNil(dataSource.object(at: path), "Object at \(path) was supposed to be nil")
        }
    }

    func testPublisher() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        let expect = expectation(description: "sink")
        var savedSubs: Set<AnyCancellable> = []
        dataSource.startListening()
        dataSource.objects.sink { objects in
            XCTAssertEqual(objects.count, 5)
            expect.fulfill()
        }.store(in: &savedSubs)
        wait(for: [expect], timeout: 1.0)
    }

    func testPublisherChanges() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        let expect = expectation(description: "sink")
        expect.expectedFulfillmentCount = 2
        var savedSubs: Set<AnyCancellable> = []
        var expectedValues = [5, 4]
        dataSource.startListening()
        dataSource.objects.sink { objects in
            XCTAssertEqual(objects.count, expectedValues[0])
            expectedValues.removeFirst()
            expect.fulfill()
        }.store(in: &savedSubs)
        dataAccess.mainContext.destroy(object: entityOne)
        dataAccess.mainContext.persist()
        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
    }

    func testPublisherUpdateFetchRequest() {
        let dataSource = CoreDataSource<MockEntity>(dataAccess: dataAccess)
        let expect = expectation(description: "sink")
        expect.expectedFulfillmentCount = 3
        var savedSubs: Set<AnyCancellable> = []
        var expectedValues = [5, 1, 5]
        dataSource.startListening()
        dataSource.objects.sink { objects in
            XCTAssertEqual(objects.count, expectedValues[0])
            expectedValues.removeFirst()
            expect.fulfill()
        }.store(in: &savedSubs)
        dataSource.predicate = NSPredicate(format: "someProperty contains \"zzzz\"")
        dataSource.predicate = nil

        waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
    }
}

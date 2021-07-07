//
//  CoreDataMigratorTests.swift
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

class CoreDataMigratorTests: XCTestCase {
    private var urlsToCleanup = [URL]()
    private let modelName = "TestMigrationModel"
    private var bundle: Bundle {
        #if COCOAPODS
        return Bundle(for: type(of: self))
        #else
        return Bundle.module
        #endif
    }
    private var compiledModelURL: URL {
        return bundle.url(forResource: modelName, withExtension: "momd")!
    }
    private lazy var versionInfo: [String: Any] = {
        guard FileManager.default.fileExists(atPath: compiledModelURL.path) else { return [:] }
        return NSDictionary(contentsOf: compiledModelURL.appendingPathComponent("VersionInfo.plist", isDirectory: false)) as? [String: Any] ?? [:]
    }()
    private lazy var knownVersions: [String] = {
        let versionHashes = versionInfo["NSManagedObjectModel_VersionHashes"] as? [String: Any]
        return versionHashes?.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending } ?? []
    }()
    private var currentVersion: String {
        return versionInfo["NSManagedObjectModel_CurrentVersionName"] as? String ?? ""
    }

    override func setUp() {
        super.setUp()
        Logger.logLevel = .debug
        urlsToCleanup = [URL]()
    }

    override func tearDown() {
        urlsToCleanup.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
        urlsToCleanup.removeAll()
        super.tearDown()
    }


    // MARK: storeIsUpToDate

    func testStateWithFreshDatabase() throws {
        let (storeURL, filename, _) = try persistentStoreContainer(version: currentVersion)
        urlsToCleanup.append(storeURL)
        let migrator = CoreDataMigrator(storeURL: storeURL, bundle: bundle, modelName: "TestMigrationModel", storeType: .sql(filename: filename))
        XCTAssertTrue(migrator.storeIsUpToDate)
    }

    func testWithStaleDatabases() throws {
        try knownVersions.forEach { versionString in
            guard versionString != currentVersion else { return }
            let (storeURL, filename, _) = try persistentStoreContainer(version: versionString)
            urlsToCleanup.append(storeURL)
            let migrator = CoreDataMigrator(storeURL: storeURL, bundle: bundle, modelName: "TestMigrationModel", storeType: .sql(filename: filename))
            XCTAssertFalse(migrator.storeIsUpToDate, "\(versionString) should be stale.")
        }
    }


    // MARK: migrate() throws

    func testMigrateEmptyDataStoreFromOriginalVersion() throws {
        let original = knownVersions[0]
        let (storeURL, filename, _) = try persistentStoreContainer(version: original)
        urlsToCleanup.append(storeURL)
        let migrator = CoreDataMigrator(storeURL: storeURL, bundle: bundle, modelName: "TestMigrationModel", storeType: .sql(filename: filename))

        do {
            let success = try migrator.migrate()
            XCTAssertTrue(success)
        } catch let error {
            XCTFail("Got error: \(error)")
        }
    }

    func testMigratePopulatedDataStoreFromOriginalVersion() throws {
        let original = knownVersions[0]
        let (storeURL, filename, oldContainer) = try persistentStoreContainer(version: original)
        urlsToCleanup.append(storeURL)
        prepareContainer(oldContainer)

        let migrator = CoreDataMigrator(storeURL: storeURL, bundle: bundle, modelName: "TestMigrationModel", storeType: .sql(filename: filename))

        do {
            let success = try migrator.migrate()
            XCTAssertTrue(success)

            let (url, _, container) = try persistentStoreContainer(version: knownVersions.last!, filename: filename)
            urlsToCleanup.append(url)
            guard let entityDescription = NSEntityDescription.entity(forEntityName: "MigratedEntity", in: container.viewContext) else {
                XCTFail("Couldn't get MigratedEntity NSEntityDescription.")
                return
            }

            let fetch = NSFetchRequest<NSFetchRequestResult>()
            fetch.entity = entityDescription
            let results = try container.viewContext.fetch(fetch)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual((results.first as? NSManagedObject)?.value(forKey: "convertedProperty") as? String, "1234")
        } catch let error {
            XCTFail("Got error: \(error)")
        }
    }


    // MARK: - Private functions

    private func persistentStoreContainer(version: String, filename: String? = nil) throws -> (onDiskURL: URL, filename: String, container: NSPersistentContainer) {
        let modelURL = try XCTUnwrap(bundle.url(forResource: version, withExtension: "mom", subdirectory: "TestMigrationModel.momd"), "Unable to load \(version).mom")
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        let filenameToUse = filename ?? "\(UUID().uuidString).sqlite"
        let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(filenameToUse)
        let container = NSPersistentContainer(name: "CoreDataMigratorTests", managedObjectModel: model)
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        container.loadPersistentStores { desc, err in
            XCTAssertEqual(desc, container.persistentStoreDescriptions.first)
            XCTAssertNil(err)
        }
        return (storeURL, filenameToUse, container)
    }

    private func prepareContainer(_ container: NSPersistentContainer) {
        let context = container.viewContext
        let managedObject = NSEntityDescription.insertNewObject(forEntityName: "EntityToMigrate", into: context)
        managedObject.setPrimitiveValue(1234, forKey: "oldProperty")
        do {
            try context.save()
        } catch let error {
            XCTFail("Got error: \(error)")
        }
    }
}

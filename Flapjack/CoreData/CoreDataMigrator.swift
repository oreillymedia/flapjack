//
//  CoreDataMigrator.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 11/30/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData
#if !COCOAPODS
import Flapjack
#endif

class CoreDataMigrator: Migrator {
    private typealias VersionModelPair = (version: String, model: NSManagedObjectModel)

    private let storeURL: URL
    private let compiledModelURL: URL
    private let storeType: CoreDataAccess.StoreType
    private var tempURL: URL?
    private var storeExists: Bool {
        return FileManager.default.fileExists(atPath: storeURL.path)
    }
    private lazy var versionInfo: VersionInfo? = {
        guard FileManager.default.fileExists(atPath: compiledModelURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: compiledModelURL.appendingPathComponent("VersionInfo.plist", isDirectory: false))
            return try PropertyListDecoder().decode(VersionInfo.self, from: data)
        } catch let error {
            Logger.error("\(error)")
            return nil
        }
    }()
    private lazy var currentStoreMeta: [String: Any]? = {
        guard storeExists else { return nil }
        do {
            return try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType.coreDataType, at: storeURL, options: nil)
        } catch let error {
            Logger.error("\(error)")
            return nil
        }
    }()

    init(storeURL: URL, compiledModelURL: URL, storeType: CoreDataAccess.StoreType) {
        self.storeURL = storeURL
        self.compiledModelURL = compiledModelURL
        self.storeType = storeType
    }


    // MARK: Migrator

    var storeIsUpToDate: Bool {
        guard let currentStoreMeta = currentStoreMeta else { return false }
        let model = NSManagedObjectModel(contentsOf: compiledModelURL)
        return model?.isConfiguration(withName: nil, compatibleWithStoreMetadata: currentStoreMeta) ?? false
    }

    func migrate() throws -> Bool {
        // If no file exists at the store URL, we definitely don't need to try and migrate, as Core
        //   Data probably hasn't even been initialized yet. If we're already up-to-date, return nothing.
        guard storeExists, !storeIsUpToDate else { return false }

        try createTempFolder()
        defer {
            if let url = tempURL {
                do {
                    try FileManager.default.removeItem(at: url)
                    Logger.verbose("Successfully removed temporary store file.")
                } catch let error {
                    // This is a non-critical error.
                    Logger.warning("Couldn't remove temporary store file: \(error.localizedDescription)")
                }
            }
        }

        // If we don't have any models to migrate to, don't do it.
        let modelsToMigrate = relevantModelVersions
        guard !modelsToMigrate.isEmpty else { return false }
        if let first = modelsToMigrate.first?.version, let last = modelsToMigrate.last?.version {
            Logger.verbose("Core Data: need to migrate from version \(first) to version \(last).")
        }

        var currentURLStore = storeURL
        do {
            // Iterate through each model that needs to be migrated to
            for idx in 0..<(modelsToMigrate.count - 1) {
                let source = modelsToMigrate[idx]
                let destination = modelsToMigrate[idx + 1]

                Logger.verbose("Migrating to \(destination.version).")
                let migratedURL = try migrateStore(at: currentURLStore, from: source, to: destination)
                if idx > 0 {
                    try removeStore(at: currentURLStore)
                }
                currentURLStore = migratedURL
            }
        } catch let error as MigratorError {
            throw error
        } catch let error {
            throw MigratorError.proceduralError(error)
        }

        // Remove the old store, put the new one in its place.
        do {
            try removeStore(at: storeURL)
            try FileManager.default.moveItem(at: currentURLStore, to: storeURL)
            Logger.verbose("Successfully migrated Core Data store and moved to \(storeURL)")
        } catch let error {
            Logger.warning("Successfully migrated Core Data store, but wasn't able to move to \(storeURL): \(error.localizedDescription)")
            throw MigratorError.cleanupError(error)
        }

        return true
    }


    // MARK: Private properties and functions

    /**
     The current managed object model as it appears on-disk.
     */
    private var currentModel: NSManagedObjectModel? {
        guard let currentMeta = currentStoreMeta else { return nil }
        return NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: currentMeta)
    }

    /**
     Contains the string name and `NSManagedObjectModel` of each model version we're dealing with.
     If this array only contains one member, it's the latest version of the data set, and no migrations
     are needed.
     */
    private var relevantModelVersions: [VersionModelPair] {
        guard let currentModel = currentModel, let versionInfo = versionInfo else { return [] }

        var isCurrentFoundInList = false
        return versionInfo.allVersions.compactMap { name in
            let url = compiledModelURL.appendingPathComponent("\(name).mom")
            let model = NSManagedObjectModel(contentsOf: url)
            // This essentially adds our current model version as the first object in the array, and then
            //   adds each subsequent newer version to the array as well (we never try migrating to an
            //   older model version).
            isCurrentFoundInList = isCurrentFoundInList || model == currentModel
            guard let foundModel = model, isCurrentFoundInList else { return nil }
            return (name, foundModel)
        }
    }

    /// Creates a temporary folder to do all of these migrations; dirname is simply a UUID string.
    private func createTempFolder() throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(NSUUID().uuidString, isDirectory: true)
        self.tempURL = tempURL
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
    }

    private func removeStore(at url: URL) throws {
        let storePath = storeURL.path
        let manager = FileManager.default
        try manager.removeItem(atPath: "\(storePath)-wal")
        try manager.removeItem(atPath: "\(storePath)-shm")
        try manager.removeItem(atPath: storePath)
    }

    /**
     The workhorse method of the class. Creates a temporary destination file based on a random UUID
     string, fetches an explicit (if it exists and the class name is referenced in the Core Data
     model file) or an inferred mapping model, and then asks `NSMigrationManager` to perform the
     actual migration.

     - parameter url: The URL of the store to perform the migration upon.
     - parameter source: The source model pair (containing version name and the model itself).
     - parameter destination: The destination model pair (containing version name and the model itself).
     - returns: The URL to the newly-migrated store, or `nil` if an error occurred.
     */
    private func migrateStore(at url: URL, from source: VersionModelPair, to destination: VersionModelPair) throws -> URL {
        // Create a temporary URL at which to store the newly-migrated model file. We need this and this
        //   should never really fail (since tempURL ought to be populated by the time we get here).
        guard let destinationURL = tempURL?.appendingPathComponent(NSUUID().uuidString.appending(".sql")) else {
            throw MigratorError.diskPreparationError
        }

        // Get either a specific mapping model class _or_ an inferred, default-behavior mapping
        //   model. Any specific mapping model classes are generated from (and referred to in) the
        //   Core Data schema file.
        var mappingModel = NSMappingModel(from: nil, forSourceModel: source.model, destinationModel: destination.model)
        if mappingModel == nil {
            Logger.verbose("Inferring mapping model from source model \(source.version) to destination model \(destination.version).")
            mappingModel = try NSMappingModel.inferredMappingModel(forSourceModel: source.model, destinationModel: destination.model)
        } else {
            Logger.verbose("Found concrete mapping model from source model \(source.version) to destination model \(destination.version).")
        }

        // Setup a migration manager and fire off the actual migration.
        let migrationManager = NSMigrationManager(sourceModel: source.model, destinationModel: destination.model)
        try migrationManager.migrateStore(from: url, sourceType: storeType.coreDataType, options: nil, with: mappingModel, toDestinationURL: destinationURL, destinationType: storeType.coreDataType, destinationOptions: nil)
        return destinationURL
    }
}


private struct VersionInfo: Codable {
    var currentVersionName: String = ""
    var versionHashes: [String: [String: Data]] = [:]

    var allVersions: [String] {
        return versionHashes.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    enum CodingKeys: String, CodingKey {
        case currentVersionName = "NSManagedObjectModel_CurrentVersionName"
        case versionHashes = "NSManagedObjectModel_VersionHashes"
    }
}
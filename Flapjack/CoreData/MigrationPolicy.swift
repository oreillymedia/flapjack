//
//  MigrationPolicy.swift
//  FlapjackCoreData
//
//  Created by Ben Kreeger on 12/14/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData

/**
 A common subclass for "hooking in" to the existing Core Data APIs for handling mapping model migrations in order to
 make them Swift-y and much easier to deal with.

 Subclasses must override the `migrations` property, where keys should be the _names_ of the mappings (like
 `PlaylistToPlaylist`), and the _values_ should be the properties vending functions to run.

 See the docstring for `migrations` for more information.
 */
@objc
public class MigrationPolicy: NSEntityMigrationPolicy {
    public typealias MigrationOperation = (_ manager: NSMigrationManager, _ source: NSManagedObject, _ destination: NSManagedObject?) throws -> Void

    @objc
    override public func createDestinationInstances(forSource sourceInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        if !migrationsWithoutNecessaryCreationStep.contains(mapping.name) {
            try super.createDestinationInstances(forSource: sourceInstance, in: mapping, manager: manager)
        }

        let destination = manager.destinationObject(in: mapping.name, source: sourceInstance)
        let migrationOperation = migrations[mapping.name]
        try migrationOperation?(manager, sourceInstance, destination)

        if let destination = destination, migrationsWithoutNecessaryCreationStep.contains(mapping.name) {
            manager.associate(sourceInstance: sourceInstance, withDestinationInstance: destination, for: mapping)
        }
    }

    /**
     Subclasses should override this method and return a dictionary whose keys are mapped directly
     to Core Data Mapping Model entity mappings (like `PlaylistToPlaylist`), and whose values are
     properties vending functions to run (conforming to the `MigrationOperation` typealias).
     */
    public var migrations: [String: MigrationOperation] {
        return [:]
    }

    /**
     For second-tier mappings (to be run after the initial mapping runs for an entity), subclasses should override
     this property and define their names as the return value to this function. This tells the parent whether or not
     it needs to _create_ the entities in the destination context (second-tier mappings should not create entities
     otherwise duplication of entities will occur).
     */
    public var migrationsWithoutNecessaryCreationStep: [String] {
        return []
    }
}

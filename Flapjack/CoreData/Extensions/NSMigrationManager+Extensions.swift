//
//  NSMigrationManager+Extensions.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 12/14/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData
#if !COCOAPODS
import Flapjack
#endif

public extension NSMigrationManager {
    /// A convenience enum for picking either the source managed object context or the destination one.
    enum Layer {
        /// The original managed object context (unmigrated).
        case source
        /// The new managed object context (to which migrated structure and objects are applied).
        case destination
    }

    /**
     A wrapper for calling `destinationInstances(forEntityMappingName:sourceInstances:)` with a single source, expecting
     a single result.

     - parameter mapping: The name of the mapping in the mapping model currently being run.
     - parameter source: The version of the managed object from the original context.
     - returns: The object belonging to the destination context, if found.
     */
    func destinationObject(in mapping: String, source: NSManagedObject) -> NSManagedObject? {
        let objects = destinationInstances(forEntityMappingName: mapping, sourceInstances: [source])
        return objects.first
    }

    /**
     Executes a fetch request in the requested context for objects matching a given entity name and a set of attributes.

     - parameter name: The entity name of the objects to be returned.
     - parameter attributes: A dictionary of key-value query constraints to apply to the lookup.
     - parameter layer: The context to fetch from; either `.source` or `.destination`.
     - returns: An array of objects found; if none were found or an error occurred, this is an empty array.
     */
    func findEntities(_ name: String, attributes: [String: Any], from layer: Layer) -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: name)
        request.predicate = NSCompoundPredicate(andPredicateFrom: attributes)
        do {
            switch layer {
            case .source:
                return try sourceContext.fetch(request)
            case .destination:
                return try destinationContext.fetch(request)
            }
        } catch let error {
            Logger.error(error.localizedDescription)
            return []
        }
    }
}

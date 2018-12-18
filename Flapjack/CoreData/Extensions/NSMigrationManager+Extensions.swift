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

extension NSMigrationManager {
    enum Layer {
        case source
        case destination
    }

    func destinationObject(in mapping: String, source: NSManagedObject) -> NSManagedObject? {
        let objects = destinationInstances(forEntityMappingName: mapping, sourceInstances: [source])
        return objects.first
    }

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

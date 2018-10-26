//
//  NSManagedObjectContext+DataContext.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext: DataContext {
    public func perform(_ operation: @escaping (_ context: DataContext) -> Void) {
        self.perform { operation(self) }
    }

    public func performSync(_ operation: @escaping (_ context: DataContext) -> Void) {
        self.performAndWait { operation(self) }
    }

    public func refresh<T: DataObject>(_ object: T) {
        guard let object = object as? NSManagedObject else {
            return
        }
        refresh(object, mergeChanges: false)
    }

    public func persist() -> DataContextError? {
        guard hasChanges else {
            return nil
        }
        return forcePersist()
    }

    public func persistOrRollback() -> Bool {
        if self.persist() == nil {
            return true
        }
        Logger.warning("Rolling back Core Data store.")
        rollback()
        return false
    }

    public func forcePersist() -> DataContextError? {
        let printableAddress = Unmanaged<AnyObject>.passUnretained(self).toOpaque()

        do {
            try self.save()
            return nil
        } catch let error {
            Logger.error("Error saving context \(printableAddress): \(error)")
            return .saveError(error)
        }
    }


    // MARK: Collection fetch operations

    public func objects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T] {
        do {
            return try fetchObjects(ofType: type, predicate: predicate, prefetch: prefetch ?? [], sortBy: sorters, limit: limit)
        } catch let error {
            Logger.error("Error fetching objects \(type) with predicate \(String(describing: predicate)): \(error.localizedDescription)")
            return []
        }
    }

    public func objects<T: DataObject>(ofType type: T.Type, objectIDs: [DataObjectID], prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T] {
        return objects(ofType: type, attributes: ["self": objectIDs], prefetch: prefetch, sortBy: sorters, limit: limit)
    }

    public func numberOfObjects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?) -> Int {
        let request = fetchRequest(for: type, predicate: predicate)
        do {
            return try count(for: request)
        } catch {
            Logger.error("Error fetching count of \(type) with predicate \(String(describing: predicate)): \(error.localizedDescription)")
            return 0
        }
    }


    // MARK: Single fetch operations

    public func object<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?, sortBy sorters: [SortDescriptor]) -> T? {
        do {
            return try fetchObject(ofType: type, predicate: predicate, prefetch: prefetch ?? [], sortBy: sorters)
        } catch let error {
            Logger.error("Error fetching objects \(type) with predicate \(String(describing: predicate)): \(error.localizedDescription)")
            return nil
        }
    }

    public func object<T: DataObject>(ofType type: T.Type, objectID: DataObjectID) -> T? {
        guard let objectID = objectID as? NSManagedObjectID else {
            return nil
        }
        if let found = registeredObject(for: objectID), !found.isDeleted, let cast = found as? T {
            return cast
        }

        do {
            let found = try existingObject(with: objectID)
            guard !found.isDeleted else {
                return nil
            }
            return found as? T
        } catch let error {
            Logger.error("Error finding object by ID \(objectID): \(error)")
            return nil
        }
    }

    public func refetch<T: DataObject>(_ dataObject: T) -> T? {
        guard let dataObject = dataObject as? NSManagedObject else {
            return nil
        }
        if let found = registeredObject(for: dataObject.objectID), !found.isDeleted, let cast = found as? T {
            return cast
        }
        do {
            let found = try existingObject(with: dataObject.objectID)
            guard !found.isDeleted else {
                return nil
            }
            return found as? T
        } catch let error {
            Logger.error("Error finding object by ID \(dataObject.objectID): \(error)")
            return nil
        }
    }


    // MARK: Creation operations

    // swiftlint:disable force_cast
    public func create<T: DataObject>(_ type: T.Type) -> T {
        return NSEntityDescription.insertNewObject(forEntityName: type.representedName, into: self) as! T
    }

    public func create<T: DataObject>(_ type: T.Type, attributes: DataContext.Attributes) -> T {
        let created = create(type)
        attributes.forEach { (created as! NSManagedObject).setValue($1, forKey: $0) }
        return created
    }
    // swiftlint:enable force_cast


    // MARK: Destruction operations

    public func destroy<T: DataObject>(_ object: T?) {
        guard let object = object as? NSManagedObject else {
            return
        }
        self.delete(object)
    }

    public func destroy<T: DataObject>(_ objects: [T]) {
        objects.forEach { self.destroy($0) }
    }


    // MARK: Fetch request helpers

    public func fetchRequest<T: DataObject>(for type: T.Type) -> NSFetchRequest<T> {
        return NSFetchRequest<T>(entityName: type.representedName)
    }

    public func fetchRequest<T: DataObject>(for type: T.Type, predicate: NSPredicate?) -> NSFetchRequest<T> {
        let request = fetchRequest(for: type)
        request.predicate = predicate
        return request
    }

    public func fetchRequest<T: DataObject>(for type: T.Type, predicate: NSPredicate?, prefetch: [String], sortBy sorters: [SortDescriptor], limit: Int?) -> NSFetchRequest<T> {
        let request = fetchRequest(for: type, predicate: predicate)
        if sorters.isEmpty {
            request.sortDescriptors = type.defaultSorters.asNSSortDescriptors
        } else {
            request.sortDescriptors = sorters.asNSSortDescriptors
        }
        request.relationshipKeyPathsForPrefetching = prefetch
        request.fetchBatchSize = 50
        if let limit = limit, limit > 0 {
            request.fetchLimit = limit
        }
        return request
    }


    // MARK: Private functions

    private func fetchObject<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String], sortBy sorters: [SortDescriptor]) throws -> T? {
        let preregistered: T? = registeredObjects.first { obj in
            guard !obj.isFault, !obj.isDeleted, let obj = obj as? T else {
                return false
            }
            if let predicate = predicate {
                return predicate.evaluate(with: obj)
            }
            return true
        } as? T

        if let found = preregistered {
            return found
        }

        return try fetchObjects(ofType: type, predicate: predicate, prefetch: prefetch, sortBy: sorters, limit: 1).first
    }

    private func fetchObjects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String], sortBy sorters: [SortDescriptor], limit: Int?) throws -> [T] {
        let request = fetchRequest(for: type, predicate: predicate, prefetch: prefetch, sortBy: sorters, limit: limit)
        return try fetch(request)
    }
}

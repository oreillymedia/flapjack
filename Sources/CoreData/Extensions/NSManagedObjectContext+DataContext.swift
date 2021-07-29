//
//  NSManagedObjectContext+DataContext.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData
#if !COCOAPODS
import Flapjack
#endif

extension NSManagedObjectContext: DataContext {
    /**
     Performs an operation against this context on an isolated queue.

     - parameter operation: The closure containing the operation(s) to perform; will be passed the background-thread
                            `NSManagedObjectContext` as a `DataContext`.
     */
    public func perform(_ operation: @escaping (_ context: DataContext) -> Void) {
        self.perform { operation(self) }
    }

    /**
     Performs an operation against this context on an isolated queue, but blocks the calling thread while doing so.
     Wraps `NSManagedObjectContext.performAndWait(_:)`.

     - parameter operation: The closure containing the operation(s) to perform; will be passed the background-thread
                            `NSManagedObjectContext` as a `DataContext`.
     */
    public func performSync(_ operation: @escaping (_ context: DataContext) -> Void) {
        self.performAndWait { operation(self) }
    }

    /**
     Goes back to this context's backing store to get a new copy of the requested object (which dumps its
     potentially-cached version).

     - parameter object: The model object to be refreshed. Must be an `NSManagedObject` otherwise this is a no-op.
     */
    public func refresh<T: DataObject>(_ object: T) {
        guard let object = object as? NSManagedObject else {
            return
        }
        refresh(object, mergeChanges: false)
    }

    /**
     Saves any pending changes to our backing store. If no changes are detected, this method is a no-op.

     - returns: An error if one occurred while saving.
     */
    public func persist() -> DataContextError? {
        guard hasChanges, isDirty else {
            return nil
        }
        return forcePersist()
    }

    /**
     Save any pending changes to our backing store, but if we encounter an error, attempts a rollback and returns
     whether or not the save succeeded.

     - returns: `true` if the persist operation was successful; `false` if a rollback happened as a result of a failure.
     */
    public func persistOrRollback() -> Bool {
        if self.persist() == nil {
            return true
        }
        Logger.error("Rolling back Core Data store.")
        rollback()
        return false
    }

    /**
     Save any pending changes to our backing store, regardless of whether or not unsaved changes exist. Guarantees a
     round trip to the backing store.

     - returns: An error if one occurred while saving.
     */
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

    /**
     Queries for a collection of objects matching the given `type`, and optional `predicate`, with an optional
     `prefetch` parameter for eagerly fetching related records, and an optional `limit` parameter for restricting the
     count of matches returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter predicate: An optional query to be applied to the lookup.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - returns: An array of any found objects. If none are found, an empty array is returned.
     */
    public func objects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?, sortBy sorters: [Flapjack.SortDescriptor], limit: Int?) -> [T] {
        do {
            return try fetchObjects(ofType: type, predicate: predicate, prefetch: prefetch ?? [], sortBy: sorters, limit: limit)
        } catch let error {
            Logger.error("Error fetching objects \(type) with predicate \(String(describing: predicate)): \(error.localizedDescription)")
            return []
        }
    }

    /**
     Queries for a collection of objects matching the given `type` and database `objectIDs`, with an optional `prefetch`
     parameter for eagerly fetching related records, and an optional `limit` parameter for restricting the count of
     records returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter objectIDs: The unique database object identifiers of the objects to be retrieved.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - returns: An array of objects matching the `DataObjectID`s given, if any. If none are found, an empty array is
                returned.
     */
    public func objects<T: DataObject>(ofType type: T.Type, objectIDs: [DataObjectID], prefetch: [String]?, sortBy sorters: [Flapjack.SortDescriptor], limit: Int?) -> [T] {
        return objects(ofType: type, attributes: ["self": objectIDs], prefetch: prefetch, sortBy: sorters, limit: limit)
    }

    /**
     Queries for the count of objects matching a given predicate. Provides an optimized query for _just_ returning an
     integer count instead of an entire record set.

     - parameter type: The specific type of `DataObject` to be queried for.
     - parameter predicate: An optional query to be applied to the lookup.
     - returns: An integer representing the number of objects that match the query.
     */
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

    /**
     Queries for a single object matching the given `type`, and optional `predicate`, with an optional `prefetch`
     parameter for eagerly fetching related records. If multiple records match the given criteria, `sorters` will be
     used to sort the results, and the first object will be returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter predicate: An optional query to be applied to the lookup.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - returns: A matched object, if found. If multiple records match the given criteria, `sorters` will be used to sort
                the results, and the first object will be returned.
     */
    public func object<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?, sortBy sorters: [Flapjack.SortDescriptor]) -> T? {
        do {
            return try fetchObject(ofType: type, predicate: predicate, prefetch: prefetch ?? [], sortBy: sorters)
        } catch let error {
            Logger.error("Error fetching objects \(type) with predicate \(String(describing: predicate)): \(error.localizedDescription)")
            return nil
        }
    }

    /**
     Queries for a single object matching the given `type`, and database `objectID`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter objectIDs: The unique database object identifier of the object to be retrieved.
     - returns: A matched object, if found.
     */
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

    /**
     Queries for an object that exists in this context, and then returns a refreshed version of it.

     - parameter dataObject: The object to be refreshed.
     - returns: A refreshed object, if it still exists in the persistent store.
     */
    public func refetch<T: DataObject>(_ dataObject: T) -> T? {
        guard let dataObject = dataObject as? NSManagedObject else {
            return nil
        }
        return object(ofType: T.self, objectID: dataObject.objectID)
    }


    // MARK: Creation operations

    /**
     Creates and returns a new entity in our context (without fully committing it to our backing store).

     - parameter type: The type of the `DataObject` to create.
     - returns: A newly added model, ready for modification and then later persistence to our context.
     */
    public func create<T: DataObject>(_ type: T.Type) -> T {
        // swiftlint:disable:next force_cast
        return NSEntityDescription.insertNewObject(forEntityName: type.representedName, into: self) as! T
    }

    /**
     Creates a new entity in our context (without fully committing it to our backing store) and assigns it a series of
     attributes as properties.

     - parameter type: The type of the `DataObject` to create.
     - parameter attributes: The attributes to assign to the new instance.
     - returns: A newly added model, ready for modification and then later persistence to our context.
     */
    public func create<T: DataObject>(_ type: T.Type, attributes: DataContext.Attributes) -> T {
        let created = create(type)
        // swiftlint:disable:next force_cast
        attributes.forEach { (created as! NSManagedObject).setValue($1, forKey: $0) }
        return created
    }


    // MARK: Destruction operations

    /**
     Removes an object from our backing store.

     - parameter object: The object to remove from our backing store.
     */
    public func destroy<T: DataObject>(object: T?) {
        guard let object = object as? NSManagedObject else {
            return
        }
        self.delete(object)
    }


    // MARK: Fetch request helpers

    /**
     Generates an `NSFetchRequest` for manual fetching operations based on a number of parameters passed in. Defaults to
     a `fetchBatchSize` of 50.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter predicate: An optional query to be applied to the fetch request.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the fetch request, if desired.
     - parameter limit: An optional limit to be applied to the fetch request.
     - returns: A formulated `NSFetchRequest` with the given parameters.
     */
    public func fetchRequest<T: DataObject>(for type: T.Type, predicate: NSPredicate? = nil, prefetch: [String] = [], sortBy sorters: [Flapjack.SortDescriptor] = [], limit: Int? = nil) -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: type.representedName)
        request.predicate = predicate
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

    /// Similar to `hasChanges`, but returns false if any updates result in no actual changes to the data.
    private var isDirty: Bool {
        return !insertedObjects.isEmpty || !deletedObjects.isEmpty || updatedObjects.contains(where: { $0.hasPersistentChangedValues })
    }

    private func fetchObject<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String], sortBy sorters: [Flapjack.SortDescriptor]) throws -> T? {
        let preregistered: T? = registeredObjects.sortedArray(using: sorters).first { obj in
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

    private func fetchObjects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String], sortBy sorters: [Flapjack.SortDescriptor], limit: Int?) throws -> [T] {
        let request = fetchRequest(for: type, predicate: predicate, prefetch: prefetch, sortBy: sorters, limit: limit)
        let results = try fetch(request)

        // To keep Core Data type info out of Flapjack core, `DataObject` doesn't explicitly conform to
        //   `NSFetchRequestResult`, although if `NSManagedObject`s conform to `DataObject`, everything should work.
        if results.isEmpty {
            return []
        } else if let castResults = results as? [T] {
            return castResults
        } else {
            throw DataContextError.fetchTypeError(String(describing: T.self), results.first)
        }
    }
}

//
//  DataContext.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation


// MARK: - DataContext

/**
 One of the two prominently-used objects in Flapjack, the `DataContext` protocol (and those that conform to it) preside
 over a modifiable and searchable "context" of model objects lifted from a backing store.
 */
public protocol DataContext {
    /// A generic alias for searchable criteria (this often gets converted into an `NSPredicate` under the hood).
    typealias Attributes = [String: Any]

    /**
     Asks the context to perform an operation against itself on an isolated thread or queue.

     - parameter operation: The closure containing the operation(s) to perform; should be passed this context object.
     */
    func perform(_ operation: @escaping (_ context: DataContext) -> Void)

    /**
     Asks the context to perform an operation against itself on an isolated thread or queue, but to block the calling
     thread while doing so.

     - parameter operation: The closure containing the operation(s) to perform; should be passed this context object.
     */
    func performSync(_ operation: @escaping (_ context: DataContext) -> Void)

    /**
     Asks the context to go through any unsaved modifications and do anything short of saving them to the disk; this may
     include giving new objects unique identifiers, establishing relationships in an object graph, etc.
     */
    func processPendingChanges()

    /**
     Asks the context to go back to its backing store to get a new copy of the requested object (and thereby dump its
     potentially-cached version).

     - parameter object: The model object to be refreshed.
     */
    func refresh<T: DataObject>(_ object: T)

    /**
     Asks the context to save any pending changes to its backing store. If no changes are detected, this method should
     not invoke an unnecessary save.

     - returns: An error if one occurred while saving.
     */
    @discardableResult
    func persist() -> DataContextError?

    /**
     Asks the context to save any pending changes to its backing store, but if it encounters an error, it should attempt
     a rollback and return whether or not the save succeeded.

     - returns: `true` if the persist operation was successful; `false` if it had to roll back.
     */
    @discardableResult
    func persistOrRollback() -> Bool

    /**
     Asks the context to save any pending changes to its backing store, regardless of whether or not unsaved changes
     exist. Should guarantee a round trip to the backing store.

     - returns: An error if one occurred while saving.
     */
    @discardableResult
    func forcePersist() -> DataContextError?


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
    func objects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T]

    /**
     Queries for a collection of objects matching the given `type`, and optional `attributes`, with an optional
     `prefetch` parameter for eagerly fetching related records, and an optional `limit` parameter for restricting the
     count of matches returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - returns: An array of any found objects. If none are found, an empty array is returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T]

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
    func objects<T: DataObject>(ofType type: T.Type, objectIDs: [DataObjectID], prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T]

    /**
     Queries for a collection of objects matching the given `type` and `primaryKeys`, with an optional `prefetch`
     parameter for eagerly fetching related records, and an optional `limit` parameter for restricting the count of
     records returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter primaryKeys: The unique primary keys of the objects to be retrieved.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - returns: An array of objects matching the `DataObjectID`s given, if any. If none are found, an empty array is
                returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, primaryKeys: [PrimaryKey], prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T]

    /**
     Queries for the count of objects matching a given predicate. This is meant to provide an optimized query for _just_
     returning an integer count instead of an entire record set.

     - parameter type: The specific type of `DataObject` to be queried for.
     - parameter predicate: An optional query to be applied to the lookup.
     - returns: An integer representing the number of objects that match the query.
     */
    func numberOfObjects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?) -> Int


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
    func object<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?, sortBy sorters: [SortDescriptor]) -> T?

    /**
     Queries for a single object matching the given `type`, and optional `attributes`, with an optional `prefetch`
     parameter for eagerly fetching related records. If multiple records match the given criteria, `sorters` will be
     used to sort the results, and the first object will be returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - returns: A matched object, if found. If multiple records match the given criteria, `sorters` will be used to sort
     the results, and the first object will be returned.
     */
    func object<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?, sortBy sorters: [SortDescriptor]) -> T?

    /**
     Queries for a single object matching the given `type`, and database `objectID`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter objectIDs: The unique database object identifier of the object to be retrieved.
     - returns: A matched object, if found.
     */
    func object<T: DataObject>(ofType type: T.Type, objectID: DataObjectID) -> T?

    /**
     Queries for an object that exists in this context, and then returns a refreshed version of it.

     - parameter dataObject: The object to be refreshed.
     - returns: A refreshed object, if it still exists in the persistent store.
     */
    func refetch<T: DataObject>(_ dataObject: T) -> T?


    // MARK: Creation operations

    /**
     Creates and returns a new entity in the context (without fully committing it to the backing store).

     - parameter type: The type of the `DataObject` to create.
     - returns: A newly added model, ready for modification and then later persistence to the context.
     */
    func create<T: DataObject>(_ type: T.Type) -> T

    /**
     Creates a new entity in the context (without fully committing it to the backing store) and assigns it a series of
     attributes as properties.

     - parameter type: The type of the `DataObject` to create.
     - parameter attributes: The attributes to assign to the new instance.
     - returns: A newly added model, ready for modification and then later persistence to the context.
     */
    func create<T: DataObject>(_ type: T.Type, attributes: Attributes) -> T


    // MARK: Destruction operations


    func destroy<T: DataObject>(object: T?)

    /**
     Removes an array of objects from the backing store.

     - parameter objects: The objects to remove from the backing store.
     */
    func destroy<T: DataObject>(objects: [T])
}


// MARK: - DataContext protocol extension

public extension DataContext {

    // MARK: Collection fetch operations

    /**
     Queries for a collection of objects matching the given `type`.

     - parameter type: The specific type of `DataObject` to be returned.
     - returns: An array of any found objects. If none are found, an empty array is returned.
     */
    func objects<T: DataObject>(ofType type: T.Type) -> [T] {
        return objects(ofType: type, predicate: nil, prefetch: nil, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type` and optional `predicate`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter predicate: An optional query to be applied to the lookup.
     - returns: An array of any found objects. If none are found, an empty array is returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?) -> [T] {
        return objects(ofType: type, predicate: predicate, prefetch: nil, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type`, and optional `predicate`, with an optional
     `prefetch` parameter for eagerly fetching related records.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter predicate: An optional query to be applied to the lookup.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - returns: An array of any found objects. If none are found, an empty array is returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?) -> [T] {
        return objects(ofType: type, predicate: predicate, prefetch: prefetch, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type` and optional `attributes`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - returns: An array of any found objects. If none are found, an empty array is returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, attributes: Attributes) -> [T] {
        return objects(ofType: type, attributes: attributes, prefetch: nil, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type`, and optional `attributes`, with an optional
     `prefetch` parameter for eagerly fetching related records.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - returns: An array of any found objects. If none are found, an empty array is returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?) -> [T] {
        return objects(ofType: type, attributes: attributes, prefetch: prefetch, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type`, and optional `attributes`, with an optional
     `prefetch` parameter for eagerly fetching related records, and an optional `limit` parameter for restricting the
     count of matches returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - returns: An array of any found objects. If none are found, an empty array is returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T] {
    return objects(ofType: type, predicate: NSCompoundPredicate(andPredicateFrom: attributes), prefetch: prefetch, sortBy: sorters, limit: limit)
    }

    /**
     Queries for a collection of objects matching the given `type` and database `objectIDs`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter objectIDs: The unique database object identifiers of the objects to be retrieved.
     - returns: An array of objects matching the `DataObjectID`s given, if any. If none are found, an empty array is
                returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, objectIDs: [DataObjectID]) -> [T] {
        return objects(ofType: type, objectIDs: objectIDs, prefetch: nil, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type` and database `objectIDs`, with an optional `prefetch`
     parameter for eagerly fetching related records.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter objectIDs: The unique database object identifiers of the objects to be retrieved.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - returns: An array of objects matching the `DataObjectID`s given, if any. If none are found, an empty array is
                returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, objectIDs: [DataObjectID], prefetch: [String]?) -> [T] {
        return objects(ofType: type, objectIDs: objectIDs, prefetch: prefetch, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type` and `primaryKeys`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter primaryKeys: The unique primary keys of the objects to be retrieved.
     - returns: An array of objects matching the `DataObjectID`s given, if any. If none are found, an empty array is
                returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, primaryKeys: [PrimaryKey]) -> [T] {
        return objects(ofType: type, primaryKeys: primaryKeys, prefetch: nil, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type` and `primaryKeys`, with an optional `prefetch`
     parameter for eagerly fetching related records.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter primaryKeys: The unique primary keys of the objects to be retrieved.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - returns: An array of objects matching the `DataObjectID`s given, if any. If none are found, an empty array is
                returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, primaryKeys: [PrimaryKey], prefetch: [String]?) -> [T] {
        return objects(ofType: type, primaryKeys: primaryKeys, prefetch: prefetch, sortBy: [], limit: 0)
    }

    /**
     Queries for a collection of objects matching the given `type` and `primaryKeys`, with an optional `prefetch`
     parameter for eagerly fetching related records, and an optional `limit` parameter for restricting the count of
     records returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter primaryKeys: The unique primary keys of the objects to be retrieved.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - returns: An array of objects matching the `DataObjectID`s given, if any. If none are found, an empty array is
                returned.
     */
    func objects<T: DataObject>(ofType type: T.Type, primaryKeys: [PrimaryKey], prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T] {
        guard !primaryKeys.isEmpty else {
            return []
        }
        return objects(ofType: type, attributes: [type.primaryKeyPath: primaryKeys], prefetch: prefetch, sortBy: sorters, limit: limit)
    }


    // MARK: Single fetch operations

    /**
     Queries for a single object matching the given `type` and optional `predicate`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter predicate: An optional query to be applied to the lookup.
     - returns: A matched object, if found. If multiple records match the given criteria, `sorters` will be used to sort
                the results, and the first object will be returned.
     */
    func object<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?) -> T? {
        return object(ofType: type, predicate: predicate, prefetch: nil, sortBy: [])
    }

    /**
     Queries for a single object matching the given `type` and optional `attributes`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - returns: A matched object, if found. If multiple records match the given criteria, `sorters` will be used to sort
                the results, and the first object will be returned.
     */
    func object<T: DataObject>(ofType type: T.Type, attributes: Attributes) -> T? {
        return object(ofType: type, attributes: attributes, prefetch: nil, sortBy: [])
    }

    /**
     Queries for a single object matching the given `type`, and optional `attributes`, with an optional `prefetch`
     parameter for eagerly fetching related records. If multiple records match the given criteria, `sorters` will be
     used to sort the results, and the first object will be returned.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - parameter prefetch: An array of keypaths for relationships to be eagerly-fetched, if desired.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - returns: A matched object, if found. If multiple records match the given criteria, `sorters` will be used to sort
                the results, and the first object will be returned.
     */
    func object<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?, sortBy sorters: [SortDescriptor]) -> T? {
        return object(ofType: type, predicate: NSCompoundPredicate(andPredicateFrom: attributes), prefetch: prefetch, sortBy: sorters)
    }

    /**
     Queries for a single object matching the given `type` and `primaryKey`.

     - parameter type: The specific type of `DataObject` to be returned.
     - parameter primaryKey: The unique primary key of the object to be retrieved.
     - returns: A matched object, if found.
     */
    func object<T: DataObject>(ofType type: T.Type, primaryKey: PrimaryKey?) -> T? {
        guard let primaryKey = primaryKey else {
            return nil
        }
        return object(ofType: type, attributes: [type.primaryKeyPath: primaryKey])
    }


    // MARK: Creation operations

    /**
     Finds or creates an instance of the given `type` based on the `primaryKey` provided. Returns a tuple of information
     including the `object` and whether or not the object `isNew`.

     - parameter type: The type of the `DataObject` to find (or create).
     - parameter primaryKey: The unique primary key of the object to be found. If not found, will be assigned to the
                             newly-created object.
     - returns: A tuple of information including the `object` and whether or not the object `isNew`.
     */
    func findOrCreate<T: DataObject>(_ type: T.Type, primaryKey: PrimaryKey?) -> (object: T, isNew: Bool)? {
        guard let primaryKey = primaryKey else {
            return nil
        }
        return findOrCreate(type, attributes: [type.primaryKeyPath: primaryKey])
    }

    /**
     Finds or creates an instance of the given `type` based on the `attributes` provided. Returns a tuple of information
     including the `object` and whether or not the object `isNew`.

     - parameter type: The type of the `DataObject` to find (or create).
     - parameter attributes: The attributes of the object to be found. If not found, will be assigned to the
                             newly-created object.
     - returns: A tuple of information including the `object` and whether or not the object `isNew`.
     */
    func findOrCreate<T: DataObject>(_ type: T.Type, attributes: DataContext.Attributes) -> (object: T, isNew: Bool) {
        if let found = object(ofType: type, attributes: attributes) {
            return (found, false)
        }
        return (create(type, attributes: attributes), true)
    }


    // MARK: Destruction operations.

    /**
     The default implementation of this function loops over the objects provided and calls `destroy(_:)` on each one.
     Concrete implementations may wish to provide a more performant version, if necessary.

     - parameter objects: The objects to remove from the backing store.
     */
    func destroy<T: DataObject>(objects: [T]) {
        objects.forEach { destroy(object: $0) }
    }
}

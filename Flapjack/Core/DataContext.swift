//
//  DataContext.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

// MARK: - DataContext

public protocol DataContext {
    typealias Attributes = [String:Any]

    func perform(_ operation: @escaping (_ context: DataContext) -> Void)
    func performSync(_ operation: @escaping (_ context: DataContext) -> Void)
    func processPendingChanges()
    func refresh<T: DataObject>(_ object: T)
    @discardableResult
    func persist() -> DataContextError?
    @discardableResult
    func persistOrRollback() -> Bool
    @discardableResult
    func forcePersist() -> DataContextError?

    // MARK: Collection fetch operations

    func objects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T]
    func objects<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T]
    func objects<T: DataObject>(ofType type: T.Type, objectIDs: [DataObjectID], prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T]
    func objects<T: DataObject>(ofType type: T.Type, primaryKeys: [PrimaryKey], prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T]
    func numberOfObjects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?) -> Int


    // MARK: Single fetch operations

    func object<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?, sortBy sorters: [SortDescriptor]) -> T?
    func object<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?, sortBy sorters: [SortDescriptor]) -> T?
    func object<T: DataObject>(ofType type: T.Type, objectID: DataObjectID) -> T?
    func refetch<T: DataObject>(_ dataObject: T) -> T?


    // MARK: Creation operations

    func create<T: DataObject>(_ type: T.Type) -> T
    func create<T: DataObject>(_ type: T.Type, attributes: Attributes) -> T


    // MARK: Destruction operations

    func destroy<T: DataObject>(_ object: T?)
    func destroy<T: DataObject>(_ objects: [T])
}


// MARK: - DataContext protocol extension

public extension DataContext {

    // MARK: Collection fetch operations

    func objects<T: DataObject>(ofType type: T.Type) -> [T] {
        return objects(ofType: type, predicate: nil, prefetch: nil, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?) -> [T] {
        return objects(ofType: type, predicate: predicate, prefetch: nil, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?, prefetch: [String]?) -> [T] {
        return objects(ofType: type, predicate: predicate, prefetch: prefetch, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, attributes: Attributes) -> [T] {
        return objects(ofType: type, attributes: attributes, prefetch: nil, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?) -> [T] {
        return objects(ofType: type, attributes: attributes, prefetch: prefetch, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T] {
        return objects(ofType: type, predicate: NSCompoundPredicate(andPredicateFrom: attributes), prefetch: prefetch, sortBy: sorters, limit: limit)
    }

    func objects<T: DataObject>(ofType type: T.Type, objectIDs: [DataObjectID]) -> [T] {
        return objects(ofType: type, objectIDs: objectIDs, prefetch: nil, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, objectIDs: [DataObjectID], prefetch: [String]?) -> [T] {
        return objects(ofType: type, objectIDs: objectIDs, prefetch: prefetch, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, primaryKeys: [PrimaryKey]) -> [T] {
        return objects(ofType: type, primaryKeys: primaryKeys, prefetch: nil, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, primaryKeys: [PrimaryKey], prefetch: [String]?) -> [T] {
        return objects(ofType: type, primaryKeys: primaryKeys, prefetch: prefetch, sortBy: [], limit: 0)
    }

    func objects<T: DataObject>(ofType type: T.Type, primaryKeys: [PrimaryKey], prefetch: [String]?, sortBy sorters: [SortDescriptor], limit: Int?) -> [T] {
        guard !primaryKeys.isEmpty else {
            return []
        }
        return objects(ofType: type, attributes: [type.primaryKeyPath: primaryKeys], prefetch: prefetch, sortBy: sorters, limit: limit)
    }


    // MARK: Single fetch operations

    func object<T: DataObject>(ofType type: T.Type, predicate: NSPredicate?) -> T? {
        return object(ofType: type, predicate: predicate, prefetch: nil, sortBy: [])
    }

    func object<T: DataObject>(ofType type: T.Type, attributes: Attributes) -> T? {
        return object(ofType: type, attributes: attributes, prefetch: nil, sortBy: [])
    }

    func object<T: DataObject>(ofType type: T.Type, attributes: Attributes, prefetch: [String]?, sortBy sorters: [SortDescriptor]) -> T? {
        return object(ofType: type, predicate: NSCompoundPredicate(andPredicateFrom: attributes), prefetch: prefetch, sortBy: sorters)
    }

    func object<T: DataObject>(ofType type: T.Type, primaryKey: PrimaryKey?) -> T? {
        guard let primaryKey = primaryKey else {
            return nil
        }
        return object(ofType: type, attributes: [type.primaryKeyPath: primaryKey])
    }


    // MARK: Creation operations

    func findOrCreate<T: DataObject>(_ type: T.Type, primaryKey: PrimaryKey?) -> (object: T, isNew: Bool)? {
        guard let primaryKey = primaryKey else {
            return nil
        }
        return findOrCreate(type, attributes: [type.primaryKeyPath: primaryKey])
    }

    func findOrCreate<T: DataObject>(_ type: T.Type, attributes: DataContext.Attributes) -> (object: T, isNew: Bool)? {
        if let found = object(ofType: type, attributes: attributes) {
            return (found, false)
        }
        return (create(type, attributes: attributes), true)
    }
}


public extension Dictionary where Key == String, Value == Any {
    var cacheKey: String {
        return self.map { key, value in
            return "\(key).\(String(describing: value))"
        }.joined(separator: "-")
    }
}

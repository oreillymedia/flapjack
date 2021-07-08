//
//  DataSource.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 A protocol describing a type that listens for changes in an underlying data set (powered by a `DataContext`) that match
 a given set of conditions, if necessary. Conforming declarations should invoke the `onChange` closure when results
 happen to change.
 */
public protocol DataSource {
    /**
     Describes a type of closure that is used as a communication channel for letting the owner know about object and
     section changes in the matched data set.
     */
    typealias OnChangeClosure = ([DataSourceChange], [DataSourceSectionChange]) -> Void

    /// A generic alias for the underlying type of model object matched and managed by the data source.
    associatedtype ModelType: DataObject & Hashable

    /// A number of all objects matched in the data set, if fetched. Otherwise this should be `0`.
    var numberOfObjects: Int { get }
    /// An array of all objects in the matched data set, if fetched. Otherwise this should be empty.
    var allObjects: [ModelType] { get }
    /// The number of sections detected in the matched data set, if grouped by section. Otherwise, this should be `1`.
    var numberOfSections: Int { get }
    /// Any full section titles for the sections found in the data set, if relevant.
    var sectionNames: [String] { get }
    /// Any abbreviated section titles for the sections found in the data set, if relevant.
    var sectionIndexTitles: [String] { get }
    /// A retained closure that is invoked when section and/or object changes are detected in the matched data set.
    var onChange: OnChangeClosure? { get set }

    /// Tells the data source to perform its operation and retain the matching results.
    func startListening()

    /**
     Provides a count of the number of objects in the section at a given section index. If the given section index
     exceeds the known bounds of possible sections, `0` should be returned.

     - parameter section: The index of the section to use in the lookup.
     - returns: The number of objects in that given section.
     */
    func numberOfObjects(in section: Int) -> Int

    /**
     Provides the object matching the given index path, if found. If not found, this should return `nil`.

     - parameter indexPath: The index path to use in the lookup.
     - returns: The object, if one is found at the given index path.
     */
    func object(at indexPath: IndexPath) -> ModelType?

    /**
     Provides the index path where the given object resides in the matched data set, if found. If not found, this
     should return `nil`.

     - parameter object: The object to use in the lookup.
     - returns: The index path, if found for the given object.
     */
    func indexPath(for object: ModelType?) -> IndexPath?

    /**
     Provides the first object matching a given closure-based query, if found. If not found, this should return `nil`.
     This function should short circuit and return immediately as soon as a result is found.

     - parameter matching: The closure to use as a query; will be passed each model in the matched data set.
     - returns: The first object matching the query, if one as found.
     */
    func firstObject(matching: (ModelType) -> Bool) -> ModelType?

    /**
     Provides the objects matching a given closure-based query, if found. If not found, this should return an empty
     array.

     - parameter matching: The closure to use as a query; will be passed each model in the matched data set.
     - returns: All objects matching the query, if any as found.
     */
    func allObjects(matching: (ModelType) -> Bool) -> [ModelType]
}

/**
 This stub implementation of `DataSource` makes it relatively easy to build your own by only having to implement a few
 short properties/functions, especially if you're managing a non-grouped set of objects. Simply implement `allObjects`
 and `startListening()`, make sure you call `onChange` when the data set changes, and everything else should hinge on
 that.
 */
public extension DataSource {
    /// If not implemented, this returns the `count` of `allObjects`.
    var numberOfObjects: Int {
        return allObjects.count
    }

    /// If not implemented, this assumes there is only one section.
    var numberOfSections: Int {
        return 1
    }

    /// If not implemented, this assumes no section names are needed.
    var sectionNames: [String] {
        return []
    }

    /// If not implemented, this assumes no section index titles are needed.
    var sectionIndexTitles: [String] {
        return []
    }

    /// If not implemented, this returns the same value as `numberOfObjects`.
    func numberOfObjects(in section: Int) -> Int {
        // Default implementation assumes only one section.
        return numberOfObjects
    }

    /// If not implemented, this uses the `item` index to lookup the object in `allObjects`.
    func object(at indexPath: IndexPath) -> ModelType? {
        guard let index = indexPath[safe: 1] else { return nil }
        // Default implementation assumes only one section.
        return allObjects[safe: index]
    }

    /// If not implemented, only returns the index of the object in `allObjects`, and 0 for the section index.
    func indexPath(for object: ModelType?) -> IndexPath? {
        // Default implementation assumes only one section.
        guard let object = object, let foundIndex = allObjects.firstIndex(of: object) else {
            return nil
        }
        return IndexPath(indexes: [0, foundIndex])
    }

    /// If not implemented, returns the first matching object from the `allObjects` array.
    func firstObject(matching: (ModelType) -> Bool) -> ModelType? {
        return allObjects.first(where: matching)
    }

    /// If not implemented, returns all matching objects from the `allObjects` array.
    func allObjects(matching: (ModelType) -> Bool) -> [ModelType] {
        return allObjects.filter(matching)
    }
}

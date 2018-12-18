//
//  CoreDataSource.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData
#if !COCOAPODS
import Flapjack
#endif

// For proper IndexPath support. Not sure what to do without these.
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/**
 Listens for changes in an `NSManagedObjectContext` based on the `NSManagedObjectContextDidChange` notification for a
 series of objects described by a set of `attributes`. Invokes the `onChange` clsoure when the objects identified by the
 lookup change, get deleted, or when new objects are added that match the attributes. Powered by an
 `NSFetchedResultsController`.
 */
public class CoreDataSource<T: NSManagedObject & DataObject>: NSObject, NSFetchedResultsControllerDelegate, DataSource {
    /// A retained closure that is invoked when section and/or object changes are detected in the matched data set.
    public var onChange: OnChangeClosure?

    private var controller: NSFetchedResultsController<NSManagedObject>
    private var pendingSectionChanges = Set<DataSourceSectionChange>()
    private var pendingItemChanges = Set<DataSourceChange>()
    private var hasExecuted: Bool = false
    private var cacheKey: String
    private var limit: Int?

    /**
     Creates and returns an instance of this data source, but does not execute any fetch operations.

     - parameter dataContext: The context on which to listen for object changes.
     - parameter attributes: The attributes of the objects to find and listen for, if applicable.
     - parameter prefetch: An array of keypaths of relationships to be eagerly-fetched, if applicable.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - parameter sectionProperty: A keypath to a property to use when grouping together results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - parameter batchSize: The size of the batch of results to be fetched at a time; default is 25.
     */
    public convenience init(dataAccess: DataAccess, attributes: DataContext.Attributes? = nil, prefetch: [String] = [], sorters: [SortDescriptor] = T.defaultSorters, sectionProperty: String? = nil, limit: Int? = nil, batchSize: Int = 25) {
        var predicate: NSPredicate?
        var cacheKey: String = "\(sorters.cacheKey)-\(limit ?? 0)"
        if let attributes = attributes {
            predicate = NSCompoundPredicate(andPredicateFrom: attributes)
            cacheKey += attributes.cacheKey
        }
        self.init(dataAccess: dataAccess, predicate: predicate, prefetch: prefetch, sorters: sorters, sectionProperty: sectionProperty, limit: limit, batchSize: batchSize, cacheName: cacheKey)
    }

    /**
     Creates and returns an instance of this data source, but does not execute any fetch operations.

     - parameter dataContext: The context on which to listen for object changes.
     - parameter predicate: An optional query to be applied to the lookup.
     - parameter prefetch: An array of keypaths of relationships to be eagerly-fetched, if applicable.
     - parameter sorters: An array of sort descriptors to be applied to the results, if desired.
     - parameter sectionProperty: A keypath to a property to use when grouping together results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - parameter batchSize: The size of the batch of results to be fetched at a time; default is 25.
     - parameter cacheName: An optional string cache key to be given to the fetched results controller; if not supplied,
                            a unique cache key will be formulated based on the other parameters to this initializer.
     */
    public init(dataAccess: DataAccess, predicate: NSPredicate?, prefetch: [String] = [], sorters: [SortDescriptor] = T.defaultSorters, sectionProperty: String? = nil, limit: Int? = nil, batchSize: Int = 25, cacheName: String? = nil) {
        guard let context = dataAccess.mainContext as? NSManagedObjectContext else {
            fatalError("Must be used with an NSManagedObjectContext.")
        }

        let fetchRequest = context.fetchRequest(for: T.self, predicate: predicate, prefetch: prefetch, sortBy: sorters, limit: limit)
        fetchRequest.fetchBatchSize = min(limit ?? batchSize, batchSize)
        if let cacheName = cacheName {
            cacheKey = cacheName
        } else {
            cacheKey = type(of: self).cacheName(type: T.self, fetchRequest: fetchRequest)
        }
        self.limit = limit
        NSFetchedResultsController<NSManagedObject>.deleteCache(withName: cacheKey)
        controller = NSFetchedResultsController<NSManagedObject>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionProperty, cacheName: cacheKey)
        super.init()
        controller.delegate = self
    }


    // MARK: DataSource

    /// A number of all objects matched in the data set, if fetched. Otherwise is 0.
    public var numberOfObjects: Int {
        if let limit = limit {
            return min(limit, controller.fetchedObjects?.count ?? 0)
        }
        return controller.fetchedObjects?.count ?? 0
    }

    /// An array of all objects in the matched data set, if fetched. Otherwise this is empty.
    public var allObjects: [T] {
        guard let fetched = fetchedObjects else {
            return []
        }
        guard let limit = limit else {
            return fetched
        }
        return Array(fetched.prefix(limit))
    }

    /// Any full section titles for the sections found in the data set, if grouped.
    public var sectionNames: [String] {
        return controller.sections?.compactMap { $0.name } ?? []
    }

    /// Any abbreviated section titles for the sections found in the data set, if grouped.
    public var sectionIndexTitles: [String] {
        return controller.sections?.compactMap { $0.indexTitle } ?? []
    }

    /// The number of sections detected in the matched data set, if grouped by section. Otherwise, this is `1`.
    public var numberOfSections: Int {
        return controller.sections?.count ?? 0
    }

    /**
     Tells the fetched results controller to fetch its initial results, and start listening for any new changes that
     come about matching our supplied predicate. If a fetch has already been executed, this method is a no-op.
     */
    public func execute() {
        guard !hasExecuted else {
            return
        }

        do {
            Logger.debug("Fetching cache key \"\(cacheKey)\"")
            try controller.performFetch()
            hasExecuted = true
        } catch let error {
            Logger.debug("Error fetching CoreDataSource<\(T.self)>: \(error)")
        }
    }

    /**
     Provides a count of the number of objects in the section at a given section index. If the given section index
     exceeds the known bounds of possible sections, returns `0`

     - parameter section: The index of the section to use in the lookup.
     - returns: The number of objects in that given section.
     */
    public func numberOfObjects(in section: Int) -> Int {
        return sectionInfo(for: section)?.numberOfObjects ?? 0
    }

    /**
     Provides the object matching the given index path, if found.

     - parameter indexPath: The index path to use in the lookup.
     - returns: The object, if one is found at the given index path.
     */
    public func object(at indexPath: IndexPath) -> T? {
        // controller.object(at: indexPath) is garbage. We do this our way.
        guard let info = sectionInfo(for: indexPath.section) else {
            Logger.error("Couldn't find section info for section \(indexPath.section).")
            return nil
        }
        guard let objects = info.objects else {
            Logger.error("Couldn't find objects for section \(indexPath.section), section info \(info).")
            return nil
        }
        guard let found = objects[safe: indexPath.item] else {
            Logger.error("Couldn't find object at given index \(indexPath.item), section \(indexPath.section) among \(objects.count) objects.")
            return nil
        }
        return found as? T
    }

    /**
     Provides the index path where the given object resides in the matched data set, if found.

     - parameter object: The object to use in the lookup.
     - returns: The index path, if found for the given object.
     */
    public func indexPath(for object: T?) -> IndexPath? {
        guard let object = object else {
            return nil
        }
        return controller.indexPath(forObject: object)
    }

    /**
     Provides the first object matching a given closure-based query, if found. This function will short circuit and
     return immediately as soon as a result is found.

     - parameter matching: The closure to use as a query; will be passed each model in the matched data set.
     - returns: The first object matching the query, if one as found.
     */
    public func firstObject(matching: (T) -> Bool) -> T? {
        return fetchedObjects?.first(where: matching)
    }

    /**
     Provides the objects matching a given closure-based query, if found.

     - parameter matching: The closure to use as a query; will be passed each model in the matched data set.
     - returns: All objects matching the query, if any as found.
     */
    public func allObjects(matching: (T) -> Bool) -> [T] {
        return fetchedObjects?.filter(matching) ?? []
    }


    // MARK: Private functions

    private class func cacheName(type: T.Type, fetchRequest: NSFetchRequest<NSManagedObject>?) -> String {
        return [String(describing: type), cacheName(for: fetchRequest)].joined(separator: "-")
    }

    private class func cacheName(for request: NSFetchRequest<NSManagedObject>?) -> String {
        guard let request = request else {
            return "all"
        }
        var elements = [String]()
        if let value = request.entityName { elements.append(value) }
        if let value = request.predicate?.debugDescription { elements.append(value) }
        elements.append(String(describing: request.fetchLimit))
        if let descriptors = request.sortDescriptors { elements.append(descriptors.map { $0.description }.joined(separator: ".")) }
        return elements.compactMap { $0 }.joined(separator: ".")
    }

    private var fetchedObjects: [T]? {
        // To keep Core Data type info out of Flapjack core, `DataObject` doesn't explicitly conform to
        //   `NSFetchRequestResult`, although if `NSManagedObject`s conform to `DataObject`, everything should work.
        return controller.fetchedObjects as? [T]
    }

    private func sectionInfo(for index: Int) -> NSFetchedResultsSectionInfo? {
        return controller.sections?[safe: index]
    }


    // MARK: NSFetchedResultsControllerDelegate

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard controller === controller else {
            return
        }
        pendingSectionChanges.removeAll()
        pendingItemChanges.removeAll()
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for theType: NSFetchedResultsChangeType) {
        guard controller === controller else {
            return
        }

        Logger.debug("\(#function): (\(T.self))")
        guard let change = theType.asDataSourceSectionChange(section: sectionIndex) else {
            Logger.error("No section change calculated for \(theType), index \(sectionIndex))")
            return
        }
        pendingSectionChanges.insert(change)
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for theType: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard controller === controller else {
            return
        }

        guard var change = theType.asDataSourceChange(at: indexPath, newPath: newIndexPath) else {
            Logger.error("No change calculated for \(theType), indexPath \(String(describing: indexPath)), newIndexPath: \(String(describing: newIndexPath))")
            return
        }

        if let limit = limit {
            switch change {
            case .insert(let path), .delete(let path), .update(let path):
                if path.item >= limit {
                    return
                }
            case .move(let fromPath, let toPath):
                if fromPath.item >= limit && toPath.item < limit {
                    change = .insert(path: toPath)
                } else if fromPath.item < limit && toPath.item >= limit {
                    change = .delete(path: fromPath)
                } else {
                    return
                }
            }
        }

        pendingItemChanges.insert(change)
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard controller === controller else {
            return
        }
        guard let onChange = onChange, !pendingItemChanges.isEmpty || !pendingSectionChanges.isEmpty else {
            return
        }
        onChange(pendingItemChanges, pendingSectionChanges)
        pendingSectionChanges.removeAll()
        pendingItemChanges.removeAll()
    }
}

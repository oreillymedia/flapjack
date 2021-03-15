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

    /// If a predicate is specified at initialization, return that value. Assigning to it changes the predicate associated
    /// with the fetched results controller and will cause data to be reloaded, if a fetch has already been executed. However, the `onChange` handler will not be called.
    public var predicate: NSPredicate? {
        didSet {
            controller.fetchRequest.predicate = predicate
            refetchIfNeeded()
        }
    }

    /// Change the set of sort descriptors used to return the objects in this data source.
    /// Will cause the fetched results controller to be reloaded if `startListening` had already been called,
    /// but does not cause the `onChange` handler to be called.
    public var sorters: [SortDescriptor] = T.defaultSorters {
        didSet {
            controller.fetchRequest.sortDescriptors = sorters.asNSSortDescriptors
            refetchIfNeeded()
        }
    }

    /// False until fetched results controller has performed at least one fetch.
    private(set) public var hasExecuted: Bool = false
    private var controller: NSFetchedResultsController<NSManagedObject>
    private var pendingSectionChanges = [DataSourceSectionChange]()
    private var pendingItemChanges = [DataSourceChange]()
    /// If this is true, our context has been deleted and we're waiting for a new one.
    private var isContextAZombie: Bool = false
    private var cacheKey: String
    private var sectionProperty: String?
    private var fetchRequest: NSFetchRequest<NSManagedObject>
    private var predicateToSurviveContextWipe: NSPredicate?
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

        fetchRequest = {
            let request = context.fetchRequest(for: T.self, predicate: predicate, prefetch: prefetch, sortBy: sorters, limit: limit)
            request.fetchBatchSize = min(limit ?? batchSize, batchSize)
            return request
        }()
        if let cacheName = cacheName {
            cacheKey = cacheName
        } else {
            cacheKey = type(of: self).cacheName(type: T.self, fetchRequest: fetchRequest)
        }
        self.limit = limit
        self.predicate = predicate
        self.sorters = sorters
        self.sectionProperty = sectionProperty
        NSFetchedResultsController<NSManagedObject>.deleteCache(withName: cacheKey)
        controller = NSFetchedResultsController<NSManagedObject>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionProperty, cacheName: cacheKey)
        super.init()
    }


    // MARK: DataSource

    /// A number of all objects matched in the data set, if fetched. Otherwise is 0.
    public var numberOfObjects: Int {
        guard !isContextAZombie else {
            return 0
        }
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
    public func startListening() {
        guard !hasExecuted else {
            return
        }

        NotificationCenter.default.addObserver(self, selector: #selector(contextWasCreated(_:)), name: CoreDataAccess.didCreateNewMainContextNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contextWillBeDestroyed(_:)), name: CoreDataAccess.willDestroyMainContextNotification, object: nil)

        do {
            Logger.debug("Fetching cache key \"\(cacheKey)\"")
            controller.delegate = self
            try controller.performFetch()
            hasExecuted = true
        } catch let error {
            Logger.error("Error fetching CoreDataSource<\(T.self)>: \(error)")
        }
    }

    public func endListening() {
        guard hasExecuted else { return }
        controller.delegate = nil
        NotificationCenter.default.removeObserver(self, name: CoreDataAccess.didCreateNewMainContextNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: CoreDataAccess.willDestroyMainContextNotification, object: nil)
        hasExecuted = false
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
        guard !isContextAZombie else {
            return []
        }
        // To keep Core Data type info out of Flapjack core, `DataObject` doesn't explicitly conform to
        //   `NSFetchRequestResult`, although if `NSManagedObject`s conform to `DataObject`, everything should work.
        return controller.fetchedObjects as? [T]
    }

    private func sectionInfo(for index: Int) -> NSFetchedResultsSectionInfo? {
        return controller.sections?[safe: index]
    }

    private func refetchIfNeeded() {
        guard hasExecuted, !isContextAZombie else { return }
        do {
            NSFetchedResultsController<NSManagedObject>.deleteCache(withName: cacheKey)
            try controller.performFetch()
        } catch let error {
            Logger.error("Error fetching CoreDataSource<\(T.self)>: \(error)")
        }
    }


    // MARK: Notification handlers

    @objc
    private func contextWasCreated(_ notification: Notification) {
        guard isContextAZombie else { return }
        guard let context = notification.object as? NSManagedObjectContext else { return }
        // Restore our predicate, if we had one to restore (from blanking out our FRC with a FALSEPREDICATE).
        predicate = predicateToSurviveContextWipe
        predicateToSurviveContextWipe = nil
        isContextAZombie = false
        controller = NSFetchedResultsController<NSManagedObject>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionProperty, cacheName: cacheKey)
        controller.delegate = self
        refetchIfNeeded()
    }

    @objc
    private func contextWillBeDestroyed(_ notification: Notification) {
        guard controller.managedObjectContext === notification.object as? NSManagedObjectContext else { return }

        // Flag ourselves as existing under a zombie context (one about to be fully banished) so
        //   that when we invoke an on-change block, any objects listening to us that _ask_ us for
        //   our number of objects or our array of objects will get back empty ones (so as to
        //   preserve data source functional integrity for collection/table view data sources).
        // If an object needs to get a specific element from us based on these indices, that object
        //   can still get it before it fully goes away using `object(at:)`.
        isContextAZombie = true

        // Make sure our listener knows our objects are going away
        if hasExecuted {
            if let onChangeBlock = onChange, let fetchedObjects = controller.fetchedObjects as? [T], !fetchedObjects.isEmpty {
                let itemRemovals: [DataSourceChange] = fetchedObjects.compactMap { indexPath(for: $0) }.map { .delete(path: $0) }
                let sectionRemovals: [DataSourceSectionChange] = (0..<numberOfSections).map { .delete(section: $0) }
                onChangeBlock(itemRemovals, sectionRemovals)
            }

            // Give our controller a stub predicate and ask it to fetch, so that it will clear out its fetchedResults.
            //   This will kick off a new fetch. The old predicate is backed up to `predicateToSurviveContextWipe`, to
            //   be... well, restored after the context wipe. Note that a `nil` predicate here is still important,
            //   because no matter what we want to undo this FALSEPREDICATE.
            predicateToSurviveContextWipe = predicate
            predicate = NSPredicate(value: false)
        }

        isContextAZombie = true
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
        pendingSectionChanges.append(change)
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for theType: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard controller === controller else {
            return
        }

        guard let change = theType.asDataSourceChange(at: indexPath, newPath: newIndexPath) else {
            Logger.error("No change calculated for \(theType), indexPath \(String(describing: indexPath)), newIndexPath: \(String(describing: newIndexPath))")
            return
        }

        var changes = [DataSourceChange]()
        switch change {
        case .move(let fromPath, let toPath):
            changes.append(.delete(path: fromPath))
            changes.append(.insert(path: toPath))
        default:
            changes.append(change)
        }

        pendingItemChanges.append(contentsOf: changes)
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

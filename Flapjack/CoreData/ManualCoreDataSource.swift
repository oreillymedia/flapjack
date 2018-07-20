//
//  ManualCoreDataSource.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/18/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData


/**
 A lightweight object for listening to Core Data object changes based on an NSPredicate.
 
 This object requires at least an `NSManagedObjectContext` to be initialized, and then a call to
 `.performFetch(_:)` will activate its listening capabilities. That callback will be invoked right
 away to return any currently-matching objects in the context, and then it will be repeatedly
 invoked for each subsequent change detected for any current and future objects that match the
 given predicate. If no predicate is given, then _all_ objects of the given generic type will be
 observed.
 
 Inspired by Arek Holko's [SingleFetchedResultController](https://github.com/fastred/SingleFetchedResultController ).
 */
public class ManualCoreDataSource<T: NSManagedObject & DataObject> {
    
    /// The context used for interating with Core Data. There must always be a managed object context, for safety.
    private var context: DataContext
    private let predicate: NSPredicate?
    private let prefetch: [String]?
    /// If this is true, our context has been deleted and we're waiting for a new one.
    private var isContextAZombie: Bool = false
    private var sorters: [SortDescriptor]
    private let limit: Int?
    
    private(set) public var isListening = false
    private(set) public var hasFetched = false
    
    /// The master array of objects currently tracked by this data source.
    private(set) public var allObjects: [T] = []
    
    /// The block that will be called upon any change events.
    public var onChange: (([T], ChangeSet<T>) -> Void)?
    public var numberOfObjects: Int { return allObjects.count }
    // TODO: SUPPORT SECTIONS!
    public var numberOfSections: Int { return 1 }
    public var sectionNames: [String] { return [] }
    public var sectionIndexTitles: [String] { return [] }
    
    
    // MARK: Lifecycle
    
    /**
     Creates and returns an instance of this data source. At least, the `context` parameter is
     required. The `predicate` will be used to optionally filter the observed results, the `sorters`
     will be used to sort the results consistently, and the `prefetch` parameter will be used to
     pre-fetch any relationship faults in the initial fetch (it currently isn't used for any
     subsequent updates).
     
     - parameter context: The managed object context instance on which to listen for changes. Generally,
                          unless there's a convincing reason otherwise, this is the main thread context.
     - parameter predicate: The conditions for filtering results that will be observed.
     - parameter sectionProperty: The section property by which to group, if necessary.
     - parameter sorters: An optional array of keypath/ascending tuples for sorting the results.
     - parameter prefetch: An optional array of relationship keypaths to pre-fill faults on initial fetch.
     */
    init(dataAccess: DataAccess, predicate: NSPredicate? = nil, sectionProperty: String? = nil, sortBy sorters: [SortDescriptor] = T.defaultSorters, prefetch: [String]? = nil, limit: Int? = nil) {
        self.context = dataAccess.mainContext
        self.predicate = predicate
        self.prefetch = prefetch
        self.sorters = sorters
        self.limit = limit
    }
    
    /**
     Creates and returns an instance of this data source. At least, the `context` parameter is
     required. The `conditions` will be used to filter the observed results (using an `AND`
     `NSCompoundPredicate`), the `sorters` will be used to sort the results consistently, and
     the `prefetch` parameter will be used to pre-fetch any relationship faults in the initial fetch
     (it currently isn't used for any subsequent updates).
     
     - parameter context: The managed object context instance on which to listen for changes. Generally,
                          unless there's a convincing reason otherwise, this is the main thread context.
     - parameter attributes: The conditions for filtering results that will be observed.
     - parameter sectionProperty: The section property by which to group, if necessary.
     - parameter sorters: An optional array of keypath/ascending tuples for sorting the results.
     - parameter prefetch: An optional array of relationship keypaths to pre-fill faults on initial fetch.
     */
    convenience init(dataAccess: DataAccess, attributes: [String:Any], sectionProperty: String? = nil, sortBy sorters: [SortDescriptor] = T.defaultSorters, prefetch: [String]? = nil, limit: Int? = nil) {
        let predicate = NSCompoundPredicate(andPredicateFrom: attributes)
        self.init(dataAccess: dataAccess, predicate: predicate, sectionProperty: sectionProperty, sortBy: sorters, prefetch: prefetch, limit: limit)
    }
    
    // MARK: Public functions
    
    /**
     Holds onto the passed-in closure and begins listening for object changes. The closure will
     immediately be called using the first-fetched batch of objects that currently exist in the
     managed object context. The same closure will then be invoked any time changes in the context
     are detected on any of the matched objects. Additionally, if any _new_ objects appear in the
     context that match the predicate, they will also start being tracked (and the closure will be
     invoked for those as well).
     
     - parameter onChange: The closure to be retained and invoked any time changes occur.
     */
    public func execute() {
        if !isListening {
            // Only bind this observer once, no matter how many times `performFetch` gets called.
            isListening = true
            NotificationCenter.default.addObserver(self, selector: #selector(handleObjectsDidChange(_:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(contextWasCreated(_:)), name: .didCreateNewMainContext, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(contextWillBeDestroyed(_:)), name: .willDestroyMainContext, object: nil)
        }
        
        let originals = allObjects
        allObjects = context.objects(ofType: T.self, predicate: predicate, prefetch: prefetch, sortBy: sorters, limit: limit)
        let firstFetch = !hasFetched
        hasFetched = true
        if firstFetch {
            onChange?(allObjects, ChangeSet<T>())
        } else {
            onChange?(allObjects, ChangeSet<T>(originals: originals, newList: allObjects))
        }
    }
    
    public subscript(uniqueId: DataContext.PrimaryKey) -> T? {
        return context.object(ofType: T.self, primaryKey: uniqueId)
    }
    
//    public func updateSortDescriptors(sortBy sorters: [SortDescriptor]) {
//        self.sorters = sorters
//        let originals = allObjects
//        allObjects = context.objects(ofType: T.self, predicate: predicate, prefetch: prefetch, sortBy: sorters, limit: limit)
//        let changeSet = ChangeSet<T>(originals: originals, newList: allObjects)
//        onChange?(allObjects, changeSet)
//    }
    
    public func firstObject(_ matching: (T) -> Bool) -> T? {
        return allObjects.first(where: matching)
    }
    
    public func objectsWhere(_ matching: (T) -> Bool) -> [T] {
        return allObjects.filter(matching)
    }
    
    public func numberOfObjects(in section: Int) -> Int {
        return numberOfObjects
    }
    
    public func object(at indexPath: IndexPath) -> T? {
        return allObjects[indexPath.item]
    }
    
    
    
    // MARK: Private notification handlers
    
    @objc private func handleObjectsDidChange(_ notification: Notification) {
        guard context as? NSManagedObjectContext === notification.object as? NSManagedObjectContext else { return }
        
        guard let changeSet = ChangeSet<T>(originals: allObjects, notification: notification, filter: predicate, sorters: sorters) else { return }
        self.allObjects = changeSet.allObjects
        onChange?(allObjects, changeSet)
    }
    
    @objc private func contextWasCreated(_ notification: Notification) {
        guard isContextAZombie else { return }
        guard let newContext = notification.object as? NSManagedObjectContext else { return }
        
        // Store our newly-minted context, and refetch.
        self.context = newContext
        execute()
    }
    
    @objc private func contextWillBeDestroyed(_ notification: Notification) {
        guard context as? NSManagedObjectContext === notification.object as? NSManagedObjectContext else { return }
        
        // Make sure our listener knows our objects are going away
        if allObjects.count > 0 {
            let changeSet = ChangeSet<T>(originals: allObjects, deletes: Set<T>(allObjects), filter: predicate, sorters: sorters)
            allObjects = [T]()
            onChange?([T](), changeSet ?? ChangeSet<T>())
        }
        
        isContextAZombie = true
        hasFetched = false
    }
}

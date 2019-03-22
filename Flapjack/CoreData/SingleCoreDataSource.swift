//
//  SingleCoreDataSource.swift
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

/**
 Listens for changes in an `NSManagedObjectContext` based on the `NSManagedObjectContextDidChange` notification for a
 single object described by a set of `attributes`. Invokes the `onChange` clsoure when the monitored object changes in
 the given `DataContext`.
 */
public class SingleCoreDataSource<T: NSManagedObject & DataObject>: NSObject, SingleDataSource {
    public let predicate: NSPredicate
    public private(set) var object: T?
    public private(set) var hasFetched = false
    public var onChange: ((T?) -> Void)?

    // This can only change if the context gets torn down and we get notified about a new one.
    private var context: DataContext
    private let prefetch: [String]
    /// If this is true, our context has been deleted and we're waiting for a new one.
    private var isContextAZombie: Bool = false
    private var isListening: Bool = false


    // MARK: Lifecycle

    /**
     Creates and returns an instance of this data source, but does not execute any fetch operations.

     - parameter context: The context on which to listen for object changes.
     - parameter predicate: The predicate of the object to find and then listen for, if applicable.
     - parameter prefetch: An array of keypaths of relationships to be eagerly-fetched, if applicable.
     */
    public init(context: DataContext, predicate: NSPredicate, prefetch: [String] = []) {
        self.context = context
        self.predicate = predicate
        self.prefetch = prefetch
        super.init()
    }

    /**
     Creates and returns an instance of this data source, but does not execute any fetch operations.

     - parameter context: The context on which to listen for object changes.
     - parameter attributes: The attributes of the object to find and then listen for, if applicable.
     - parameter prefetch: An array of keypaths of relationships to be eagerly-fetched, if applicable.
     */
    public convenience init(context: DataContext, attributes: DataContext.Attributes, prefetch: [String] = []) {
        let predicate = NSCompoundPredicate(andPredicateFrom: attributes)
        self.init(context: context, predicate: predicate, prefetch: prefetch)
    }

    /**
     Creates and returns an instance of this data source, but does not execute any fetch operations.

     - parameter context: The context on which to listen for object changes.
     - parameter uniqueID: The unique identifier of the object to find and then listen for.
     - parameter prefetch: An array of keypaths of relationships to be eagerly-fetched, if applicable.
     */
    public convenience init(context: DataContext, uniqueID: T.PrimaryKeyType, prefetch: [String] = []) {
        let predicate = NSCompoundPredicate(andPredicateFrom: [T.primaryKeyPath: uniqueID])
        self.init(context: context, predicate: predicate, prefetch: prefetch)
    }

    /**
     Creates and returns an instance of this data source, but does not execute any fetch operations.

     - parameter context: The managed object context instance on which to listen for changes.
     - parameter object: The object for which to observe changes.
     - parameter prefetch: An optional array of relationship keypaths to pre-fill faults on initial fetch.
     */
    public convenience init(context: DataContext, object: T, prefetch: [String] = []) {
        self.init(context: context, predicate: NSPredicate(key: "self", value: object), prefetch: prefetch)
    }

    deinit {
        guard isListening else {
            return
        }
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: nil)
    }


    // MARK: SingleDataSource

    /**
     Begins listening for `NSManagedObjectContextObjectsDidChange` notifications, and fetches the initial object result
     into the `object` property. Immediately invokes the `onChange` block upon completion and passes in the object if
     found.
     */
    public func startListening() {
        if !isListening {
            NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange(_:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(contextWasCreated(_:)), name: CoreDataAccess.didCreateNewMainContextNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(contextWillBeDestroyed(_:)), name: CoreDataAccess.willDestroyMainContextNotification, object: nil)
            isListening = true
        }

        object = context.object(ofType: T.self, predicate: predicate, prefetch: prefetch, sortBy: [])
        onChange?(object)
    }


    // MARK: Private functions

    private func findObjectFrom(objects: Set<T>) -> T? {
        return (objects as NSSet).filtered(using: predicate).first(where: { $0 is T }) as? T
    }

    @objc
    private func objectsDidChange(_ notification: Notification) {
        guard context as? NSManagedObjectContext === notification.object as? NSManagedObjectContext else { return }

        let (refreshes, inserts, updates, deletes) = NSManagedObjectContext.objectsFrom(notification: notification, ofType: T.self)

        if findObjectFrom(objects: deletes) != nil {
            hasFetched = true
            object = nil
            onChange?(nil)
            return
        }

        let theRest = inserts.union(updates).union(refreshes)
        if let filtered = findObjectFrom(objects: theRest) {
            hasFetched = true
            object = filtered
        }

        onChange?(object)
    }

    @objc
    private func contextWasCreated(_ notification: Notification) {
        guard isContextAZombie else { return }
        guard let newContext = notification.object as? DataContext else { return }

        // Store our newly-minted context, and refetch.
        self.context = newContext
        startListening()
    }

    @objc
    private func contextWillBeDestroyed(_ notification: Notification) {
        guard context as? NSManagedObjectContext === notification.object as? NSManagedObjectContext else { return }

        isContextAZombie = true
        hasFetched = false
        object = nil
    }
}

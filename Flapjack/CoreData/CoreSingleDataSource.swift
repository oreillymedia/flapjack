//
//  BaseSingleDataSource.swift
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
public class CoreSingleDataSource<T: NSManagedObject & DataObject>: NSObject, SingleDataSource {
    /// The criteria being used for finding the object being observed by this data source.
    public let attributes: DataContext.Attributes
    /// The object being observed by this data source, if found.
    public private(set) var object: T?
    /// A closure to be called whenever a change is detected to the object being observed.
    public var onChange: ((T?) -> Void)?

    private let context: DataContext
    private let prefetch: [String]
    private var isListening: Bool = false


    // MARK: Lifecycle

    /**
     Creates and returns an instance of this data source, but does not execute any fetch operations.

     - parameter dataContext: The context on which to listen for object changes.
     - parameter attributes: The attributes of the object to find and then listen for, if applicable.
     - parameter prefetch: An array of keypaths of relationships to be eagerly-fetched, if applicable.
     */
    public init(context: DataContext, attributes: DataContext.Attributes, prefetch: [String]) {
        self.context = context
        self.attributes = attributes
        self.prefetch = prefetch
        super.init()
    }

    /**
     Creates and returns an instance of this data source, but does not execute any fetch operations.

     - parameter dataContext: The context on which to listen for object changes.
     - parameter uniqueID: The unique identifier of the object to find and then listen for.
     - parameter prefetch: An array of keypaths of relationships to be eagerly-fetched, if applicable.
     */
    public convenience init(context: DataContext, uniqueID: T.PrimaryKeyType, prefetch: [String]) {
        self.init(context: context, attributes: [T.primaryKeyPath: uniqueID], prefetch: prefetch)
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
    public func execute() {
        if !isListening {
            NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange(_:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)
            isListening = true
        }

        object = context.object(ofType: T.self, attributes: attributes, prefetch: prefetch, sortBy: [])
        onChange?(object)
    }


    // MARK: Private functions

    @objc
    private func objectsDidChange(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext, context === self.context as? NSManagedObjectContext else {
            return
        }
        let allObjects = NSManagedObjectContext.objectsFrom(notification: notification, ofType: T.self)
        if allObjects.refreshes.isEmpty, allObjects.inserts.isEmpty, allObjects.updates.isEmpty, allObjects.deletes.isEmpty {
            return
        }

        if (allObjects.deletes as NSSet).filtered(using: NSCompoundPredicate(andPredicateFrom: attributes)).first as? T != nil {
            object = nil
            onChange?(nil)
            return
        }

        let theRest = allObjects.inserts.union(allObjects.updates).union(allObjects.refreshes)
        if let filtered = (theRest as NSSet).filtered(using: NSCompoundPredicate(andPredicateFrom: attributes)).first as? T {
            object = filtered
        }

        onChange?(object)
    }
}

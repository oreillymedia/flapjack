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

public class CoreSingleDataSource<T: NSManagedObject & DataObject>: NSObject, SingleDataSource {
    public let attributes: DataContext.Attributes
    public private(set) var object: T?
    public var objectDidChange: ((T?) -> Void)?

    private let dataAccess: DataAccess
    private let prefetch: [String]
    private var isListening: Bool = false


    // MARK: Lifecycle

    public init(dataAccess: DataAccess, attributes: DataContext.Attributes, prefetch: [String]) {
        self.dataAccess = dataAccess
        self.attributes = attributes
        self.prefetch = prefetch
        super.init()
    }

    public convenience init(dataAccess: DataAccess, uniqueID: T.PrimaryKeyType, prefetch: [String]) {
        self.init(dataAccess: dataAccess, attributes: [T.primaryKeyPath: uniqueID], prefetch: prefetch)
    }

    deinit {
        guard isListening else {
            return
        }
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: nil)
    }


    // MARK: SingleDataSource

    public func execute() {
        if !isListening {
            NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange(_:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)
            isListening = true
        }

        object = dataAccess.mainContext.object(ofType: T.self, attributes: attributes, prefetch: prefetch, sortBy: [])
        objectDidChange?(object)
    }


    // MARK: Private functions

    @objc
    private func objectsDidChange(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext, context === dataAccess.mainContext as? NSManagedObjectContext else {
            return
        }
        let allObjects = NSManagedObjectContext.objectsFrom(notification: notification, ofType: T.self)
        if allObjects.refreshes.isEmpty, allObjects.inserts.isEmpty, allObjects.updates.isEmpty, allObjects.deletes.isEmpty {
            return
        }

        if (allObjects.deletes as NSSet).filtered(using: NSCompoundPredicate(andPredicateFrom: attributes)).first as? T != nil {
            object = nil
            return
        }

        let theRest = allObjects.inserts.union(allObjects.updates).union(allObjects.refreshes)
        if let filtered = (theRest as NSSet).filtered(using: NSCompoundPredicate(andPredicateFrom: attributes)).first as? T {
            object = filtered
        }

        objectDidChange?(object)
    }
}

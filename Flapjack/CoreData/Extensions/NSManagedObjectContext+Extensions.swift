//
//  NSManagedObjectContext+Extensions.swift
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

public extension NSManagedObjectContext {
    /**
     A tuple that represents a series of refreshed, inserted, updated, and deleted `DataObjects`.
     */
    typealias NotificationObjectSet<T: DataObject & Hashable> = (refreshes: Set<T>, inserts: Set<T>, updates: Set<T>, deletes: Set<T>)
    /**
     A tuple that represents a series of refreshed, inserted, updated, and deleted objects based on their
     `NSManagedObjectID`s.
     */
    typealias NotificationObjectIDSet = (refreshes: Set<NSManagedObjectID>, inserts: Set<NSManagedObjectID>, updates: Set<NSManagedObjectID>, deletes: Set<NSManagedObjectID>)

    /**
     Obtains the refreshed, updated, inserted, and deleted object identifiers from a Core Data object-did-change or
     context-did-save notification.

     - parameter notification: The notification object from an `NSManagedObjectContextObjectsDidChange` or
                               `NSManagedObjectContextDidSave` notification.
     - returns: A tuple containing the object IDs from the notification.
     */
    class func objectIDsFrom(notification: Notification) -> NotificationObjectIDSet {
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>
        let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>
        let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>
        let inserted = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>
        return (
            Set<NSManagedObjectID>(refreshed?.map { $0.objectID } ?? []),
            Set<NSManagedObjectID>(inserted?.map { $0.objectID } ?? []),
            Set<NSManagedObjectID>(updated?.map { $0.objectID } ?? []),
            Set<NSManagedObjectID>(deleted?.map { $0.objectID } ?? [])
        )
    }

    /**
     Obtains the refreshed, updated, inserted, and deleted object identifiers from a Core Data object-did-change or
     context-did-save notification matching a given type.

     - parameter notification: The notification object from an `NSManagedObjectContextObjectsDidChange` or
                               `NSManagedObjectContextDidSave` notification.
     - parameter type: The type of the objects to retrieve; only those matching this type will be returned.
     - returns: A tuple containing the object IDs from the notification.
     */
    class func objectsFrom<T: DataObject & Hashable>(notification: Notification, ofType type: T.Type) -> NotificationObjectSet<T> {
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<T> ?? Set<T>()
        let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<T> ?? Set<T>()
        let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<T> ?? Set<T>()
        let inserted = notification.userInfo?[NSInsertedObjectsKey] as? Set<T> ?? Set<T>()
        return (refreshed, inserted, updated, deleted)
    }

    /**
     Obtains the object from an `NSManagedObjectContextObjectsDidChange` or `NSManagedObjectContextDidSave` notification
     based on that object's `NSManagedObjectID`.

     - parameter objectID: The managed object identifier of the object to retrieve.
     - parameter type: The type of the object to retrieve.
     - parameter notification: The notification object from an `NSManagedObjectContextObjectsDidChange` or
                               `NSManagedObjectContextDidSave` notification.
     - parameter refetch: If `true`, the object will be refreshed again from Core Data. Generally this should be
                          left to the default value `false` unless you have a good reason.
     - returns: A tuple containing the object and whether or not it came through as a deletion, if found.
     */
    class func referencedObject<T: DataObject & Hashable>(for objectID: NSManagedObjectID, type: T.Type, in notification: Notification, refetch: Bool = false) -> (object: T, deleted: Bool)? {
        let (refreshes, inserts, updates, deletes) = objectsFrom(notification: notification, ofType: type)
        guard let context = notification.object as? NSManagedObjectContext else {
            return nil
        }

        for object in refreshes {
            guard let managed = object as? NSManagedObject, managed.objectID == objectID else { continue }
            if refetch, let refetched = context.object(with: objectID) as? T {
                return (refetched, false)
            }
            return (object, false)
        }
        for object in inserts {
            guard let managed = object as? NSManagedObject, managed.objectID == objectID else { continue }
            if refetch, let refetched = context.object(with: objectID) as? T {
                return (refetched, false)
            }
            return (object, false)
        }
        for object in updates {
            guard let managed = object as? NSManagedObject, managed.objectID == objectID else { continue }
            if refetch, let refetched = context.object(with: objectID) as? T {
                return (refetched, false)
            }
            return (object, false)
        }
        for object in deletes {
            guard let managed = object as? NSManagedObject, managed.objectID == objectID else { continue }
            return (object, true)
        }
        return nil
    }

    /**
     Checks if the given object is referenced in the given `NSManagedObjectContextObjectsDidChange` or
     `NSManagedObjectContextDidSave` notification.

     - parameter object: The object to look for in the change notification.
     - parameter notification: The notification object from an `NSManagedObjectContextObjectsDidChange` or
                               `NSManagedObjectContextDidSave` notification.
     - returns: `true` if found.
     */
    class func isObject(_ object: NSManagedObject, referencedIn notification: Notification) -> Bool {
        let objectID = object.objectID
        let (refreshes, inserts, updates, deletes) = objectIDsFrom(notification: notification)
        return refreshes.contains(objectID) || inserts.contains(objectID) || updates.contains(objectID) || deletes.contains(objectID)
    }
}

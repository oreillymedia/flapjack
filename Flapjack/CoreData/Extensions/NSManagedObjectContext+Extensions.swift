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
    typealias NotificationObjectSet<T: DataObject & Hashable> = (refreshes: Set<T>, inserts: Set<T>, updates: Set<T>, deletes: Set<T>)
    typealias NotificationObjectIDSet = (refreshes: Set<NSManagedObjectID>, inserts: Set<NSManagedObjectID>, updates: Set<NSManagedObjectID>, deletes: Set<NSManagedObjectID>)

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

    class func objectsFrom<T: DataObject & Hashable>(notification: Notification, ofType type: T.Type) -> NotificationObjectSet<T> {
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<T> ?? Set<T>()
        let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<T> ?? Set<T>()
        let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<T> ?? Set<T>()
        let inserted = notification.userInfo?[NSInsertedObjectsKey] as? Set<T> ?? Set<T>()
        return (refreshed, inserted, updated, deleted)
    }

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

    class func isObject(_ object: NSManagedObject, referencedIn notification: Notification) -> Bool {
        let objectID = object.objectID
        let (refreshes, inserts, updates, deletes) = objectIDsFrom(notification: notification)
        return refreshes.contains(objectID) || inserts.contains(objectID) || updates.contains(objectID) || deletes.contains(objectID)
    }
}

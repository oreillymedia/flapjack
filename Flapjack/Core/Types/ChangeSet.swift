//
//  CoreDataChangeSet.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/18/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData

/**
 Responsible for consuming an array of items along with a Core Data changeset that modifies that
 object array. Emits a set of inserts, updates, and deletes, along with a modified array of the
 original objects, plus an indexed dictionary of where those inserts/updates/deletes were made.
 */
public class ChangeSet<T: DataObject & Hashable> {
    public typealias Insert = (object: T, newIndex: Int)
    public typealias Update = (object: T, oldIndex: Int, newIndex: Int)
    public typealias Delete = (object: T, oldIndex: Int)
    public typealias AllChanges = (all: [T], inserts: [Insert], updates: [Update], deletes: [Delete])
    
    public let inserts: [Insert]
    public let updates: [Update]
    public let deletes: [Delete]
    public let allObjects: [T]
    
    public var hasChanges: Bool {
        return !inserts.isEmpty || !updates.isEmpty || !deletes.isEmpty
    }
    
    
    // MARK: Lifecycle
    
    /**
     Creates an instance of this change set given a handful of necessary properties. May return nil
     if no matches from the Core Data Change Notification were found.
     
     - parameters:
     - originals: The original array of objects to do calculations against.
     - notification: The Core Data Change Notification.
     - filter: Any predicate to use when filtering the objects from the notification.
     - prefilterBlock: A block to prefilter any objects from the notification before inserts, updates and deletes are processed
     - sorters: Any sort descriptor tuples to use when sorting this data.
     
     - returns: An instance of the object with all properties populated, or nil if no changes found.
     */
    convenience init?(originals: [T], notification: Notification, filter: NSPredicate?, sorters: [SortDescriptor]?) {
        let (inserts, updates, deletes, refreshes) = NSManagedObjectContext.objectsFrom(notification: notification, ofType: T.self)
        let updatesAndRefreshes = updates.union(refreshes)
        self.init(originals: originals, inserts: inserts, updates: updatesAndRefreshes, deletes: deletes, filter: filter, sorters: sorters)
    }
    
    init?(originals: [T], inserts: Set<T> = Set<T>(), updates: Set<T> = Set<T>(), deletes: Set<T> = Set<T>(), filter: NSPredicate? = nil, sorters: [SortDescriptor]? = nil) {
        guard inserts.count > 0 || updates.count > 0 || deletes.count > 0 else { return nil }
        
        let changes = type(of: self).process(originals: originals, predicate: filter, sorters: sorters, inserts: inserts, updates: updates, deletes: deletes)
        guard changes.inserts.count > 0 || changes.updates.count > 0 || changes.deletes.count > 0 else { return nil }
        
        self.inserts = changes.inserts
        self.updates = changes.updates
        self.deletes = changes.deletes
        self.allObjects = changes.all
    }
    
    init(originals: [T], newList: [T]) {
        let changes = type(of: self).process(originals: originals, newList: newList)
        
        self.inserts = changes.inserts
        self.updates = changes.updates
        self.deletes = changes.deletes
        self.allObjects = changes.all
    }
    
    init() {
        self.inserts = []
        self.updates = []
        self.deletes = []
        self.allObjects = []
    }
    
    public var description: String {
        return debugDescription
    }
    
    public var debugDescription: String {
        return "<ChangeSet<\(String(describing: T.self))> objects: \(allObjects.count), inserts: \(inserts), updates: \(updates), deletes: \(deletes)>"
    }
    
    
    // MARK: Public functions
    
    public func asDictionaryTuple() -> (inserts: [T:Int], updates: [T:[Int]], deletes: [T:Int]) {
        let insertDict: [T:Int] = inserts.reduce([T:Int]()) { memo, insert in
            var updatedMemo = memo
            updatedMemo[insert.object] = insert.newIndex
            return updatedMemo
        }
        let updateDict: [T:[Int]] = updates.reduce([T:[Int]]()) { memo, update in
            var updatedMemo = memo
            updatedMemo[update.object] = [update.oldIndex, update.newIndex]
            return updatedMemo
        }
        let deleteDict: [T:Int] = deletes.reduce([T:Int]()) { memo, delete in
            var updatedMemo = memo
            updatedMemo[delete.object] = delete.oldIndex
            return updatedMemo
        }
        return (insertDict, updateDict, deleteDict)
    }
    
    
    // MARK: Private functions
    
    private class func process(originals: [T], newList: [T]) -> AllChanges {
        guard originals != newList else {
            return (all: newList, inserts: [], updates: [], deletes: [])
        }
        
        var workingCopy = originals
        
        let indexesNotFound = originals.enumerated().compactMap { pair in
            return newList.contains(pair.element) ? nil : pair.offset
        }
        
        let mappedDeletes: [Delete] = indexesNotFound.sorted().reversed().compactMap { idx in
            return Delete(workingCopy.remove(at: idx), idx)
        }
        
        let mappedInserts: [Insert] = newList.enumerated().compactMap { pair in
            guard !workingCopy.contains(pair.element) else { return nil }
            workingCopy.insert(pair.element, at: pair.offset)
            return Insert(pair.element, pair.offset)
        }
        
        let permutations: [(origIdx: Int, oldIdx: Int, newIdx: Int)] = newList.enumerated().compactMap { pair in
            guard let origIndex = originals.index(of: pair.element) else { return nil }
            guard let workingIndex = workingCopy.index(of: pair.element) else { return nil }
            return (origIndex, workingIndex, pair.offset)
        }
        
        let mappedUpdates: [Update] = permutations.compactMap { origIndex, oldIdx, newIdx in
            let object = workingCopy.remove(at: oldIdx)
            workingCopy.insert(object, at: newIdx)
            return Update(object, origIndex, newIdx)
        }
        
        return (newList, mappedInserts, mappedUpdates, mappedDeletes)
    }
    
    private class func process(originals: [T], predicate: NSPredicate?, sorters: [SortDescriptor]?, inserts: Set<T>, updates: Set<T>, deletes: Set<T>) -> AllChanges {
        var mutatingObjects = originals
        
        // First, figure out which objects are going to be deleted. We'll take them out of our
        //   mutable array (mutatingObjects) after we get all the info we need about insert/update
        //   indexes.
        
        var mappedDeletes = [Delete]()
        deletes.forEach { deleted in
            guard let index = mutatingObjects.index(of: deleted, pointerComparison: true) else { return }
            mappedDeletes.append(Delete(deleted, index))
        }
        
        // Then, process updates, because some of them may become deletes if they no longer match.
        
        var mutableMatchedUpdates = filtered(objects: updates, with: predicate)
        var mutableMatchedInserts = filtered(objects: inserts, with: predicate)
        
        // Check all updates, regardless of if they match our predicate, because it's possible they
        //   used to match our predicate and now they don't (in which case, it's a "delete").
        updates.forEach { updated in
            // If this object matches one of our own, but it isn't found in any of our matched inserts
            //   or updates, it's been "updated" to no longer match our predicate, so it's a deletion.
            if let index = mutatingObjects.index(of: updated, pointerComparison: true) {
                guard !mutableMatchedUpdates.contains(updated), !mutableMatchedInserts.contains(updated) else { return }
                mappedDeletes.append(Delete(updated, index))
                return
            }
            
            // If we don't track this object in our objects set, but it matched our predicate,
            //   treat it as an insert and go to the next object.
            if let found = mutableMatchedUpdates.remove(updated) {
                mutableMatchedInserts.insert(found)
                mutatingObjects.append(found)
            }
        }
        
        // It's time to start modifying our mutable array. First, insert stuff into the array.
        
        var mappedPreUpdates = [T:Int]()
        filtered(objects: inserts, with: predicate).forEach { inserted in
            // If for some reason, we already have this inserted object in our mutatingObjects, replace
            //   it and track it as an update. Remove it from our matchedInserts set and instead give
            //   it to our matchedUpdates set (so that it ends up in the right changeset object).
            if let foundIndex = mutatingObjects.index(of: inserted, pointerComparison: true), let removed = mutableMatchedInserts.remove(inserted) {
                mutatingObjects[foundIndex] = removed
                mappedPreUpdates[inserted] = foundIndex
                mutableMatchedUpdates.insert(removed)
            } else {
                mutatingObjects.append(inserted)
            }
        }
        
        // Then, update stuff.
        
        updates.forEach { updated in
            guard let index = mutatingObjects.index(of: updated, pointerComparison: true), mutableMatchedUpdates.contains(updated) else { return }
            // If this updated object still matches our predicate, update our reference to it.
            mutatingObjects[index] = updated
            mappedPreUpdates[updated] = index
        }
        
        // Now delete all the things we tracked.
        
        mutatingObjects.remove(atIndexes: mappedDeletes.map { $0.oldIndex })
        
        // Then, sort everything.
        
        if let sorters = sorters, !sorters.isEmpty {
            mutatingObjects = (mutatingObjects as NSArray).sortedArray(using: sorters.asNSSortDescriptors).compactMap { $0 as? T }
        } else {
            mutatingObjects = Array(mutatingObjects)
        }
        
        // Grab the indices of the things we've inserted.
        
        var mappedInserts = [Insert]()
        mutableMatchedInserts.forEach { inserted in
            guard let index = mutatingObjects.index(of: inserted, pointerComparison: true) else { return }
            mappedInserts.append(Insert(inserted, index))
        }
        
        // And grab the indices of the things that were there before but have been updated.
        
        var mappedUpdates = [Update]()
        mutableMatchedUpdates.forEach { updated in
            guard
                let newIndex = mutatingObjects.index(of: updated, pointerComparison: true),
                let oldIndex = mappedPreUpdates[updated]
                else { return }
            mappedUpdates.append(Update(updated, oldIndex, newIndex))
        }
        
        return (mutatingObjects, mappedInserts, mappedUpdates, mappedDeletes)
    }
    
    private class func filtered(objects: Set<T>, with predicate: NSPredicate?) -> Set<T> {
        if let predicate = predicate, let filtered = (objects as NSSet).filtered(using: predicate) as? Set<T> {
            return filtered
        }
        return objects
    }
}

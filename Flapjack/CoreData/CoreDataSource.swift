//
//  CoreDataSource.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataSource<T: NSManagedObject & DataObject>: NSObject, NSFetchedResultsControllerDelegate, DataSource {
    private var controller: NSFetchedResultsController<T>
    private var pendingSectionChanges = Set<DataSourceSectionChange>()
    private var pendingItemChanges = Set<DataSourceChange>()
    private var hasExecuted: Bool = false
    private var cacheKey: String
    private var limit: Int?
    public var onChange: OnChangeClosure?

    public convenience init(dataAccess: DataAccess, attributes: DataContext.Attributes? = nil, prefetch: [String] = [], sorters: [SortDescriptor] = T.defaultSorters, sectionProperty: String? = nil, limit: Int? = nil, batchSize: Int = 25) {
        var predicate: NSPredicate?
        var cacheKey: String = "\(sorters.cacheKey)-\(limit ?? 0)"
        if let attributes = attributes {
            predicate = NSCompoundPredicate(andPredicateFrom: attributes)
            cacheKey += attributes.cacheKey
        }
        self.init(dataAccess: dataAccess, predicate: predicate, prefetch: prefetch, sorters: sorters, sectionProperty: sectionProperty, limit: limit, batchSize: batchSize, cacheName: cacheKey)
    }

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
        NSFetchedResultsController<T>.deleteCache(withName: cacheKey)
        controller = NSFetchedResultsController<T>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionProperty, cacheName: cacheKey)
        super.init()
        controller.delegate = self
    }


    // MARK: DataSource

    public var numberOfObjects: Int {
        if let limit = limit {
            return limit
        }
        return controller.fetchedObjects?.count ?? 0
    }

    public var allObjects: [T] {
        guard let fetched = controller.fetchedObjects else {
            return []
        }
        guard let limit = limit else {
            return fetched
        }
        return Array(fetched.prefix(limit))
    }

    public var sectionNames: [String] {
        return controller.sections?.compactMap { $0.name } ?? []
    }

    public var sectionIndexTitles: [String] {
        return controller.sections?.compactMap { $0.indexTitle } ?? []
    }

    public var numberOfSections: Int {
        return controller.sections?.count ?? 0
    }

    public func execute() {
        guard !hasExecuted else {
            return
        }

        do {
            Logger.verbose("Fetching cache key \"\(cacheKey)\"")
            try controller.performFetch()
        } catch let error {
            Logger.warning("Error fetching CoreDataSource<\(T.self)>: \(error)")
        }
    }

    public func numberOfObjects(in section: Int) -> Int {
        return sectionInfo(for: section)?.numberOfObjects ?? 0
    }

    public func object(at indexPath: IndexPath) -> T? {
        // controller.object(at: indexPath) is garbage. We do this our way.
        guard let info = sectionInfo(for: indexPath.section) else {
            Logger.warning("Couldn't find section info for section \(indexPath.section).")
            return nil
        }
        guard let objects = info.objects else {
            Logger.warning("Couldn't find objects for section \(indexPath.section), section info \(info).")
            return nil
        }
        guard let found = objects[safe: indexPath.item] else {
            Logger.warning("Couldn't find object at given index path \(indexPath) among \(objects.count) objects.")
            return nil
        }
        return found as? T
    }

    public func indexPath(for object: T?) -> IndexPath? {
        guard let object = object else {
            return nil
        }
        return controller.indexPath(forObject: object)
    }

    public func firstObject(_ matching: (T) -> Bool) -> T? {
        return controller.fetchedObjects?.first(where: matching)
    }

    public func objectsWhere(_ matching: (T) -> Bool) -> [T] {
        return controller.fetchedObjects?.filter(matching) ?? []
    }


    // MARK: Private functions

    private class func cacheName(type: T.Type, fetchRequest: NSFetchRequest<T>?) -> String {
        return [String(describing: type), cacheName(for: fetchRequest)].joined(separator: "-")
    }

    private class func cacheName(for request: NSFetchRequest<T>?) -> String {
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

        Logger.verbose("\(#function): (\(T.self))")
        guard let change = theType.asDataSourceSectionChange(section: sectionIndex) else {
            Logger.warning("No section change calculated for \(theType), index \(sectionIndex))")
            return
        }
        pendingSectionChanges.insert(change)
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for theType: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard controller === controller else {
            return
        }

        guard var change = theType.asDataSourceChange(at: indexPath, newPath: newIndexPath) else {
            Logger.warning("No change calculated for \(theType), indexPath \(String(describing: indexPath)), newIndexPath: \(String(describing: newIndexPath))")
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

//
//  CoreDataAccess.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 10/14/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData


// MARK: - CoreDataAccess

public final class CoreDataAccess: DataAccess {
    public enum StoreType {
        case sql(filename: String)
        case memory

        var url: URL? {
            switch self {
            case .sql(let name):
                return storeUrl(for: name)
            case .memory:
                return nil
            }
        }

        var storeDescription: NSPersistentStoreDescription {
            var description: NSPersistentStoreDescription
            switch self {
            case .sql(let name):
                description = NSPersistentStoreDescription(url: storeUrl(for: name))
            case .memory:
                description = NSPersistentStoreDescription()
            }
            description.type = coreDataType
            return description
        }

        var coreDataType: String {
            switch self {
            case .sql: return NSSQLiteStoreType
            case .memory: return NSInMemoryStoreType
            }
        }

        private func storeUrl(for name: String) -> URL {
            return NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(name)
        }
    }

    public private(set) var isStackReady: Bool = false
    private let storeType: StoreType
    private let container: NSPersistentContainer
    private var shouldLoadAsynchronously: Bool = false
    private var persistentStores = [NSPersistentStore]()
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        return container.persistentStoreCoordinator
    }

    // MARK: Lifecycle

    public init(name: String, type: StoreType, model: NSManagedObjectModel? = nil) {
        storeType = type
        if let model = model {
            container = NSPersistentContainer(name: name, managedObjectModel: model)
        } else {
            container = NSPersistentContainer(name: name)
        }
        container.persistentStoreDescriptions = [type.storeDescription]
    }


    // MARK: DataAccess

    public var mainContext: DataContext {
        return container.viewContext
    }

    public func prepareStack(asynchronously: Bool, completion: @escaping (DataAccessError?) -> Void) {
        guard persistentStoreCoordinator.persistentStores.isEmpty else {
            completion(nil)
            return
        }

        addDefaultPersistentStores(async: asynchronously) { [weak self] fatalError in
            guard let `self` = self else {
                return completion(fatalError)
            }
            self.container.viewContext.automaticallyMergesChangesFromParent = true
            self.isStackReady = true
            NotificationCenter.default.post(name: .didCreateNewMainContext, object: self.mainContext)
            completion(nil)
        }
    }

    public func performInBackground(operation: @escaping (_ context: DataContext) -> Void) {
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            operation(context)
        }
    }

    public func vendBackgroundContext() -> DataContext {
        let context = container.newBackgroundContext()
        context.persistentStoreCoordinator = container.persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    public func deleteDatabase(rebuild: Bool, completion: @escaping (Error?) -> Void) {
        guard let storeURL = storeType.url else {
            completion(nil)
            return
        }

        guard !persistentStores.isEmpty else {
            if rebuild {
                addDefaultPersistentStores(async: shouldLoadAsynchronously, completion: completion)
            } else {
                completion(nil)
            }
            return
        }

        NotificationCenter.default.post(name: .willDestroyMainContext, object: mainContext)

        var mPersistentStores = persistentStores
        persistentStores.enumerated().forEach { idx, persistentStore in
            do {
                try persistentStoreCoordinator.remove(persistentStore)
            } catch let error {
                Logger.error("Error removing persistent store #\(idx) \(persistentStore): \(error)")
            }

            mPersistentStores.remove(at: idx)
        }
        persistentStores = mPersistentStores

        do {
            if FileManager.default.fileExists(atPath: storeURL.path, isDirectory: nil) {
                try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: storeType.coreDataType, options: nil)
                try FileManager.default.removeItem(atPath: storeURL.path)
            }
        } catch let error {
            Logger.error("Error destroying persistent store at \(storeURL): \(error)")
        }

        if rebuild {
            addDefaultPersistentStores(async: shouldLoadAsynchronously, completion: completion)
            return
        }

        completion(nil)
    }


    // MARK: Private functions

    private func addDefaultPersistentStores(async: Bool, completion: @escaping (DataAccessError?) -> Void) {
        var callCount = 0
        let totalCount = container.persistentStoreDescriptions.count
        var errors: [DataAccessError] = []

        shouldLoadAsynchronously = async
        container.persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = async }
        container.loadPersistentStores { [weak self] storeDescription, error in
            callCount += 1

            if let error = error {
                errors.append(.preparationError(error))
            } else if let url = storeDescription.url, let store = self?.container.persistentStoreCoordinator.persistentStore(for: url) {
                Logger.info("Initializing persistent store at \(url.path).")
                self?.persistentStores.append(store)
            }

            guard callCount >= totalCount else {
                return
            }
            completion(errors.first)
        }
    }
}


// MARK: - Notifications

extension Notification.Name {
    static let didCreateNewMainContext = Notification.Name("didCreateNewMainContext")
    static let willDestroyMainContext = Notification.Name("willDestroyMainContext")
}

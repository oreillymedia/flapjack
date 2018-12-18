//
//  CoreDataAccess.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 10/14/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData
#if !COCOAPODS
import Flapjack
#endif

public final class CoreDataAccess: DataAccess {
    public static let didCreateNewMainContextNotification = Notification.Name("com.oreillymedia.flapjack.didCreateNewMainContext")
    public static let willDestroyMainContextNotification = Notification.Name("com.oreillymedia.flapjack.willDestroyMainContext")

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

    public weak var delegate: DataAccessDelegate?
    public private(set) var isStackReady: Bool = false
    private let storeType: StoreType
    private let container: NSPersistentContainer
    private var shouldLoadAsynchronously: Bool = false
    private lazy var dispatchQueue = DispatchQueue(label: "com.oreillymedia.flapjack.coreDataAccessQueue")
    private var persistentStores = [NSPersistentStore]()
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        return container.persistentStoreCoordinator
    }


    // MARK: Lifecycle

    public init(name: String, type: StoreType, model: NSManagedObjectModel? = nil, delegate: DataAccessDelegate? = nil) {
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

        migrateIfNecessary(async: asynchronously) { [weak self] error in
            guard let self = self, error == nil else {
                // Notify the caller; if they so choose, they can nuke the data store and rebuild it
                completion(error)
                return
            }

            self.addDefaultPersistentStores(async: asynchronously) { [weak self] fatalError in
                guard let self = self, fatalError == nil else {
                    completion(fatalError)
                    return
                }

                self.container.viewContext.automaticallyMergesChangesFromParent = true
                self.isStackReady = true
                NotificationCenter.default.post(name: type(of: self).didCreateNewMainContextNotification, object: self.mainContext)
                completion(nil)
            }
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

        NotificationCenter.default.post(name: type(of: self).willDestroyMainContextNotification, object: mainContext)

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

    /**
     Asks the delegate for a migrator object, and if given one, performs migration operations in either the background
     or in the calling thread.

     - parameter async: If `true`, operation will be performed in our background thread.
     - parameter completion: A block to be called upon completion; will be passed an error if one occurred. If `async`
                             is `true`, this will be called on our background thread.
     */
    private func migrateIfNecessary(async: Bool, completion: @escaping (DataAccessError?) -> Void) {
        guard let migrator = delegate?.dataAccess(self, wantsMigratorForStoreAt: self.storeType.url), !migrator.storeIsUpToDate else {
            completion(nil)
            return
        }

        let toExecute = {
            do {
                try migrator.migrate()
            } catch let error {
                // If a migration fails, notify the caller, who can then choose to nuke the data store and try again,
                //   or perform some other action
                completion(.preparationError(error))
            }
        }

        if async {
            dispatchQueue.async(execute: toExecute)
        } else {
            toExecute()
        }
    }

    /**
     Asks Core Data to go through its list of persistent stores and add them one by one.

     - parameter async: If `true`, operation will be performed asynchronously according to Core Data.
     - parameter completion: A block to be called upon completion; will be passed an error if one occurred. If `async`
                             is `true`, this will be dispatched out to the main thread. If `false`, this function
                             assumes it's being called on the main thread already, and the completion block will be
                             called on the main/calling thread.
     */
    private func addDefaultPersistentStores(async: Bool, completion: @escaping (DataAccessError?) -> Void) {
        var errors: [DataAccessError] = []

        shouldLoadAsynchronously = async
        container.persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = async }

        let group = DispatchGroup()
        group.enter()
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error {
                errors.append(.preparationError(error))
            } else if let url = storeDescription.url, let store = self?.container.persistentStoreCoordinator.persistentStore(for: url) {
                Logger.info("Initializing persistent store at \(url.path).")
                self?.persistentStores.append(store)
            }
            group.leave()
        }

        if async {
            group.notify(queue: .main) {
                completion(errors.first)
            }
        } else {
            completion(errors.first)
        }
    }
}

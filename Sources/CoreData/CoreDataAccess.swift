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

/**
 Presides over the setup and management of the entire Core Data stack, along with managing the lifecycle of background
 context operations. Background contexts use the `NSMergeByPropertyStoreTrumpMergePolicy` merge policy, and will share
 a persistent store with the `mainContext`, and change synchronization between the contexts are performed by
 `NSPersistentContainer`.
 */
public final class CoreDataAccess: DataAccess {
    public static let didCreateNewMainContextNotification = Notification.Name("com.oreillymedia.flapjack.didCreateNewMainContext")
    public static let willDestroyMainContextNotification = Notification.Name("com.oreillymedia.flapjack.willDestroyMainContext")

    public enum StoreType {
        case sql(filename: String)
        case memory

        public var url: URL? {
            switch self {
            case .sql(let name):
                return storeUrl(for: name)
            case .memory:
                return nil
            }
        }

        public var coreDataType: String {
            switch self {
            case .sql: return NSSQLiteStoreType
            case .memory: return NSInMemoryStoreType
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

        private func storeUrl(for name: String) -> URL {
            return NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(name)
        }
    }

    public weak var delegate: DataAccessDelegate?
    public private(set) var isStackReady: Bool = false
    private let storeType: StoreType
    private let container: NSPersistentContainer
    private var shouldLoadAsynchronously: Bool = false
    private var defaultContextPolicy: NSMergePolicy = .error
    private lazy var dispatchQueue = DispatchQueue(label: "com.oreillymedia.flapjack.coreDataAccessQueue")

    public var managedObjectModel: NSManagedObjectModel {
        return container.managedObjectModel
    }
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        return container.persistentStoreCoordinator
    }
    public var persistentStores: [NSPersistentStore] {
        return persistentStoreCoordinator.persistentStores
    }


    // MARK: Lifecycle

    public init(name: String, type: StoreType, model: NSManagedObjectModel? = nil, delegate: DataAccessDelegate? = nil, defaultPolicy: NSMergePolicy = .mergeByPropertyStoreTrump) {
        self.storeType = type
        if let model = model {
            self.container = NSPersistentContainer(name: name, managedObjectModel: model)
        } else {
            self.container = NSPersistentContainer(name: name)
        }
        self.container.persistentStoreDescriptions = [type.storeDescription]
        self.delegate = delegate
        self.defaultContextPolicy = defaultPolicy
        self.container.viewContext.mergePolicy = self.defaultContextPolicy
    }


    // MARK: DataAccess

    /// The main thread, view-layer context. Should generally only be used for read-only operations.
    public var mainContext: DataContext {
        return container.viewContext
    }

    /**
     Load up its store from disk (or in memory), asks for any migrations needed, populates the necessary instance
     variables for accessing it, and sets the `isStackReady` property to `true` if everything succeeded.

     - parameter asynchronously: If `true`, the stack preparation will be performed in a background thread, and the
                                 `completion` block will return on the main thread.
     - parameter completion: A closure to be called upon completion. If `asynchronously` is `true`, this is guaranteed
                             to be called on the main thread. If `false`, it will be called on the calling thread.
     */
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

            self.addDefaultPersistentStores(async: asynchronously) { fatalError in
                guard fatalError == nil else {
                    completion(fatalError)
                    return
                }

                completion(nil)
            }
        }
    }

    /**
     Prepares a background-thread context for use, and then pops into a background thread and calls the `operation`.
     Basically wraps Core Data's `NSPersistentContainer.performBackgroundTask(_:)`.

     - parameter operation: The actions to execute upon the background `DataContext`; will be passed said context.
     */
    public func performInBackground(operation: @escaping (_ context: DataContext) -> Void) {
        container.performBackgroundTask { [weak self] context in
            context.mergePolicy = self?.defaultContextPolicy ?? .error
            operation(context)
        }
    }

    /**
     Prepares a background-thread `DataContext` for use, and then returns that context right away on the calling thread.
     It should be the caller's responsibility to use the context responsibly.

     - returns: A background-thread-ready `DataContext`.
     */
    public func vendBackgroundContext() -> DataContext {
        let context = container.newBackgroundContext()
        context.persistentStoreCoordinator = container.persistentStoreCoordinator
        context.mergePolicy = defaultContextPolicy
        return context
    }

    /**
     Deletes the data store from disk if the Core Data container uses SQLite backing stores. If in memory, the in-memory
     context is wiped and started anew.

     - parameter rebuild: If `true`, the data store will be reconstructed after it's deleted.
     - parameter completion: A closure to be called upon completion.
     */
    public func deleteDatabase(rebuild: Bool, completion: @escaping (DataAccessError?) -> Void) {
        let fileExistsAtPath = storeType.url.map { FileManager.default.fileExists(atPath: $0.path, isDirectory: nil) } ?? false

        // If we've never attached any store, delete any stale file that may be there and add them
        //   anew with `addDefaultPersistentStores(async:completion:)`.
        guard !persistentStores.isEmpty else {
            if let storeURL = storeType.url, fileExistsAtPath {
                do {
                    try FileManager.default.removeItem(atPath: storeURL.path)
                } catch let error {
                    Logger.error("Error destroying persistent store at \(storeURL): \(error)")
                }
            }
            if rebuild {
                addDefaultPersistentStores(async: shouldLoadAsynchronously, completion: completion)
            } else {
                completion(nil)
            }
            return
        }

        // Let listeners know we're about to detach our store from our coordinator, and then do it.
        NotificationCenter.default.post(name: type(of: self).willDestroyMainContextNotification, object: mainContext)
        let localPersistentStores = persistentStores
        localPersistentStores.enumerated().forEach { idx, persistentStore in
            do {
                try persistentStoreCoordinator.remove(persistentStore)
            } catch let error {
                Logger.error("Error removing persistent store #\(idx) \(persistentStore): \(error)")
            }
        }

        // Now that we've detached the store from the coordinator, 
        if let storeURL = storeType.url, fileExistsAtPath {
            do {
                try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: storeType.coreDataType, options: nil)
                try FileManager.default.removeItem(atPath: storeURL.path)
            } catch let error {
                Logger.error("Error destroying persistent store at \(storeURL): \(error)")
            }
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
                completion(nil)
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
        container.loadPersistentStores { _, error in
            if let error = error {
                errors.append(.preparationError(error))
            }
            group.leave()
        }

        let finally: ([DataAccessError]) -> Void = { [weak self] errors in
            if errors.isEmpty, let self = self {
                self.container.viewContext.automaticallyMergesChangesFromParent = true
                self.isStackReady = true
                NotificationCenter.default.post(name: type(of: self).didCreateNewMainContextNotification, object: self.mainContext)
            }
            completion(errors.first)
        }

        if async {
            group.notify(queue: .main) {
                finally(errors)
            }
        } else {
            finally(errors)
        }
    }
}

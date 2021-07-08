//
//  DataAccess.swift
//  Flapjack
//
//  Created by Ben Kreeger on 10/13/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation


// MARK: - DataAccess

/**
 One of two prominently-used objects in Flapjack, the `DataAccess` protocol (and those that conform to it) preside over
 the setup and management of the entire data persistence stack, along with managing the lifecycle of background context
 operations.
 */
public protocol DataAccess {
    /// The main thread (or view-layer) context. Should generally only be used for read-only operations.
    var mainContext: DataContext { get }
    /// This should be `true` if the stack has been setup in memory and ready to go; `false` otherwise.
    var isStackReady: Bool { get }
    /// The object that agrees to be notified about special events and requests from `DataAccess`; optional.
    var delegate: DataAccessDelegate? { get set }

    /**
     Invoking this method should ask the `DataAccess` object to load up its store from disk (or in memory), ask for any
     migrations needed, populate the necessary instance variables for accessing it, and set the `isStackReady` property
     to `true` if everything succeeded.

     - parameter asynchronously: If `true`, the stack preparation should be performed in a background thread, and the
                                 `completion` block should return on the main thread.
     - parameter completion: A closure to be called upon completion. If `asynchronously` is `true`, this should be
                             guaranteed to be called on the main thread. If `false`, it should be called on the calling
                             thread.
     */
    func prepareStack(asynchronously: Bool, completion: @escaping (DataAccessError?) -> Void)

    /**
     Invoking this method should ask the `DataAccess` object to prepare a background-thread `DataContext` for use, and
     then pop into a background thread and call the `operation`.

     - parameter operation: The actions to execute upon the background `DataContext`; will be passed said context.
     */
    func performInBackground(operation: @escaping (_ context: DataContext) -> Void)

    /**
     Invoking this method should ask the `DataAccess` object to prepare a background-thread `DataContext` for use, and
     then return that context right away on the calling thread. It should be the caller's responsibility to use the
     context responsibly.

     - returns: A background-thread-ready `DataContext`.
     */
    func vendBackgroundContext() -> DataContext

    /**
     Invoking this method should ask the `DataAccess` object to delete the data store in a matter it sees fit. If asked
     to `rebuild` the database, it should do so in a manner consistent with the one performed in
     `prepareStack(asynchronously:completion:)`.

     - parameter rebuild: If `true`, the data store should be reconstructed after it's deleted.
     - parameter completion: A closure to be called upon completion.
     */
    func deleteDatabase(rebuild: Bool, completion: @escaping (DataAccessError?) -> Void)
}


// MARK: - DataAccessDelegate

/**
 An object conforming to the `DataAccessDelegate` agrees to be notified about events occurring outside the normal
 call-and-return lifecycle of the methods presented by conformists to `DataAccess`.
 */
public protocol DataAccessDelegate: AnyObject {
    /**
     Called when the data access object is about to setup the data stack (from on disk into application memory), and if
     necessary (given the on-disk store at the given URL), should be returned a `Migrator` object if migrations should
     be performed. The `DataAccess` object should check with the provider if migrations should actually be performed,
     and it's the `Migrator`'s responsibility to deal with the store at the URL to see if it's up-to-date (for more
     information, see the documentation for `Migrator`).

     - parameter dataAccess: The object calling this method.
     - parameter storeURL: The on-disk location where the store is located; if there is no on-disk store (like if the
                           store is in-memory only), this will be `nil`.
     - returns: Should return a `Migrator` object if one needs to be consulted with to begin migrations; `nil` if not.
     */
    func dataAccess(_ dataAccess: DataAccess, wantsMigratorForStoreAt storeURL: URL?) -> Migrator?
}

public extension DataAccessDelegate {
    /// The default implementation of this delegate method returns `nil` for the `Migrator`.
    func dataAccess(_ dataAccess: DataAccess, wantsMigratorForStoreAt storeURL: URL?) -> Migrator? {
        return nil
    }
}

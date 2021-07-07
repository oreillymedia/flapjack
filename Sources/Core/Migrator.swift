//
//  Migrator.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/30/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 Describes an object responsible for determining if content should be migrated, and for doing so.
 */
public protocol Migrator {
    /// If `true`, migrations do not need to be performed, and calling migrate() is a no-op.
    var storeIsUpToDate: Bool { get }

    /**
     Performs the migration by setting up temp directories and iterating over all model versions. If an error occurs,
     it will be thrown as a MigratorError.

     - returns: `true` if a migration was performed, `false` if one was not needed.
     */
    @discardableResult
    func migrate() throws -> Bool
}

/**
 An error potentially thrown by an object conforming to the `Migrator` protocol.
 */
public enum MigratorError: Error {
    /// Indicates a failure creating a destination folder, or creating the database on the file system.
    case diskPreparationError
    /// Indicates a failure setting up the stack, by whatever database technology is doing so.
    case proceduralError(Error)
    /// Indicates a failure occurring during database removal or other cleanup procedure.
    case cleanupError(Error)
}

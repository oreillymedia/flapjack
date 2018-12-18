//
//  Migrator.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/30/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

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


public enum MigratorError: Error {
    case diskPreparationError
    case proceduralError(Error)
    case cleanupError(Error)
}

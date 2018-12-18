//
//  MockMigrator.swift
//  Tests
//
//  Created by Ben Kreeger on 12/18/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

@testable import Flapjack
@testable import FlapjackCoreData

class MockMigrator: Migrator {
    var storeIsUpToDate: Bool = false
    var errorToThrow: MigratorError?
    var simulateMigration: Bool = false

    func migrate() throws -> Bool {
        if let error = errorToThrow {
            throw error
        }
        return simulateMigration
    }
}

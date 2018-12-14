//
//  MockMigrationPolicy.swift
//  Tests
//
//  Created by Ben Kreeger on 12/14/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData

@testable import Flapjack
@testable import FlapjackCoreData

@objc(MockMigrationPolicy)
class MockMigrationPolicy: MigrationPolicy {
    override var migrations: [String: MigrationOperation] {
        return [
            "EntityToMigrateToMigratedEntity": entityMigration
        ]
    }

    private var entityMigration: MigrationOperation {
        return { manager, source, destination in
            if let sourceValue = source.value(forKey: "renamedProperty") as? Int32 {
                destination?.setValue(String(sourceValue), forKey: "convertedProperty")
            }
        }
    }
}

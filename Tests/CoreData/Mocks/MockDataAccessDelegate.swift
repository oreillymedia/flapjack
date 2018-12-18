//
//  MockDataAccessDelegate.swift
//  Tests
//
//  Created by Ben Kreeger on 12/18/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData

@testable import Flapjack
@testable import FlapjackCoreData

class MockDataAccessDelegate: DataAccessDelegate {
    var migrator: Migrator?

    var wantsMigratorForStoreAtCalled: (called: Bool, url: URL?) = (false, nil)
    func dataAccess(_ dataAccess: DataAccess, wantsMigratorForStoreAt storeURL: URL?) -> Migrator? {
        wantsMigratorForStoreAtCalled = (true, storeURL)
        return migrator
    }
}

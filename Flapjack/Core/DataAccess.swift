//
//  DataAccess.swift
//  Flapjack
//
//  Created by Ben Kreeger on 10/13/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation


// MARK: - DataAccess

public protocol DataAccess {
    var mainContext: DataContext { get }
    var isStackReady: Bool { get }
    var delegate: DataAccessDelegate? { get set }

    func prepareStack(asynchronously: Bool, completion: @escaping (DataAccessError?) -> Void)
    func performInBackground(operation: @escaping (_ context: DataContext) -> Void)
    func vendBackgroundContext() -> DataContext
    func deleteDatabase(rebuild: Bool, completion: @escaping (Error?) -> Void)
}


// MARK: - DataAccessDelegate

public protocol DataAccessDelegate: AnyObject {
    func dataAccess(_ dataAccess: DataAccess, wantsMigratorForStoreAt storeURL: URL?) -> Migrator?
}

public extension DataAccessDelegate {
    func dataAccess(_ dataAccess: DataAccess, wantsMigratorForStoreAt storeURL: URL?) -> Migrator? {
        return nil
    }
}

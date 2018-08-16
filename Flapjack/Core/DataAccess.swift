//
//  DataAccess.swift
//  Flapjack
//
//  Created by Ben Kreeger on 10/13/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public protocol DataAccess {
    var mainContext: DataContext { get }
    func prepareStack(asynchronously: Bool, completion: @escaping (DataAccessError?) -> Void)
    func performInBackground(operation: @escaping (_ context: DataContext) -> Void)
    func vendBackgroundContext() -> DataContext
    func deleteDatabase(rebuild: Bool, completion: @escaping (Error?) -> Void)
}

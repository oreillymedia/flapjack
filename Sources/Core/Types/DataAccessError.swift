//
//  DataAccessError.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 Encapsulates error state when thrown by the `DataAccess` object. Generally this is related to stack preparation.
 */
public enum DataAccessError: LocalizedError, CustomStringConvertible {
    /// Indicates an error was thrown while preparing the stack; includes the underlying error.
    case preparationError(Error)

    public var description: String {
        switch self {
        case .preparationError:
            return "DataAccessError.preparationError: \(localizedDescription)"
        }
    }

    public var localizedDescription: String {
        switch self {
        case .preparationError(let error):
            if let error = error as? LocalizedError {
                return error.localizedDescription
            }
            return (error as NSError?)?.localizedDescription ?? "unknown error"
        }
    }
}

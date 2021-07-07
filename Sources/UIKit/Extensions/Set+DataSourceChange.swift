//
//  Set+DataSourceChange.swift
//  FlapjackUIKit
//
//  Created by Ben Kreeger on 12/20/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
#if !COCOAPODS
import Flapjack
#endif

internal extension Set where Element == DataSourceChange {
    var components: (inserts: [IndexPath], deletes: [IndexPath], moves: [(from: IndexPath, to: IndexPath)], updates: [IndexPath]) {
        var tuple: (inserts: [IndexPath], deletes: [IndexPath], moves: [(from: IndexPath, to: IndexPath)], updates: [IndexPath]) = ([], [], [], [])
        forEach { element in
            switch element {
            case .insert(let path): tuple.inserts.append(path)
            case .delete(let path): tuple.deletes.append(path)
            case .move(let fromPath, let toPath): tuple.moves.append((fromPath, toPath))
            case .update(let path): tuple.updates.append(path)
            }
        }
        return tuple
    }
}

internal extension Set where Element == DataSourceSectionChange {
    var components: (inserts: IndexSet, deletes: IndexSet) {
        var tuple: (inserts: IndexSet, deletes: IndexSet) = ([], [])
        forEach { element in
            switch element {
            case .insert(let section): tuple.inserts.insert(section)
            case .delete(let section): tuple.deletes.insert(section)
            }
        }
        return tuple
    }
}

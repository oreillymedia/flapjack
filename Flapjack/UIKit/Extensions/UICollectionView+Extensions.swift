//
//  UICollectionView+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 07/19/2018.
//  Copyright (c) 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import UIKit
#if !COCOAPODS
import Flapjack
#endif

public extension UICollectionView {
    /**
     Divvies up the changes passed in and forwards the calls to native iOS APIs for performing batch changes in a
     `UICollectionView`. Provides a convenience API for not having to do this yourself!

     - parameter objectChanges: A set of change enumerations coming from a collection-observing `DataSource`.
     - parameter sectionChanges: A set of section change enumerations coming from a collection-observing `DataSource`.
     - parameter completion: A block to be called upon completion. The included boolean indicates if the animations
                             finished successfully.
     */
    func performBatchUpdates(_ objectChanges: Set<DataSourceChange>, sectionChanges: Set<DataSourceSectionChange> = [], completion: ((Bool) -> Void)? = nil) {
        guard superview != nil, !objectChanges.isEmpty else {
            return
        }
        let (inserts, deletes, moves, updates) = objectChanges.components
        let (sectionInserts, sectionDeletes) = sectionChanges.components
        performBatchUpdates({
            if !sectionDeletes.isEmpty { deleteSections(sectionDeletes) }
            if !sectionInserts.isEmpty { insertSections(sectionInserts) }
            if !deletes.isEmpty { deleteItems(at: deletes) }
            if !inserts.isEmpty { insertItems(at: inserts) }
            if !updates.isEmpty { reloadItems(at: updates) }
            moves.forEach { moveItem(at: $0, to: $1) }
        }, completion: completion)
    }
}

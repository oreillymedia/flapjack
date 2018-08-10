//
//  UICollectionView+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 07/19/2018.
//  Copyright (c) 2018 O'Reilly Media, Inc. All rights reserved.
//

public extension UICollectionView {
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

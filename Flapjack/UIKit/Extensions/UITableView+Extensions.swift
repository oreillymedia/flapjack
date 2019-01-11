//
//  UITableView+Extensions.swift
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

public extension UITableView {
    /**
     Divvies up the changes passed in and forwards the calls to native iOS APIs for performing batch changes in a
     `UITableView`. Provides a convenience API for not having to do this yourself!

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

        performBatchUpdates({ [weak self] in
            guard let `self` = self else {
                return
            }
            if !sectionDeletes.isEmpty { self.deleteSections(sectionDeletes, with: .automatic) }
            if !sectionInserts.isEmpty { self.insertSections(sectionInserts, with: .automatic) }
            if !deletes.isEmpty { self.deleteRows(at: deletes, with: .automatic) }
            if !inserts.isEmpty { self.insertRows(at: inserts, with: .automatic) }
            if !updates.isEmpty { self.reloadRows(at: updates, with: .automatic) }
            moves.forEach { self.moveRow(at: $0, to: $1) }
        }, completion: completion)
    }
}

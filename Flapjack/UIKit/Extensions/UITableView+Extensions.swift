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
    func performBatchUpdates(_ objectChanges: [DataSourceChange], sectionChanges: [DataSourceSectionChange] = [], completion: ((Bool) -> Void)? = nil) {
        guard superview != nil, !objectChanges.isEmpty else {
            return
        }

        performBatchUpdates({
            for change in objectChanges {
                switch change {
                case .insert(let path):
                    insertRows(at: [path], with: .automatic)
                case .delete(let path):
                    deleteRows(at: [path], with: .automatic)
                case .move(let fromPath, let toPath):
                    deleteRows(at: [fromPath], with: .automatic)
                    insertRows(at: [toPath], with: .automatic)
                case .update(let path):
                    reloadRows(at: [path], with: .automatic)
                }
            }
            for sectionChange in sectionChanges {
                switch sectionChange {
                case .insert(let section):
                    insertSections(IndexSet(integer: section), with: .automatic)
                case .delete(let section):
                    deleteSections(IndexSet(integer: section), with: .automatic)
                }
            }
        }, completion: completion)
    }
}

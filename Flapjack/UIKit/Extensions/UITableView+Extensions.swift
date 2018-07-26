//
//  UITableView+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 07/19/2018.
//  Copyright (c) 2018 kreeger. All rights reserved.
//

public extension UITableView {
    public func performBatchUpdates(_ objectChanges: Set<DataSourceChange>, sectionChanges: Set<DataSourceSectionChange> = [], completion: ((Bool) -> Void)? = nil) {
        guard superview != nil, !objectChanges.isEmpty else { return }
        let (inserts, deletes, moves, updates) = objectChanges.components
        let (sectionInserts, sectionDeletes) = sectionChanges.components
        
        let changesToPerform: () -> Void = { [weak self] in
            guard let `self` = self else { return }
            if !sectionDeletes.isEmpty { self.deleteSections(sectionDeletes, with: .automatic) }
            if !sectionInserts.isEmpty { self.insertSections(sectionInserts, with: .automatic) }
            if !deletes.isEmpty { self.deleteRows(at: deletes, with: .automatic) }
            if !inserts.isEmpty { self.insertRows(at: inserts, with: .automatic) }
            if !updates.isEmpty { self.reloadRows(at: updates, with: .automatic) }
            moves.forEach { self.moveRow(at: $0, to: $1) }
        }
        
        if #available(iOS 11.0, *) {
            performBatchUpdates(changesToPerform, completion: completion)
        } else {
            beginUpdates()
            changesToPerform()
            endUpdates()
            completion?(true)
        }
    }
}

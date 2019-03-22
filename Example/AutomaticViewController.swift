//
//  AutomaticViewController.swift
//  Flapjack
//
//  Created by kreeger on 07/19/2018.
//  Copyright (c) 2018 O'Reilly Media, Inc. All rights reserved.
//

import UIKit
import Flapjack
// These imports are necessary if you're importing the framework manually or via Carthage.
import FlapjackCoreData
import FlapjackUIKit

class AutomaticViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var maker: PancakeMaker!
    var dataSource: CoreDataSource<Pancake>! {
        didSet {
            dataSource.onChange = { itemChanges, sectionChanges in
                self.tableView.performBatchUpdates(itemChanges, sectionChanges: sectionChanges)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.startListening()
    }


    // MARK: Actions

    @IBAction private func addButtonTapped(_ sender: UIBarButtonItem) {
        maker.makePancake { [weak self] _, error in
            if let error = error {
                self?.displayAlert(for: error.localizedDescription)
            }
        }
    }


    // MARK: Private functions

    private func displayAlert(for message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


extension AutomaticViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfObjects(in: section)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < dataSource.sectionNames.count else {
            return nil
        }
        return dataSource.sectionNames[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        if let model = dataSource.object(at: indexPath) {
            cell.textLabel?.text = "\(model.radius)\" radius, \(model.height)\" tall"
            cell.detailTextLabel?.text = model.identifier
        }
        return cell
    }
}


extension AutomaticViewController: UITableViewDelegate {

}

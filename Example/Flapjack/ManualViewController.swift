//
//  ManualViewController.swift
//  Flapjack
//
//  Created by kreeger on 07/19/2018.
//  Copyright (c) 2018 kreeger. All rights reserved.
//

import UIKit
import Flapjack

class ManualViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var maker: PancakeMaker!
    var dataAccess: DataAccess! {
        didSet {
            pancakes = dataAccess.mainContext.objects(ofType: Pancake.self)
            tableView.reloadData()
        }
    }
    
    private var pancakes = [Pancake]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pancakes = dataAccess?.mainContext.objects(ofType: Pancake.self) ?? []
        tableView.reloadData()
    }
    
    
    // MARK: Actions
    
    @IBAction private func addButtonTapped(_ sender: UIBarButtonItem) {
        maker.makePancake { [weak self] (pancake, error) in
            guard let `self` = self else { return }
            if let error = error {
                self.displayAlert(for: error.localizedDescription)
            }
            self.pancakes = self.dataAccess.mainContext.objects(ofType: Pancake.self)
            self.tableView.reloadData()
        }
    }
    
    @IBAction private func refreshButtonTapped(_ sender: UIBarButtonItem) {
        pancakes = dataAccess.mainContext.objects(ofType: Pancake.self)
        tableView.reloadData()
    }
    
    
    // MARK: Private functions
    
    private func displayAlert(for message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


extension ManualViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pancakes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        if indexPath.item < pancakes.count {
            let model = pancakes[indexPath.item]
            let display = "\(model.flavor ?? "Flavorless"), \(model.radius)\" radius, \(model.height)\" tall"
            cell.textLabel?.text = display
            cell.detailTextLabel?.text = model.identifier
        }
        return cell
    }
}


extension ManualViewController: UITableViewDelegate {
    
}

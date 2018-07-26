//
//  AppDelegate.swift
//  Flapjack
//
//  Created by kreeger on 07/19/2018.
//  Copyright (c) 2018 kreeger. All rights reserved.
//

import UIKit
import Flapjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    lazy var dataAccess: DataAccess = CoreDataAccess(name: "FlapjackExample", type: .memory)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let dataSourceFactory = CoreDataSourceFactory(dataAccess: dataAccess)
        let maker = PancakeMaker(dataAccess: dataAccess)
        
        let manualVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ManualViewController") as! ManualViewController
        let manualNav = UINavigationController(rootViewController: manualVC)
        manualVC.title = "Manual Refresh"
        manualVC.maker = maker
        
        let autoVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "AutomaticViewController") as! AutomaticViewController
        let autoNav = UINavigationController(rootViewController: autoVC)
        autoVC.title = "Auto Refresh"
        autoVC.maker = maker
        
        dataAccess.prepareStack { [weak self] (error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            manualVC.dataAccess = self?.dataAccess
            autoVC.dataSource = dataSourceFactory.vendObjectsDataSource(attributes: [:], sectionProperty: "flavor", limit: nil)
        }
        
        let tabVC = UITabBarController()
        tabVC.viewControllers = [manualNav, autoNav]
        window.rootViewController = tabVC
        window.makeKeyAndVisible()
        return true
    }
}

//
//  AppDelegate.swift
//  Flapjack
//
//  Created by kreeger on 07/19/2018.
//  Copyright (c) 2018 O'Reilly Media, Inc. All rights reserved.
//

import UIKit
import Flapjack
// This import is necessary if you're importing the framework manually or via Carthage.
import FlapjackCoreData

#if swift(>=4.2)
#else
extension UIApplication {
    typealias LaunchOptionsKey = UIApplicationLaunchOptionsKey
}
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    lazy var dataAccess: DataAccess = CoreDataAccess(name: "FlapjackExample", type: .memory)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        let dataSourceFactory = CoreDataSourceFactory(dataAccess: dataAccess)
        let maker = PancakeMaker(dataAccess: dataAccess)

        guard
            let manualVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ManualViewController") as? ManualViewController,
            let autoVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "AutomaticViewController") as? AutomaticViewController
        else {
            return false
        }
        let manualNav = UINavigationController(rootViewController: manualVC)
        manualVC.title = "Manual Refresh"
        manualVC.maker = maker

        let autoNav = UINavigationController(rootViewController: autoVC)
        autoVC.title = "Auto Refresh"
        autoVC.maker = maker

        dataAccess.prepareStack(asynchronously: true) { [weak self] error in
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

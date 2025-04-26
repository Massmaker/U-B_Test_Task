//
//  AppDelegate.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window:UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let rootVC = Composer.createListScreenSuite()
        let aWindow = UIWindow(frame: UIScreen.main.bounds)
        
        let navigationController = UINavigationController(rootViewController: rootVC)

        aWindow.rootViewController = navigationController
        aWindow.makeKeyAndVisible()
        
        self.window = aWindow
        
        return true
    }


}


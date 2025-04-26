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
        
        let rootVC = ViewController()
        let aWindow = UIWindow(frame: UIScreen.main.bounds)
        aWindow.rootViewController = rootVC
        aWindow.makeKeyAndVisible()
        
        self.window = aWindow
        
        return true
    }


}


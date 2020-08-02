//
//  AppDelegate.swift
//  DownFall
//
//  Created by William Katz on 5/9/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

import UIKit
import Combine

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var disposables = Set<AnyCancellable>()
    var gameViewController: GameViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let gameViewController = GameViewController(nibName: nil, bundle: nil)
        self.gameViewController = gameViewController
        
        GameScope.shared.profileManager.loadedProfile.sink(receiveCompletion: { _ in }) { (profile) in
            gameViewController.profile = profile
        }.store(in: &disposables)
        
        // Start the authentication process
        GameScope.shared.profileManager.start(gameViewController)
        
        // window
        window!.rootViewController = gameViewController
        window!.makeKeyAndVisible()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        guard let profile = gameViewController?.applicationDidEnterBackground() else { fatalError("Cannot save the profile") }
        
        GameScope.shared.profileManager.saveProfile(profile)
        
    }
}


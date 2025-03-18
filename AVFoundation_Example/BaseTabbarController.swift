//
//  BaseTabbarController.swift
//  AVFoundation_Example
//
//  Created by Quân Nguyễn on 18/3/25.
//

import Foundation
import UIKit

class BaseTabbarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        setupTabbarController()
    }
    
    func setupTabbarController() {
        let avPlayerVC = AVPlayerVC()
        let avCaptureSessionVC = AVCaptureSessionVC()
        let avAssetVC = AVAssetVC()
        let avAudioSessionVC = AVAudioSessionVC()
        
        let avPlayerNav = UINavigationController(rootViewController: avPlayerVC)
        let avCaptureSessionNav = UINavigationController(rootViewController: avCaptureSessionVC)
        let avAssetNav = UINavigationController(rootViewController: avAssetVC)
        let avAudioSessionNav = UINavigationController(rootViewController: avAudioSessionVC)
        
        avPlayerNav.tabBarItem = UITabBarItem( title: "AVPlayer",
                                           image: UIImage(systemName: "house.fill"),
                                           selectedImage: nil)
        
        avCaptureSessionNav.tabBarItem = UITabBarItem( title: "AVCapture",
                                           image: UIImage(systemName: "house.fill"),
                                           selectedImage: nil)
        
        avAssetNav.tabBarItem = UITabBarItem( title: "AVAsset",
                                           image: UIImage(systemName: "house.fill"),
                                           selectedImage: nil)
        
        avAudioSessionNav.tabBarItem = UITabBarItem( title: "AVAudio",
                                           image: UIImage(systemName: "house.fill"),
                                           selectedImage: nil)
        self.viewControllers = [avPlayerNav, avCaptureSessionNav, avAssetNav, avAudioSessionNav]
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            
            self.tabBar.standardAppearance = appearance
            self.tabBar.scrollEdgeAppearance = tabBar.standardAppearance
            self.tabBar.standardAppearance = appearance
            self.tabBar.scrollEdgeAppearance = tabBar.standardAppearance
            UITableView.appearance().sectionHeaderTopPadding = 1
        }
    }    
}

extension BaseTabbarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {

    }
}

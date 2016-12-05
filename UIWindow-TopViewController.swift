//
//  UIWindow-TopViewController.swift
//  GiftTalk-Swift
//
//  Created by Deville Tang on 1/28/16.
//  Copyright © 2016 liwushuo. All rights reserved.
//

import UIKit

extension UIWindow {
    
    private static func topViewController(controller: UIViewController) -> UIViewController
    {
        if let tab = controller as? UITabBarController {
            if let c = tab.selectedViewController
            {
                return topViewController(c)
            }
            else
            {
                return tab
            }
        }
        
        if let nav = controller as? UINavigationController {
            if let c = nav.visibleViewController {
                return topViewController(c)
            }
            else{
                return nav
            }
        }
        
        if let pre = controller.presentedViewController {
            return topViewController(pre)
        }
        
        return controller
    }
    
    public static func topViewController() -> UIViewController? {
        if let controller = UIApplication.sharedApplication().keyWindow?.rootViewController
        {
            return topViewController(controller)
        }
        
        return nil
    }
    
    public static func rootViewController() -> UIViewController? {
        return UIApplication.sharedApplication().keyWindow?.rootViewController
    }
}

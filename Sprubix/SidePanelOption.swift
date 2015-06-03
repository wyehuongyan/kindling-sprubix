//
//  SidePanelOption.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SidePanelOption {
    let image: UIImage?
    let option: Option?
    let viewControllerName: String?
    
    init(option: Option, image: UIImage?, viewControllerName: String? = nil) {
        self.image = image
        self.option = option
        self.viewControllerName = viewControllerName
    }

    enum Option {
        case Messages
        case Notifications
        case CreateOutfit
        case LikedOutfits
        case Settings
        
        func toString()->String {
            switch self {
            case .Messages:
                return "Messages"
            case .Notifications:
                return "Notifications"
            case .CreateOutfit:
                return "Create Outfit"
            case .LikedOutfits:
                return "Liked Outfits"
            case .Settings:
                return "Settings"
            }
        }
    }
    
    // notifications for each side menu option
    struct alerts {
        static var counter:[String:Int] = [
            SidePanelOption.Option.Messages.toString(): 0,
            SidePanelOption.Option.Notifications.toString(): 0,
            SidePanelOption.Option.Settings.toString(): 0
        ]
        
        subscript(type: String) -> Int? {
            get {
                return alerts.counter[type]
            }
            set(value) {
                alerts.counter[type] = value
            }
        }
        
        // get total number of alerts for all options
        static var total: Int? {
            get {
                var totalAlerts = 0
                
                for (alert, counter) in SidePanelOption.alerts.counter {
                    totalAlerts = totalAlerts + counter
                }
                
                return totalAlerts
            }
        }
    }
    
    // create customized option list here
    class func userOptions() -> Array<SidePanelOption> {
        return [
            //SidePanelOption(option: Option.Messages, image: UIImage(named: "sidemenu-messages")),
            SidePanelOption(option: Option.Notifications, image: UIImage(named: "sidemenu-notifications")),
            SidePanelOption(option: Option.CreateOutfit, image: UIImage(named: "sidemenu-create")),
            SidePanelOption(option: Option.LikedOutfits, image: UIImage(named: "sidemenu-likes")),
            SidePanelOption(option: Option.Settings, image: UIImage(named: "sidemenu-settings"))
        ]
    }
}

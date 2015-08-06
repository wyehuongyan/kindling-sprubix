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
        case Activity
        case CreateOutfit
        case Favorites
        case Settings
        case Inventory
        case Cart
        case Orders
        case Refunds
        case DeliveryOptions
        
        func toString()->String {
            switch self {
            case .Messages:
                return "Messages"
            case .Activity:
                return "Activity"
            case .CreateOutfit:
                return "Create Outfit"
            case .Favorites:
                return "Favorites"
            case .Settings:
                return "Settings"
            case .Inventory:
                return "Inventory"
            case .Cart:
                return "My Cart"
            case .Orders:
                return "Orders"
            case .Refunds:
                return "Refunds"
            case .DeliveryOptions:
                return "Delivery Options"
            }
        }
    }
    
    // notifications for each side menu option
    struct alerts {
        static var counter:[String:Int] = [
            SidePanelOption.Option.Messages.toString(): 0,
            SidePanelOption.Option.Activity.toString(): 0,
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
            SidePanelOption(option: Option.Activity, image: UIImage(named: "sidemenu-notifications")),
            SidePanelOption(option: Option.CreateOutfit, image: UIImage(named: "sidemenu-create")),
            SidePanelOption(option: Option.Favorites, image: UIImage(named: "sidemenu-likes")),
            SidePanelOption(option: Option.Cart, image: UIImage(named: "sidemenu-cart")),
            SidePanelOption(option: Option.Orders, image: UIImage(named: "sidemenu-orders")),
            SidePanelOption(option: Option.Refunds, image: UIImage(named: "sidemenu-inventory")),
            SidePanelOption(option: Option.Settings, image: UIImage(named: "sidemenu-settings"))
        ]
    }
    
    class func shopOptions() -> Array<SidePanelOption> {
        return [
            //SidePanelOption(option: Option.Messages, image: UIImage(named: "sidemenu-messages")),
            SidePanelOption(option: Option.Activity, image: UIImage(named: "sidemenu-notifications")),
            SidePanelOption(option: Option.CreateOutfit, image: UIImage(named: "sidemenu-create")),
            SidePanelOption(option: Option.Favorites, image: UIImage(named: "sidemenu-likes")),
            SidePanelOption(option: Option.Orders, image: UIImage(named: "sidemenu-orders")),
            SidePanelOption(option: Option.Refunds, image: UIImage(named: "sidemenu-inventory")),
            SidePanelOption(option: Option.Inventory, image: UIImage(named: "sidemenu-inventory")),
            SidePanelOption(option: Option.DeliveryOptions, image: UIImage(named: "sidemenu-fulfilment")),
            SidePanelOption(option: Option.Settings, image: UIImage(named: "sidemenu-settings"))
        ]
    }
}

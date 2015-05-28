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
    
    // create customized option list here
    class func userOptions() -> Array<SidePanelOption> {
        return [
            SidePanelOption(option: Option.Messages, image: UIImage(named: "sidemenu-messages")),
            SidePanelOption(option: Option.Notifications, image: UIImage(named: "sidemenu-notifications")),
            SidePanelOption(option: Option.CreateOutfit, image: UIImage(named: "sidemenu-create")),
            SidePanelOption(option: Option.LikedOutfits, image: UIImage(named: "sidemenu-likes")),
            SidePanelOption(option: Option.Settings, image: UIImage(named: "sidemenu-settings"))
        ]
    }
}

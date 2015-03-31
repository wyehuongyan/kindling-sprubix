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
    let title: String?
    let viewControllerName: String?
    
    init(title: String, image: UIImage?, viewControllerName: String? = nil) {
        self.image = image
        self.title = title
        self.viewControllerName = viewControllerName
    }
    
    // create customized option list here
    class func userOptions() -> Array<SidePanelOption> {
        return [
            SidePanelOption(title: "Messages", image: UIImage(named: "icon-placeholder.png")),
            SidePanelOption(title: "Notifications", image: UIImage(named: "icon-placeholder.png")),
            SidePanelOption(title: "Create Outfit", image: UIImage(named: "icon-placeholder.png")),
            SidePanelOption(title: "Liked Outfits", image: UIImage(named: "icon-placeholder.png")),
            SidePanelOption(title: "Settings", image: UIImage(named: "icon-placeholder.png"))
        ]
    }
}

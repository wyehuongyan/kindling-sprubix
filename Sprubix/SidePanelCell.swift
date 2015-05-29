//
//  SidePanelCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SidePanelCell: UITableViewCell {
    
    @IBOutlet var sideIcon: UIImageView!
    @IBOutlet var sideLabel: UILabel!

    var viewControllerName: String?
    
    func configureForSidePanelOption(sidePanelOption: SidePanelOption) {
        sideIcon.image = sidePanelOption.image
        sideLabel.textColor = UIColor.darkGrayColor()
        sideLabel.text = sidePanelOption.option?.toString()

        viewControllerName = sidePanelOption.viewControllerName

        // notification num alerts for option
        var numAlerts: Int? = SidePanelOption.alerts.counter[sideLabel.text!]
        
        if numAlerts != nil && numAlerts > 0 {
            let badgeWidth: CGFloat = 20
            var badge: UILabel = UILabel(frame: CGRectMake(10, 5, badgeWidth, badgeWidth))
            
            badge.backgroundColor = sprubixColor
            badge.layer.cornerRadius = badgeWidth / 2
            badge.layer.borderWidth = 1.0
            badge.layer.borderColor = sprubixGray.CGColor
            badge.clipsToBounds = true
            badge.textColor = UIColor.whiteColor()
            badge.textAlignment = NSTextAlignment.Center
            badge.font = UIFont(name: mainBadge.font.fontName, size: 10)
            badge.text = "\(numAlerts!)"
                
            contentView.addSubview(badge)
        }
    }
    
}

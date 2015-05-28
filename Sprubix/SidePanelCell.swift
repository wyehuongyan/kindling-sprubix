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
        sideLabel.text = sidePanelOption.option?.toString()

        viewControllerName = sidePanelOption.viewControllerName
    }
    
}

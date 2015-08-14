//
//  DashboardItemCell.swift
//  Sprubix
//
//  Created by Shion Wah on 8/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class DashboardItemCell: UITableViewCell {
    
    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var itemName: UILabel!
    @IBOutlet var itemSold: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        itemName.textColor = UIColor.darkGrayColor()
        itemSold.textColor = UIColor.darkGrayColor()
        
        itemImageView.layer.cornerRadius = 8.0
        itemImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        itemImageView.layer.borderWidth = 0.5
        itemImageView.clipsToBounds = true
        itemImageView.contentMode = UIViewContentMode.ScaleAspectFill
    }
}
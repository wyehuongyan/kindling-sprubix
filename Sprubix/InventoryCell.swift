//
//  InventoryCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 21/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class InventoryCell: UITableViewCell {

    @IBOutlet var inventoryImage: UIImageView!
    @IBOutlet var accessoryImage: UIImageView!
    
    @IBOutlet var inventoryName: UILabel!
    @IBOutlet var inventoryPrice: UILabel!
    @IBOutlet var inventoryQuantity: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        inventoryImage.layer.cornerRadius = 8.0
        inventoryImage.layer.borderColor = UIColor.lightGrayColor().CGColor
        inventoryImage.layer.borderWidth = 0.5
        inventoryImage.clipsToBounds = true
        
        Glow.addGlow(accessoryImage)
    }
}

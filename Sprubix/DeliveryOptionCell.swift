//
//  DeliveryOptionCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 24/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class DeliveryOptionCell: UITableViewCell {
    
    @IBOutlet var deliveryOptionName: UILabel!
    @IBOutlet var deliveryOptionPrice: UILabel!
    
    @IBOutlet var editDeliveryOptionButton: UIButton!
    @IBOutlet var deleteDeliveryOptionButton: UIButton!
    
    @IBAction func editDeliveryOption(sender: AnyObject) {
        println("edit delivery option")
    }
    
    @IBAction func deleteDeliveryOption(sender: AnyObject) {
        println("delete delivery option")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        Glow.addGlow(editDeliveryOptionButton)
        Glow.addGlow(deleteDeliveryOptionButton)
    }
}

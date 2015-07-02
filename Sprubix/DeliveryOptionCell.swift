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
        editDeliveryAction?()
    }
    
    @IBAction func deleteDeliveryOption(sender: AnyObject) {
        deleteDeliveryAction?()
    }
    
    var editDeliveryAction: (() -> Void)?
    var deleteDeliveryAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        editDeliveryOptionButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        editDeliveryOptionButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        Glow.addGlow(editDeliveryOptionButton)

        deleteDeliveryOptionButton.imageEdgeInsets = UIEdgeInsetsMake(9, 8, 7, 8)
        deleteDeliveryOptionButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        Glow.addGlow(deleteDeliveryOptionButton)
    }
}

//
//  DeliveryAddressCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 5/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class DeliveryAddressCell: UITableViewCell {

    @IBOutlet var deliveryAddress: UILabel!
    @IBOutlet var editDeliveryAddressButton: UIButton!
    @IBOutlet var deleteDeliveryAddressButton: UIButton!
    
    @IBAction func editDeliveryAddress(sender: AnyObject) {
        editDeliveryAction?()
    }
    
    @IBAction func deleteDeliveryAddress(sender: AnyObject) {
        deleteDeliveryAction?()
    }
    
    var editDeliveryAction: (() -> Void)?
    var deleteDeliveryAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        editDeliveryAddressButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //editDeliveryAddressButton = UIEdgeInsetsMake(5, 5, 5, 5)
        editDeliveryAddressButton.imageEdgeInsets = UIEdgeInsetsMake(0, 2, 2, 0)
        Glow.addGlow(editDeliveryAddressButton)
        
        deleteDeliveryAddressButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        // top, left, bottom, right
        deleteDeliveryAddressButton.imageEdgeInsets = UIEdgeInsetsMake(6, 8, 4, 2)
        //deleteDeliveryAddressButton = UIEdgeInsetsMake(9, 8, 7, 8)
        Glow.addGlow(deleteDeliveryAddressButton)
    }
}

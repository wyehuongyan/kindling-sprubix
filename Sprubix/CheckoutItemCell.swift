//
//  CheckoutItemCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 11/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CheckoutItemCell: UITableViewCell {
    @IBOutlet var checkoutItemImageView: UIImageView!
    @IBOutlet var checkoutItemName: UILabel!
    @IBOutlet var checkoutItemSize: UILabel!
    @IBOutlet var checkoutItemQuantity: UILabel!
    @IBOutlet var checkoutItemPrice: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        checkoutItemImageView.layer.cornerRadius = 8.0
        checkoutItemImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        checkoutItemImageView.layer.borderWidth = 0.5
        checkoutItemImageView.clipsToBounds = true
    }
}

//
//  CartItemSectionFooter.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 4/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CartItemSectionFooter: UITableViewCell {

    @IBOutlet var deliveryMethod: UIButton!
    @IBOutlet var subtotal: UILabel!
    @IBOutlet var shippingRate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = UIColor.whiteColor()
        
        deliveryMethod.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        deliveryMethod.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0)
        deliveryMethod.titleEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0)
    }
}

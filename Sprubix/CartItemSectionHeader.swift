//
//  CartItemSectionHeader.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 4/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CartItemSectionHeader: UITableViewCell {
    @IBOutlet var sellerImageView: UIImageView!
    @IBOutlet var sellerName: UILabel!
    
    override func awakeFromNib() {
        sellerImageView.layer.cornerRadius = sellerImageView.frame.size.width / 2
        sellerImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        sellerImageView.layer.borderWidth = 0.5
        sellerImageView.clipsToBounds = true
        
        contentView.backgroundColor = sprubixLightGray
    }
}

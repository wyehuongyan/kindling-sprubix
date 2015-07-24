//
//  CheckoutPointsItemCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CheckoutPointsItemCell: UITableViewCell {

    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var quantity: UILabel!
    @IBOutlet var price: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        itemImageView.layer.cornerRadius = 8.0
        itemImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        itemImageView.layer.borderWidth = 0.5
        itemImageView.clipsToBounds = true
    }
}

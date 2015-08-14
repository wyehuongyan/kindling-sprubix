//
//  RefundDetailsItemCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class RefundDetailsItemCell: UITableViewCell {

    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var size: UILabel!
    @IBOutlet var price: UILabel!
    @IBOutlet var returnInfo: UILabel!
    @IBOutlet var edit: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        itemImageView.layer.cornerRadius = 8.0
        itemImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        itemImageView.layer.borderWidth = 0.5
        itemImageView.clipsToBounds = true
    }
}

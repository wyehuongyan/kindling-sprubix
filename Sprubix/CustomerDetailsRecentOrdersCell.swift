//
//  CustomerDetailsRecentOrdersCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CustomerDetailsRecentOrdersCell: UITableViewCell {

    @IBOutlet var cartImageView: UIImageView!
    @IBOutlet var recentOrderText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = sprubixLightGray
    }
}

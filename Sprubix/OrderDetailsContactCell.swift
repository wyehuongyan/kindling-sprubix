//
//  OrderDetailsContactCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 20/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class OrderDetailsContactCell: UITableViewCell {
    @IBOutlet var emailAddress: UILabel!
    @IBOutlet var contactNumber: UILabel!
    
    @IBOutlet var contactImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let image: UIImage = UIImage(named: "order-contact")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        contactImageView.image = image
        contactImageView.tintColor = UIColor.lightGrayColor()
    }
}

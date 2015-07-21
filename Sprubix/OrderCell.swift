//
//  OrderCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 18/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class OrderCell: UITableViewCell {
    @IBOutlet var username: UILabel!
    @IBOutlet var orderNumber: UILabel!
    @IBOutlet var price: UILabel!
    @IBOutlet var dateTime: UILabel!

    @IBOutlet var statusImageView: UIImageView!
    
    var orderStatusId: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setStatusImage() {
        var statusImageName = ""
        var statusTintColor: UIColor = UIColor.lightGrayColor()
        
        switch orderStatusId {
        case 1:
            // Processing
            statusImageName = "order-processing"
            statusTintColor = UIColor.lightGrayColor()
        case 2:
            // Shipping Requested
            statusImageName = "order-shipping-requested"
            statusTintColor = UIColor.cyanColor()
        case 3:
            // Shipping Posted
            statusImageName = "order-shipping-posted"
            statusTintColor = UIColor.blueColor()
        case 4:
            // Shipping Delivered
            statusImageName = "order-shipping-delivered"
            statusTintColor = UIColor.greenColor()
        case 5:
            // Payment Failed
            statusImageName = "order-cancelled"
            statusTintColor = UIColor.redColor()
        case 6:
            // Shipping Delayed
            statusImageName = "order-shipping-requested"
            statusTintColor = UIColor.orangeColor()
        default:
            fatalError("Unknown order status in ShopOrderDetailsViewController")
        }
        
        let statusImage: UIImage = UIImage(named: statusImageName)!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        statusImageView.image = statusImage
        statusImageView.tintColor = statusTintColor
    }
}

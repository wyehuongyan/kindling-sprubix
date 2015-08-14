//
//  OrderDetailsStatusCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 20/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class OrderDetailsStatusCell: UITableViewCell {

    @IBOutlet var statusImageView: UIImageView!
    @IBOutlet var status: UILabel!
    @IBOutlet var changeStatusButton: UIButton!

    @IBAction func changeOrderStatus(sender: AnyObject) {
        changeStatusAction?()
    }
    
    var changeStatusAction: (() -> Void)?
    var orderStatusId: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        changeStatusButton.layer.cornerRadius = changeStatusButton.frame.size.height / 2
        changeStatusButton.clipsToBounds = true
        changeStatusButton.layer.borderWidth = 2.0
        changeStatusButton.layer.borderColor = sprubixColor.CGColor
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
            statusImageName = "order-shipping-received"
            statusTintColor = UIColor.greenColor()
        case 5:
            // Payment Failed
            statusImageName = "order-cancelled"
            statusTintColor = UIColor.redColor()
        case 6:
            // Shipping Delayed
            statusImageName = "order-shipping-requested"
            statusTintColor = UIColor.orangeColor()
        case 7:
            // Cancelled
            statusImageName = "order-cancelled"
            statusTintColor = UIColor.redColor()
        default:
            fatalError("Unknown order status in OrderDetailsStatusCell")
        }
        
        let statusImage: UIImage = UIImage(named: statusImageName)!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        statusImageView.image = statusImage
        statusImageView.tintColor = statusTintColor
    }
}

//
//  RefundCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class RefundCell: UITableViewCell {
    @IBOutlet var username: UILabel!
    @IBOutlet var orderNumber: UILabel!
    @IBOutlet var price: UILabel!
    @IBOutlet var dateTime: UILabel!
    
    @IBOutlet var statusImageView: UIImageView!
    
    var refundStatusId: Int!
    
    func setStatusImage() {
        var statusImageName = ""
        var statusTintColor: UIColor = UIColor.lightGrayColor()
        
        switch refundStatusId {
        case 1:
            // Requested for Refund
            statusImageName = "order-processing"
            statusTintColor = UIColor.lightGrayColor()
        case 2:
            // Refunded
            statusImageName = "order-shipping-requested"
            statusTintColor = UIColor.cyanColor()
        case 3:
            // Refund Cancelled
            statusImageName = "order-shipping-posted"
            statusTintColor = UIColor.blueColor()
        case 4:
            // Refund Failed
            statusImageName = "order-shipping-received"
            statusTintColor = UIColor.greenColor()
        default:
            fatalError("Unknown refund status in RefundDetailsStatusCell")
        }
        
        let statusImage: UIImage = UIImage(named: statusImageName)!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        statusImageView.image = statusImage
        statusImageView.tintColor = statusTintColor
    }

}

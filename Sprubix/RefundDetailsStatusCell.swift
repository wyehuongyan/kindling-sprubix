//
//  ShopOrderRefundDetailsStatusCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 12/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class ShopOrderRefundDetailsStatusCell: UITableViewCell {
    @IBOutlet var statusImageView: UIImageView!
    @IBOutlet var status: UILabel!
    
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
            // Refund Processing
            statusImageName = "order-shipping-requested"
            statusTintColor = UIColor.cyanColor()
        case 3:
            // Refunded
            statusImageName = "order-shipping-received"
            statusTintColor = UIColor.greenColor()
        case 4:
            // Refund Cancelled
            statusImageName = "order-cancelled"
            statusTintColor = UIColor.redColor()
        case 5:
            // Refund Failed
            statusImageName = "shop-info"
            statusTintColor = UIColor.redColor()
        default:
            fatalError("Unknown refund status in RefundDetailsStatusCell")
        }
        
        let statusImage: UIImage = UIImage(named: statusImageName)!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        statusImageView.image = statusImage
        statusImageView.tintColor = statusTintColor
    }
}

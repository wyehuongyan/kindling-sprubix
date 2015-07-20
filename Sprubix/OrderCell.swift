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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let orderProcessingImage: UIImage = UIImage(named: "order-processing")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        statusImageView.image = orderProcessingImage
        statusImageView.tintColor = UIColor.lightGrayColor()
    }
}

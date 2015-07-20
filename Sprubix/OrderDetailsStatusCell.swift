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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        changeStatusButton.layer.cornerRadius = changeStatusButton.frame.size.height / 2
        changeStatusButton.clipsToBounds = true
        changeStatusButton.layer.borderWidth = 2.0
        changeStatusButton.layer.borderColor = sprubixColor.CGColor
    }
    
    func setStatusImage(imageName: String, tintColor: UIColor) {
        let statusImage: UIImage = UIImage(named: imageName)!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        statusImageView.image = statusImage
        statusImageView.tintColor = tintColor
    }
}

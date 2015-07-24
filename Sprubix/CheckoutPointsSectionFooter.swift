//
//  CheckoutPointsSectionFooter.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CheckoutPointsSectionFooter: UITableViewCell {

    @IBOutlet var pointsEntitlement: UIButton!
    @IBOutlet var subtotal: UILabel!
    @IBOutlet var points: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let pointsImage: UIImage = UIImage(named: "shop-points")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        pointsEntitlement.setImage(pointsImage, forState: UIControlState.Normal)
        pointsEntitlement.imageView?.tintColor = sprubixColor
        pointsEntitlement.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        pointsEntitlement.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 0)
        pointsEntitlement.titleEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 0)
        
        contentView.backgroundColor = UIColor.whiteColor()
    }
}

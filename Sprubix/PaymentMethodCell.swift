//
//  PaymentMethodCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 10/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class PaymentMethodCell: UITableViewCell {

    @IBOutlet var paymentMethodName: UILabel!
    @IBOutlet var paymentMethodImage: UIImageView!
    @IBOutlet var deletePaymentMethodButton: UIButton!
    @IBOutlet var makeDefaultButton: UIButton!
    
    @IBAction func makeDefault(sender: AnyObject) {
        makeDefaultPaymentMethodAction?()
    }

    @IBAction func deletePaymentMethod(sender: AnyObject) {
        deletePaymentMethodAction?()
    }
    
    var deletePaymentMethodAction: (() -> Void)?
    var makeDefaultPaymentMethodAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        paymentMethodImage.contentMode = UIViewContentMode.ScaleAspectFit
        
        deletePaymentMethodButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        // top, left, bottom, right
        deletePaymentMethodButton.imageEdgeInsets = UIEdgeInsetsMake(6, 8, 4, 2)
        Glow.addGlow(deletePaymentMethodButton)
    }
}

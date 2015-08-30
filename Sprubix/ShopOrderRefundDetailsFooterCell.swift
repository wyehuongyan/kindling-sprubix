//
//  ShopOrderRefundDetailsFooterCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class ShopOrderRefundDetailsFooterCell: UITableViewCell {

    @IBOutlet var shippingRate: UILabel!
    @IBOutlet var totalAmountRefundable: UILabel!
    @IBOutlet var refundAmount: UITextField!
    @IBOutlet var refundPoints: UITextField!
    @IBOutlet var refundReason: UITextView!
    
    override func awakeFromNib() {
        var dollarLabel: UILabel = UILabel(frame: CGRectMake(5, -0.5, 10, refundAmount.frame.height))
        dollarLabel.text = "$"
        dollarLabel.textColor = UIColor.lightGrayColor()
        dollarLabel.textAlignment = NSTextAlignment.Left
        
        var offsetView: UIView = UIView(frame: dollarLabel.bounds)
        offsetView.addSubview(dollarLabel)

        refundAmount.leftView = offsetView
        refundAmount.leftViewMode = UITextFieldViewMode.Always
    }
}

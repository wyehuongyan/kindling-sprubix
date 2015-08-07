//
//  OrderDetailsRefundCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class OrderDetailsRefundCell: UITableViewCell {
    
    @IBOutlet var refundButton: UIButton!
    @IBAction func refundButtonPressed(sender: AnyObject) {
        refundAction?()
    }
    
    var refundAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

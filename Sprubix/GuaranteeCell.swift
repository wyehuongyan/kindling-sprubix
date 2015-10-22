//
//  GuaranteeCell.swift
//  Sprubix
//
//  Created by Shion Wah on 22/10/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class GuaranteeCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
        
        self.textLabel!.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        self.textLabel!.textColor = UIColor.darkGrayColor()
        self.textLabel!.textAlignment = NSTextAlignment.Center
        self.textLabel!.text = "Sprubix's Guarantee"
        
        self.detailTextLabel!.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightRegular)
        self.detailTextLabel!.textColor = UIColor.darkGrayColor()
        self.detailTextLabel!.textAlignment = NSTextAlignment.Center
        self.detailTextLabel!.numberOfLines = 0
        self.detailTextLabel!.text = "\nItems are fulfilled by the individual sellers. If you're not statisfied with the order, we'll make it right or refund your purchase."
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var textFrame = self.textLabel!.frame
        textFrame.size.width = CGRectGetWidth(self.frame)
        textFrame.origin.x = 0.0
        self.textLabel!.frame = textFrame
        
        var detailFrame = self.detailTextLabel!.frame
        detailFrame.size.width = CGRectGetWidth(self.frame)
        detailFrame.origin.x = 0.0
        self.detailTextLabel!.frame = detailFrame
    }
}

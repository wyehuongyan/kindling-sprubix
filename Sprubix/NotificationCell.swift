//
//  NotificationCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 27/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {
    
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var notificationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        notificationLabel.textColor = UIColor.grayColor()
        notificationLabel.preferredMaxLayoutWidth = screenWidth - userImageView.frame.size.width - itemImageView.frame.size.width - 40 // 40 is padding on the sides of the imageviews
        
        userImageView.backgroundColor = sprubixGray
        userImageView.contentMode = UIViewContentMode.ScaleAspectFit
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 0.5
        userImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        itemImageView.backgroundColor = sprubixGray
        itemImageView.contentMode = UIViewContentMode.ScaleAspectFit
        itemImageView.layer.cornerRadius = 5
        itemImageView.clipsToBounds = true
        itemImageView.layer.borderWidth = 0.5
        itemImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
}

//
//  UserFollowListCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class UserFollowListCell: UITableViewCell {

    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var realname: UILabel!
    @IBOutlet var followButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        userImageView.backgroundColor = sprubixGray
        userImageView.contentMode = UIViewContentMode.ScaleAspectFit
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 0.5
        userImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        var image: UIImage = UIImage(named: "people-follow-user")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        followButton.setImage(image, forState: UIControlState.Normal)
        followButton.setImage(UIImage(named: "filter-check"), forState: UIControlState.Selected)
        followButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        followButton.imageView?.tintColor = sprubixColor
        followButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 8, 1)
        followButton.addTarget(self, action: "followTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        followButton.exclusiveTouch = true
        followButton.alpha = 0.0
        
        followButton.layer.cornerRadius = followButton.frame.size.height
        followButton.layer.borderWidth = 1.0
        followButton.layer.borderColor = sprubixColor.CGColor
        followButton.backgroundColor = UIColor.whiteColor()
        followButton.clipsToBounds = true
    }
    
    func followTapped(sender: UIButton) {
    }
}

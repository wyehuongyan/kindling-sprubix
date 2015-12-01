//
//  UserFollowListUNCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class UserFollowListUNCell: UITableViewCell {

    var delegate: UserFollowInteractionProtocol?
    var user: NSDictionary!
    
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var followButton: UIButton!
    @IBOutlet var verifiedIcon: UIImageView!

    var followed: Bool!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        userImageView.backgroundColor = sprubixGray
        userImageView.contentMode = UIViewContentMode.ScaleAspectFit
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 0.5
        userImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        userImageView.userInteractionEnabled = true
        
        // gesture recognizer
        let userImageGoToProfileGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showProfile")
        
        userImageView.addGestureRecognizer(userImageGoToProfileGestureRecognizer)
        
        let userNameGoToProfileGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showProfile")
        
        username.userInteractionEnabled = true
        username.addGestureRecognizer(userNameGoToProfileGestureRecognizer)
        
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
    
    func initFollowButton() {
        followButton.selected = followed
        
        if followButton.selected {
            followButton.backgroundColor = sprubixColor
            followButton.imageView?.tintColor = UIColor.whiteColor()
            followButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
        } else {
            followButton.backgroundColor = UIColor.whiteColor()
            followButton.imageView?.tintColor = sprubixColor
            followButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 8, 1)
        }
    }
    
    func followTapped(sender: UIButton) {
        sender.selected = !sender.selected
        
        if sender.selected {
            sender.backgroundColor = sprubixColor
            sender.imageView?.tintColor = UIColor.whiteColor()
            sender.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
            
            // follow
            delegate?.followUser(user, sender: sender)
            
        } else {
            sender.backgroundColor = UIColor.whiteColor()
            sender.imageView?.tintColor = sprubixColor
            sender.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 8, 1)
            
            delegate?.unfollowUser(user, sender: sender)
        }
    }
    
    func showProfile() {
        delegate?.showProfile(user)
    }
}

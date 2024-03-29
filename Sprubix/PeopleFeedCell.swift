//
//  PeopleFeedCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 3/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol PeopleInteractionProtocol {
    func showProfile(user: NSDictionary)
    func showPieceDetails(piece: NSDictionary)
    func followUser(user: NSDictionary, sender: UIButton)
    func unfollowUser(user: NSDictionary, sender: UIButton)
}

class PeopleFeedCell: UITableViewCell {
    let userImageViewWidth: CGFloat = 60.0
    let itemPreviewImageViewWidth = (screenWidth - 40.0) / 3
    
    var delegate: PeopleInteractionProtocol?
    
    var pieces: [NSDictionary]!
    var user: NSDictionary!
    var followed: Bool!
    
    var userImageView: UIImageView!
    var userRealNameLabel: UILabel!
    var userNameLabel: UILabel!
    var verifiedIcon:UIImageView!
    var followButton: UIButton!
    
    var itemPreviewImageViews: [UIImageView]!
    var itemPreviewContainer: UIView!
    
    let userNameLabelHeight: CGFloat = 18.0
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if itemPreviewImageViews != nil {
            for itemPreviewImageView in itemPreviewImageViews {
                itemPreviewImageView.removeFromSuperview()
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // create user profile picture imageview
        userImageView = UIImageView(frame: CGRectMake(10, 10, userImageViewWidth, userImageViewWidth))
        
        userImageView.backgroundColor = sprubixGray
        userImageView.contentMode = UIViewContentMode.ScaleAspectFit
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 0.5
        userImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        userImageView.userInteractionEnabled = true
        
        // gesture recognizer
        let goToProfileGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showProfile")
        
        userImageView.addGestureRecognizer(goToProfileGestureRecognizer)
        
        contentView.addSubview(userImageView)
        
        // create name label
        let followButtonWidth = userNameLabelHeight * 2
        
        //userNameLabel = UILabel(frame: CGRectMake(userImageView.frame.origin.x + userImageViewWidth + 10.0, 21.0, screenWidth - userImageViewWidth - 40.0 - followButtonWidth, userNameLabelHeight))
        userNameLabel = UILabel()
        userNameLabel.font = UIFont(name: userNameLabel.font.fontName, size: 16.0)
        userNameLabel.textColor = sprubixColor
        
        contentView.addSubview(userNameLabel)
        
        // verified tick
        verifiedIcon = UIImageView()
        verifiedIcon.image = UIImage(named: "others-verified")
        
        contentView.addSubview(verifiedIcon)
        
        // create username label
        userRealNameLabel = UILabel(frame: CGRectMake(userImageView.frame.origin.x + userImageViewWidth + 10.0, 21.0 + userNameLabelHeight + 2.0, screenWidth - userImageViewWidth - 40.0 - followButtonWidth, userNameLabelHeight))
        userRealNameLabel.font = UIFont(name: userRealNameLabel.font.fontName, size: 14.0)
        userRealNameLabel.textColor = UIColor.lightGrayColor()
        
        contentView.addSubview(userRealNameLabel)
        
        // create follow button
        followButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        followButton.frame = CGRectMake(screenWidth - followButtonWidth - 10.0, 21.5, followButtonWidth, userNameLabelHeight * 2)

        var image: UIImage = UIImage(named: "people-follow-user")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        followButton.setImage(image, forState: UIControlState.Normal)
        followButton.setImage(UIImage(named: "filter-check"), forState: UIControlState.Selected)
        followButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        followButton.imageView?.tintColor = sprubixColor
        followButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 8, 1)
        followButton.addTarget(self, action: "followTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        followButton.exclusiveTouch = true
        followButton.alpha = 0.0
        
        followButton.layer.cornerRadius = userNameLabelHeight
        followButton.layer.borderWidth = 1.0
        followButton.layer.borderColor = sprubixColor.CGColor
        followButton.backgroundColor = UIColor.whiteColor()
        followButton.clipsToBounds = true
        
        contentView.addSubview(followButton)
        
        // itemPreviewContainer
        itemPreviewContainer = UIView(frame: CGRectMake(0, userImageViewWidth + 20.0, screenWidth, itemPreviewImageViewWidth + 20.0))
        
        itemPreviewContainer.backgroundColor = sprubixLightGray
        
        contentView.addSubview(itemPreviewContainer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func initItemPreview(pieces: [NSDictionary], shoppableType: String?) {
        // total of 6 pieces will be shown here.
        // // if there's not enough pieces, placeholder image is shown
        self.pieces = pieces

        var rowCount: Int = 0
        
        if pieces.count > 3 {
            rowCount = 2
            
            itemPreviewContainer.frame.size.height = 2 * itemPreviewImageViewWidth + 30.0
        } else {
            rowCount = 1
            
            itemPreviewContainer.frame.size.height = itemPreviewImageViewWidth + 20.0
        }
        
        itemPreviewImageViews = [UIImageView]()
        
        for var row = 0; row < rowCount; row++ {
            for var col = 0; col < 3; col++ {
                
                let itemPreviewImageView = UIImageView(frame: CGRectMake((CGFloat(col) + 1) * 10.0 + CGFloat(col) * itemPreviewImageViewWidth, (CGFloat(row) + 1) * 10.0 + CGFloat(row) * itemPreviewImageViewWidth, itemPreviewImageViewWidth, itemPreviewImageViewWidth))
                
                itemPreviewImageView.contentMode = UIViewContentMode.ScaleAspectFill
                itemPreviewImageView.layer.cornerRadius = 10.0
                itemPreviewImageView.layer.borderWidth = 0.0
                itemPreviewImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
                itemPreviewImageView.backgroundColor = sprubixLightGray
                itemPreviewImageView.clipsToBounds = true
                
                itemPreviewContainer.addSubview(itemPreviewImageView)
                
                itemPreviewImageViews.append(itemPreviewImageView)
            }
        }
        
        for var i = 0; i < pieces.count; i++ {
            let itemPreviewImageView: UIImageView = itemPreviewImageViews[i]
            let piece = pieces[i] as NSDictionary
            
            var pieceImagesString = piece["images"] as! NSString
            var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
            var imageURLString = pieceImagesDict["cover"] as! String

            itemPreviewImageView.layer.borderWidth = 1.0
            itemPreviewImageView.backgroundColor = UIColor.whiteColor()
            itemPreviewImageView.setImageWithURL(NSURL(string: imageURLString))
            itemPreviewImageView.userInteractionEnabled = true
            
            // gesture recognizer
            let goToPieceDetailsGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showPieceDetails:")
            
            itemPreviewImageView.addGestureRecognizer(goToPieceDetailsGestureRecognizer)
            
        }
        
        // set follow button
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if user["id"] as? Int != userId {
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
            
            followButton.alpha = 1.0
        } else {
            followButton.alpha = 0.0
        }
        
        // set username label width (depends on username text)
        userNameLabel.frame = CGRectMake(userImageView.frame.origin.x + userImageViewWidth + 10.0, 21.0, userNameLabel.intrinsicContentSize().width, userNameLabelHeight)
        
        verifiedIcon.frame = CGRectMake(userNameLabel.frame.origin.x + userNameLabel.frame.width + 6, userNameLabel.frame.origin.y + 2, 17, 17)
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") == nil {
            if !user!["verified_at"]!.isKindOfClass(NSNull) {
                verifiedIcon.alpha = 1.0
            } else {
                verifiedIcon.alpha = 0.0
            }
        } else {
            verifiedIcon.alpha = 0.0
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
    
    func showPieceDetails(gesture: UITapGestureRecognizer) {
        var pos: Int? = find(itemPreviewImageViews, gesture.view as! UIImageView)
        
        if pos != nil {
            let piece = pieces[pos!] as NSDictionary
            
            delegate?.showPieceDetails(piece)
        }
    }
}

//
//  UserProfileHeader.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 10/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

protocol UserProfileHeaderDelegate {
    // methods are called when each button in the toolbar is pressed
    func loadUserOutfits()
    func loadUserPieces()
    func loadCommunityOutfits()
    
    func showFollowers()
    func showFollowing()
    
    func showEmptyDataSet()
    func hideEmptyDataSet()
}

class UserProfileHeader: UICollectionReusableView, UIScrollViewDelegate {
    let bgImageHeight:CGFloat = 250
    let userInfoHeight:CGFloat = 250
    let toolbarHeight:CGFloat = 50
    let userInfoNumPages = 2
    
    var coverImageContent : UIImageView = UIImageView()
    var button1:UIButton!
    var button2:UIButton!
    var button3:UIButton!
    
    var profileDescriptionBG: UIView!
    
    var currentChoice:UIButton!
    
    var buttonLine:UIView!
    var pageControl:UIPageControl!
    var userInfoScrollView:UIScrollView!
    
    var delegate: UserProfileHeaderDelegate?
    var user: NSDictionary?
    var userName: String?
    
    var profileImage:UIImageView!
    var profileRealName:UILabel!
    var profileName:UILabel!
    var verifiedIcon:UIImageView!
    var profileDescription:UILabel!
    
    var numOutfits: UILabel!
    var numFollowers: UILabel!
    var numFollowing: UILabel!
    
    var numOutfitsText: UILabel!
    var numFollowersText: UILabel!
    var numFollowingText: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initHeaderImage()
        initToolBar()
        initUserInfo()
    }
    
    func initHeaderImage() {
        coverImageContent.frame = CGRectMake(0, 0, screenWidth, bgImageHeight)
        coverImageContent.contentMode = UIViewContentMode.ScaleAspectFill
        coverImageContent.clipsToBounds = true
        coverImageContent.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        
        addSubview(coverImageContent)
    }
    
    func initToolBar() {
        // create toolbar
        var toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: userInfoHeight, width: bounds.width, height: toolbarHeight))
        toolbar.clipsToBounds = true
        toolbar.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        
        // toolbar items
        var buttonWidth = bounds.width / 3
        
        button1 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button1.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: toolbarHeight)
        button1.backgroundColor = UIColor.whiteColor()
        button1.setImage(UIImage(named: "profile-myoutfits"), forState: UIControlState.Normal)
        button1.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button1.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        button1.setImage(UIImage(named: "profile-myoutfits"), forState: UIControlState.Selected)
        button1.tintColor = UIColor.lightGrayColor()
        button1.autoresizesSubviews = true
        button1.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button1.exclusiveTouch = true
        button1.addTarget(self, action: "userOutfitsPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        button2 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button2.frame = CGRect(x: buttonWidth, y: 0, width: buttonWidth, height: toolbarHeight)
        button2.backgroundColor = UIColor.whiteColor()
        button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Normal)
        button2.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button2.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Selected)
        button2.tintColor = UIColor.lightGrayColor()
        button2.autoresizesSubviews = true
        button2.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button2.exclusiveTouch = true
        button2.addTarget(self, action: "userPiecesPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        button3 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button3.frame = CGRect(x: buttonWidth * 2, y: 0, width: buttonWidth, height: toolbarHeight)
        button3.backgroundColor = UIColor.whiteColor()
        button3.setImage(UIImage(named: "profile-community"), forState: UIControlState.Normal)
        button3.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button3.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        button3.setImage(UIImage(named: "profile-community"), forState: UIControlState.Selected)
        button3.tintColor = UIColor.lightGrayColor()
        button3.autoresizesSubviews = true
        button3.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button1.exclusiveTouch = true
        button3.addTarget(self, action: "communityOutfitsPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        toolbar.addSubview(button1)
        toolbar.addSubview(button2)
        toolbar.addSubview(button3)
        
        addSubview(toolbar)
        
        // set when button is selected
        buttonLine = UIView(frame: CGRect(x: 0, y: button1.frame.height - 2.0, width: button1.frame.width, height: 2))
        buttonLine.backgroundColor = sprubixColor
        
        // button 2 is initially selected
        button2.addSubview(buttonLine)
        button2.tintColor = sprubixColor
        currentChoice = button2
    }
    
    func initUserInfo() {
        // a scroll view with 2 pages is used to hold user information
        userInfoScrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: userInfoHeight))
        userInfoScrollView.contentSize = CGSize(width: bounds.width * 2, height: userInfoHeight)
        userInfoScrollView.pagingEnabled = true
        userInfoScrollView.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        userInfoScrollView.scrollEnabled = true
        userInfoScrollView.showsHorizontalScrollIndicator = false
        userInfoScrollView.alwaysBounceHorizontal = true
        userInfoScrollView.delegate = self
        
        // add user profile pic, username on first page
        //let userData:NSDictionary! = defaults.dictionaryForKey("userData")
        //let userThumbnailURL = NSURL(string: user["image"] as NSString)
        
        profileImage = UIImageView()
        let profileImageLength:CGFloat = 90
        
        // 50 is arbitary value, but should convert to constraint
        profileImage.frame = CGRect(x: (bounds.width / 2) - (profileImageLength / 2), y: 40, width: profileImageLength, height: profileImageLength)
        
        // circle mask
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        profileImage.layer.borderWidth = 1.0
        profileImage.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        userInfoScrollView.addSubview(profileImage)
        
        // create real name UILabel
        profileRealName = UILabel()
        let profileNameLength:CGFloat = bounds.width
        profileRealName.frame = CGRect(x: (bounds.width / 2) - (profileNameLength / 2), y: profileImage.center.y + 45, width: profileNameLength, height: 30)
        profileRealName.text = "realname"
        profileRealName.textColor = UIColor.whiteColor()
        profileRealName.font = UIFont(name: profileRealName.font.fontName, size: 20)
        profileRealName.textAlignment = NSTextAlignment.Center
        profileRealName.layer.shadowOpacity = 0.8;
        profileRealName.layer.shadowRadius = 1.0;
        profileRealName.layer.shadowColor = UIColor.blackColor().CGColor;
        profileRealName.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        userInfoScrollView.addSubview(profileRealName)
        
        // create username UILabel
        profileName = UILabel()
        profileName.text = "username"
        profileName.textColor = UIColor.whiteColor()
        profileName.font = UIFont(name: profileName.font.fontName, size: 14)
        profileName.textAlignment = NSTextAlignment.Center
        profileName.layer.shadowOpacity = 0.8;
        profileName.layer.shadowRadius = 1.0;
        profileName.layer.shadowColor = UIColor.blackColor().CGColor;
        profileName.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        userInfoScrollView.addSubview(profileName)
        
        // verified tick
        verifiedIcon = UIImageView()
        verifiedIcon.image = UIImage(named: "others-verified")
        verifiedIcon.alpha = 0.0
        
        userInfoScrollView.addSubview(verifiedIcon)
        
        // create outfits, followers, following
        let followInfoViewWidth = screenWidth - 10
        let followInfoView = UIView(frame: CGRectMake(screenWidth / 2 - followInfoViewWidth / 2, profileImage.center.y + 100, followInfoViewWidth, 40))
        
        userInfoScrollView.addSubview(followInfoView)
        
        // num outfits
        numOutfits = UILabel(frame: CGRectMake(0, 0, followInfoViewWidth / 3, 20))
        numOutfits.text = "0"
        numOutfits.textColor = UIColor.whiteColor()
        numOutfits.font = UIFont(name: profileName.font.fontName, size: 18)
        numOutfits.textAlignment = NSTextAlignment.Center
        numOutfits.layer.shadowOpacity = 0.8;
        numOutfits.layer.shadowRadius = 1.0;
        numOutfits.layer.shadowColor = UIColor.blackColor().CGColor;
        numOutfits.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        numOutfitsText = UILabel(frame: CGRectMake(0, 20, followInfoViewWidth / 3, 20))
        numOutfitsText.text = "Outfits"
        numOutfitsText.textColor = UIColor.whiteColor()
        numOutfitsText.font = UIFont(name: profileName.font.fontName, size: 12)
        numOutfitsText.textAlignment = NSTextAlignment.Center
        numOutfitsText.layer.shadowOpacity = 0.8;
        numOutfitsText.layer.shadowRadius = 1.0;
        numOutfitsText.layer.shadowColor = UIColor.blackColor().CGColor;
        numOutfitsText.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        followInfoView.addSubview(numOutfits)
        followInfoView.addSubview(numOutfitsText)
        
        // num followers
        numFollowers = UILabel(frame: CGRectMake(followInfoViewWidth / 3, 0, followInfoViewWidth / 3, 20))
        numFollowers.text = "0"
        numFollowers.textColor = UIColor.whiteColor()
        numFollowers.font = UIFont(name: profileName.font.fontName, size: 18)
        numFollowers.textAlignment = NSTextAlignment.Center
        numFollowers.layer.shadowOpacity = 0.8;
        numFollowers.layer.shadowRadius = 1.0;
        numFollowers.layer.shadowColor = UIColor.blackColor().CGColor;
        numFollowers.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        // // gesture recognizer to see followers
        let followersGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showFollowers")
        followersGestureRecognizer.numberOfTapsRequired = 1
        
        numFollowers.userInteractionEnabled = true
        numFollowers.addGestureRecognizer(followersGestureRecognizer)
        
        numFollowersText = UILabel(frame: CGRectMake(followInfoViewWidth / 3, 20, followInfoViewWidth / 3, 20))
        numFollowersText.text = "Followers"
        numFollowersText.textColor = UIColor.whiteColor()
        numFollowersText.font = UIFont(name: profileName.font.fontName, size: 12)
        numFollowersText.textAlignment = NSTextAlignment.Center
        numFollowersText.layer.shadowOpacity = 0.8;
        numFollowersText.layer.shadowRadius = 1.0;
        numFollowersText.layer.shadowColor = UIColor.blackColor().CGColor;
        numFollowersText.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        // // gesture recognizer to see followers
        let followersTextGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showFollowers")
        followersTextGestureRecognizer.numberOfTapsRequired = 1
        
        numFollowersText.userInteractionEnabled = true
        numFollowersText.addGestureRecognizer(followersTextGestureRecognizer)
        
        followInfoView.addSubview(numFollowers)
        followInfoView.addSubview(numFollowersText)
        
        // num following
        numFollowing = UILabel(frame: CGRectMake(2 * followInfoViewWidth / 3, 0, followInfoViewWidth / 3, 20))
        numFollowing.text = "0"
        numFollowing.textColor = UIColor.whiteColor()
        numFollowing.font = UIFont(name: profileName.font.fontName, size: 18)
        numFollowing.textAlignment = NSTextAlignment.Center
        numFollowing.layer.shadowOpacity = 0.8;
        numFollowing.layer.shadowRadius = 1.0;
        numFollowing.layer.shadowColor = UIColor.blackColor().CGColor;
        numFollowing.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        // // gesture recognizer to see following
        let followingGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showFollowing")
        followingGestureRecognizer.numberOfTapsRequired = 1
        
        numFollowing.userInteractionEnabled = true
        numFollowing.addGestureRecognizer(followingGestureRecognizer)
        
        numFollowingText = UILabel(frame: CGRectMake(2 * followInfoViewWidth / 3, 20, followInfoViewWidth / 3, 20))
        numFollowingText.text = "Following"
        numFollowingText.textColor = UIColor.whiteColor()
        numFollowingText.font = UIFont(name: profileName.font.fontName, size: 12)
        numFollowingText.textAlignment = NSTextAlignment.Center
        numFollowingText.layer.shadowOpacity = 0.8;
        numFollowingText.layer.shadowRadius = 1.0;
        numFollowingText.layer.shadowColor = UIColor.blackColor().CGColor;
        numFollowingText.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        // // gesture recognizer to see following
        let followingTextGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showFollowing")
        followingTextGestureRecognizer.numberOfTapsRequired = 1
        
        numFollowingText.userInteractionEnabled = true
        numFollowingText.addGestureRecognizer(followingTextGestureRecognizer)
        
        followInfoView.addSubview(numFollowing)
        followInfoView.addSubview(numFollowingText)
        
        // create user description
        profileDescriptionBG = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width * 2, height: bounds.height))
        profileDescriptionBG.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        profileDescriptionBG.alpha = 0
        
        profileDescription = UILabel()
        let profileDescriptionLength:CGFloat = bounds.width
        profileDescription.frame = CGRect(x: ((bounds.width / 2) - (profileDescriptionLength / 2)) + bounds.width, y: 80, width: profileDescriptionLength, height: 120)
        profileDescription.lineBreakMode = .ByWordWrapping // or NSLineBreakMode.ByWordWrapping
        profileDescription.numberOfLines = 5
        profileDescription.textColor = UIColor.whiteColor()
        profileDescription.font = UIFont(name: profileDescription.font.fontName, size: 16)
        profileDescription.textAlignment = NSTextAlignment.Center
        
        profileDescriptionBG.addSubview(profileDescription)
        
        userInfoScrollView.addSubview(profileDescriptionBG)
        
        // create a page control to show paging indicators
        pageControl = UIPageControl(frame: CGRect(x: 0, y: followInfoView.center.y + 20, width: bounds.width, height: 21))
        pageControl.numberOfPages = userInfoNumPages
        pageControl.currentPage = 0
        pageControl.clipsToBounds = true
        pageControl.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        pageControl.userInteractionEnabled = false
        
        addSubview(userInfoScrollView)
        addSubview(pageControl) // do not add to scrollview or it will be scrolled away!
    }
    
    func setProfileInfo() {
        let localUserId: Int? = defaults.objectForKey("userId") as? Int
        
        // user outfits, followers and following in defaults is sometimes outdated
        if user != nil {
            var userId = user!["id"] as! Int
            
            if userId == localUserId {
                // REST call to server to retrieve latest logged in user details
                manager.GET(SprubixConfig.URL.api + "/user",
                    parameters: nil,
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        self.user = responseObject as? NSDictionary
                        
                        self.setProfileInfoData()
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            }
            
            setProfileInfoData()
        }
    }
    
    private func setProfileInfoData() {
        let userThumbnailURL = NSURL(string: user!["image"] as! String)
        let userCoverURL = NSURL(string: user!["cover"] as! String)
        let username = user!["username"] as! String!
        let name = user!["name"] as! String!
        let shoppableType: String? = user!["shoppable_type"] as? String
        
        profileImage.setImageWithURL(userThumbnailURL)
        coverImageContent.setImageWithURL(userCoverURL)
        
        profileRealName.text = name
        profileName.text = "@\(username)"

        profileName.frame = CGRect(x: (bounds.width / 2) - (profileName.intrinsicContentSize().width / 2), y: profileImage.center.y + 70, width: profileName.intrinsicContentSize().width, height: 20)
        verifiedIcon.frame = CGRectMake(profileName.frame.origin.x + profileName.frame.width + 6, profileName.frame.origin.y + 4, 14, 14)
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") == nil {
            if !user!["verified_at"]!.isKindOfClass(NSNull) {
                verifiedIcon.alpha = 1.0
            } else {
                verifiedIcon.alpha = 0.0
            }
        } else {
            verifiedIcon.alpha = 0.0
        }
        
        var userDescriptionString = user!["description"] as? String
        
        if userDescriptionString != nil && userDescriptionString != "" {
            var userDescriptionData: NSData = userDescriptionString!.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var userDescriptionDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(userDescriptionData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
            profileDescription.text = userDescriptionDict["description"] as? String
        }
        
        // follow info
        let numOutfitsValue = user!["num_outfits"] as! Int
        let numFollowersValue = user!["num_followers"] as! Int
        let numFollowingValue = user!["num_following"] as! Int
        
        numOutfits.text = "\(numOutfitsValue)"
        numFollowers.text = "\(numFollowersValue)"
        numFollowing.text = "\(numFollowingValue)"
        
        if username == "sprubix" {
            numFollowers.text = "-"
            numFollowersText.userInteractionEnabled = false
            numFollowers.userInteractionEnabled = false
        } else {
            numFollowersText.userInteractionEnabled = true
            numFollowers.userInteractionEnabled = true
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        calculatePageIndicator()
    }
    
    func calculatePageIndicator() {
        let pageWidth = userInfoScrollView.frame.size.width
        let value = (userInfoScrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)
        let page = Int(floor(value))
        
        profileDescriptionBG.alpha = (value - 0.5)
        
        pageControl.currentPage = page
    }
    
    // toolbar button actions
    func userOutfitsPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()

            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            delegate?.showEmptyDataSet()
            delegate?.loadUserOutfits()
            
            // Mixpanel - Viewed User Profile, Profile
            mixpanel.track("Viewed User Profile", properties: [
                "Source": "User Profile",
                "Tab": "Outfit",
                "Target User ID": user!["id"] as! Int!
            ])
            // Mixpanel - End
        }
    }
    
    func userPiecesPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            delegate?.showEmptyDataSet()
            delegate?.loadUserPieces()
            
            // Mixpanel - Viewed User Profile, Profile
            mixpanel.track("Viewed User Profile", properties: [
                "Source": "User Profile",
                "Tab": "Piece",
                "Target User ID": user!["id"] as! Int!
            ])
            // Mixpanel - End
        }
    }
    
    func communityOutfitsPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()

            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            delegate?.showEmptyDataSet()
            delegate?.loadCommunityOutfits()
            
            // Mixpanel - Viewed User Profile, Profile
            mixpanel.track("Viewed User Profile", properties: [
                "Source": "User Profile",
                "Tab": "Community Outfit",
                "Target User ID": user!["id"] as! Int!
            ])
            // Mixpanel - End
        }
    }
    
    // gesture recognizer callbacks
    func showFollowers() {
        delegate?.showFollowers()
    }
    
    func showFollowing() {
        delegate?.showFollowing()
    }
    
    func deselectAllButtons() {
        buttonLine.removeFromSuperview()
        
        button1.tintColor = UIColor.lightGrayColor()
        button2.tintColor = UIColor.lightGrayColor()
        button3.tintColor = UIColor.lightGrayColor()
    }
}

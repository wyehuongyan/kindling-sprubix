//
//  UserProfileHeader.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 10/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol UserProfileHeaderDelegate {
    // methods are called when each button in the toolbar is pressed
    func loadUserOutfits()
    func loadUserPieces()
    func loadCommunityOutfits()
}

class UserProfileHeader: UICollectionReusableView, UIScrollViewDelegate {
    let bgImageHeight:CGFloat = 300
    let userInfoHeight:CGFloat = 250
    let toolbarHeight:CGFloat = 50
    let userInfoNumPages = 2
    
    var coverImageContent : UIImageView = UIImageView()
    var button1:UIButton!
    var button2:UIButton!
    var button3:UIButton!
    
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
    var profileDescription:UILabel!
    
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
        coverImageContent.frame = bounds
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
        
        // button 1 is initially selected
        button1.addSubview(buttonLine)
        button1.tintColor = sprubixColor
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
        
        profileImage = UIImageView(image: UIImage(named: "person-placeholder.jpg"))
        let profileImageLength:CGFloat = 100
        
        // 50 is arbitary value, but should convert to constraint
        profileImage.frame = CGRect(x: (bounds.width / 2) - (profileImageLength / 2), y: 50, width: profileImageLength, height: profileImageLength)
        
        // circle mask
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        profileImage.layer.borderWidth = 1.0
        profileImage.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        userInfoScrollView.addSubview(profileImage)
        
        // create real name UILabel
        profileRealName = UILabel()
        let profileNameLength:CGFloat = bounds.width
        profileRealName.frame = CGRect(x: (bounds.width / 2) - (profileNameLength / 2), y: profileImage.center.y + 50, width: profileNameLength, height: 30)
        profileRealName.text = "realname"
        profileRealName.textColor = UIColor.whiteColor()
        profileRealName.font = UIFont(name: profileRealName.font.fontName, size: 22)
        profileRealName.textAlignment = NSTextAlignment.Center
        profileRealName.layer.shadowOpacity = 1.0;
        profileRealName.layer.shadowRadius = 1.0;
        profileRealName.layer.shadowColor = UIColor.grayColor().CGColor;
        profileRealName.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        userInfoScrollView.addSubview(profileRealName)
        
        // create username UILabel
        profileName = UILabel()
        profileName.frame = CGRect(x: (bounds.width / 2) - (profileNameLength / 2), y: profileImage.center.y + 80, width: profileNameLength, height: 21)
        profileName.text = "username"
        profileName.textColor = UIColor.whiteColor()
        profileName.font = UIFont(name: profileName.font.fontName, size: 16)
        profileName.textAlignment = NSTextAlignment.Center
        profileName.layer.shadowOpacity = 1.0;
        profileName.layer.shadowRadius = 1.0;
        profileName.layer.shadowColor = UIColor.grayColor().CGColor;
        profileName.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        
        userInfoScrollView.addSubview(profileName)
        
        // create user description
        var profileDescriptionBG:UIView = UIView(frame: CGRect(x: bounds.width, y: 0, width: bounds.width, height: bounds.height))
        profileDescriptionBG.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        
        profileDescription = UILabel()
        let profileDescriptionLength:CGFloat = bounds.width
        profileDescription.frame = CGRect(x: (bounds.width / 2) - (profileDescriptionLength / 2), y: 100, width: profileDescriptionLength, height: 21)
        profileDescription.text = "User Description"
        profileDescription.lineBreakMode = .ByWordWrapping // or NSLineBreakMode.ByWordWrapping
        profileDescription.numberOfLines = 0
        profileDescription.textColor = UIColor.whiteColor()
        profileDescription.font = UIFont(name: profileDescription.font.fontName, size: 16)
        profileDescription.textAlignment = NSTextAlignment.Center
        
        profileDescriptionBG.addSubview(profileDescription)
        
        userInfoScrollView.addSubview(profileDescriptionBG)
        
        // create a page control to show paging indicators
        pageControl = UIPageControl(frame: CGRect(x: 0, y: profileName.center.y + 20, width: bounds.width, height: 21))
        pageControl.numberOfPages = userInfoNumPages
        pageControl.currentPage = 0
        pageControl.clipsToBounds = true
        pageControl.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        
        addSubview(pageControl) // do not add to scrollview or it will be scrolled away!
        addSubview(userInfoScrollView)
    }
    
    func setProfileInfo() {
        if user != nil {
            let userThumbnailURL = NSURL(string: user!["image"] as! String)
            let userCoverURL = NSURL(string: user!["cover"] as! String)
            let username = user!["username"] as! String!
            let name = user!["name"] as! String!

            profileImage.setImageWithURL(userThumbnailURL)
            coverImageContent.setImageWithURL(userCoverURL)
            
            profileRealName.text = name
            profileName.text = "@\(username)"
            profileDescription.text = user!["description"] as? String
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        calculatePageIndicator()
    }
    
    func calculatePageIndicator() {
        let pageWidth = userInfoScrollView.frame.size.width
        let page = Int(floor((userInfoScrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
        
        pageControl.currentPage = page
    }
    
    // toolbar button actions
    func userOutfitsPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()

            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            delegate?.loadUserOutfits()
        }
    }
    
    func userPiecesPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            delegate?.loadUserPieces()
        }
    }
    
    func communityOutfitsPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()

            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            delegate?.loadCommunityOutfits()
        }
    }
    
    func deselectAllButtons() {
        buttonLine.removeFromSuperview()
        
        button1.tintColor = UIColor.lightGrayColor()
        button2.tintColor = UIColor.lightGrayColor()
        button3.tintColor = UIColor.lightGrayColor()
    }
}

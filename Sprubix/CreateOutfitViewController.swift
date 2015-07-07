//
//  CreateOutfitViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 2/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class CreateOutfitViewController: UIViewController {
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    // choice buttons
    var snapFromCameraButton: UIButton!
    var myClosetItemsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        initChoiceButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        snapFromCameraButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        myClosetItemsButton.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Create Outfit"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.exclusiveTouch = true
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initChoiceButtons() {
        // choice buttons
        // // new items
        let buttonPadding: CGFloat = 20.0
        let buttonWidth: CGFloat = (screenWidth - (20.0 * 3)) / 2
        snapFromCameraButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        snapFromCameraButton.frame = CGRectMake(buttonPadding, screenHeight / 2 - buttonWidth / 2, buttonWidth, buttonWidth)
        snapFromCameraButton.setTitle("Snap from Camera", forState: UIControlState.Normal)
        snapFromCameraButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        
        if screenWidth >= 375 {
            snapFromCameraButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15.0)
        } else {
            snapFromCameraButton.titleLabel?.font = UIFont.boldSystemFontOfSize(13.0)
        }
        
        snapFromCameraButton.titleEdgeInsets = UIEdgeInsetsMake(buttonWidth / 2, 0, 0, 0)
        snapFromCameraButton.backgroundColor = UIColor.whiteColor()
        snapFromCameraButton.clipsToBounds = true
        snapFromCameraButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        snapFromCameraButton.layer.borderWidth = 2.0
        snapFromCameraButton.layer.cornerRadius = 12.0
        
        snapFromCameraButton.addTarget(self, action: "snapFromCamera:", forControlEvents: UIControlEvents.TouchUpInside)
        snapFromCameraButton.addTarget(self, action: "highlightButton:", forControlEvents: UIControlEvents.TouchDown)
        snapFromCameraButton.addTarget(self, action: "unHighlightButton:", forControlEvents: UIControlEvents.TouchUpOutside)
        
        // // icon image
        let snapFromCameraImageWidth = buttonWidth / 2
        let snapFromCameraImageView: UIImageView = UIImageView(frame: CGRectMake(buttonWidth / 2 - snapFromCameraImageWidth / 2, buttonWidth / 2 - snapFromCameraImageWidth / 2, snapFromCameraImageWidth, snapFromCameraImageWidth))
        
        snapFromCameraImageView.contentMode = UIViewContentMode.ScaleAspectFit
        snapFromCameraImageView.image = UIImage(named: "details-thumbnail-add")
        snapFromCameraButton.addSubview(snapFromCameraImageView)
        
        // // existing items (spruce)
        myClosetItemsButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        myClosetItemsButton.frame = CGRectMake(snapFromCameraButton.frame.origin.x + buttonWidth + buttonPadding, screenHeight / 2 - buttonWidth / 2, buttonWidth, buttonWidth)
        myClosetItemsButton.setTitle("Spruce My Closet", forState: UIControlState.Normal)
        myClosetItemsButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)

        if screenWidth >= 375 {
            myClosetItemsButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15.0)
        } else {
            myClosetItemsButton.titleLabel?.font = UIFont.boldSystemFontOfSize(13.0)
        }
        
        myClosetItemsButton.titleEdgeInsets = UIEdgeInsetsMake(buttonWidth / 2, 0, 0, 0)
        myClosetItemsButton.backgroundColor = UIColor.whiteColor()
        myClosetItemsButton.clipsToBounds = true
        myClosetItemsButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        myClosetItemsButton.layer.borderWidth = 2.0
        myClosetItemsButton.layer.cornerRadius = 12.0
        
        myClosetItemsButton.addTarget(self, action: "spruceCloset:", forControlEvents: UIControlEvents.TouchUpInside)
        myClosetItemsButton.addTarget(self, action: "highlightButton:", forControlEvents: UIControlEvents.TouchDown)
        myClosetItemsButton.addTarget(self, action: "unHighlightButton:", forControlEvents: UIControlEvents.TouchUpOutside)
        
        // // icon image
        let myClosetItemsImageWidth = buttonWidth / 2
        let myClosetItemsImageView: UIImageView = UIImageView(frame: CGRectMake(buttonWidth / 2 - snapFromCameraImageWidth / 2, buttonWidth / 2 - snapFromCameraImageWidth / 1.5, snapFromCameraImageWidth, snapFromCameraImageWidth))
        
        myClosetItemsImageView.contentMode = UIViewContentMode.ScaleAspectFit
        myClosetItemsImageView.image = UIImage(named: "profile-mycloset")
        myClosetItemsButton.addSubview(myClosetItemsImageView)
        
        view.addSubview(snapFromCameraButton)
        view.addSubview(myClosetItemsButton)
        
        // label
        let createOutfitLabelWidth: CGFloat = screenWidth
        let createOutfitLabelHeight: CGFloat = 40.0
        let labelPadding: CGFloat = 10.0
        
        let createOutfitLabel: UILabel = UILabel(frame: CGRectMake(0, myClosetItemsButton.frame.origin.y - createOutfitLabelHeight - labelPadding, createOutfitLabelWidth, createOutfitLabelHeight))
        
        if screenWidth < 375 {
            createOutfitLabel.font = UIFont.systemFontOfSize(14.0)
        }
        
        createOutfitLabel.text = "How would you like to create your outfit?"
        createOutfitLabel.numberOfLines = 0
        createOutfitLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        createOutfitLabel.textAlignment = NSTextAlignment.Center
        createOutfitLabel.textColor = UIColor.darkGrayColor()
        
        view.addSubview(createOutfitLabel)
    }
    
    // button callbacks
    func highlightButton(sender: UIButton) {
        sender.backgroundColor = sprubixColor
    }
    
    func unHighlightButton(sender: UIButton) {
        sender.backgroundColor = UIColor.whiteColor()
    }
    
    func snapFromCamera(sender: UIButton) {
        sender.backgroundColor = UIColor.whiteColor()
        sender.layer.borderColor = sprubixColor.CGColor
        
        let sprubixCameraViewController = UIStoryboard.sprubixCameraViewController()
        
        self.navigationController?.pushViewController(sprubixCameraViewController!, animated: true)
    }
    
    func spruceCloset(sender: UIButton) {
        // spruce mode
        sender.backgroundColor = UIColor.whiteColor()
        sender.layer.borderColor = sprubixColor.CGColor
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        let spruceViewController = SpruceViewController()
        
        spruceViewController.userIdFrom = userData!["id"] as! Int
        spruceViewController.usernameFrom = userData!["username"] as! String
        spruceViewController.userThumbnailFrom = userData!["image"] as! String
        
        self.navigationController?.delegate = nil
        self.navigationController?.pushViewController(spruceViewController, animated: true)
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

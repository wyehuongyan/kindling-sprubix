//
//  PeopleFeedViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class PeopleFeedViewController: UIViewController {

    var delegate: SidePanelViewControllerDelegate?
    
    // drop down
    var sprubixTitle: SprubixButtonIconRight!
    var dropdownWrapper: UIView?
    var dropdownView: UIView?
    var dropdownVisible: Bool = false
    let dropdownButtonHeight = navigationHeight
    let dropdownViewHeight = navigationHeight * 3
    
    // feed
    var browseFeedController: BrowseFeedController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        initDropdown()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.shyNavBarManager = nil
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func initNavBar() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        // 1. add a new title to the nav bar
        self.navigationItem.title = "People"
        
        // 2. create a custom button
        var sideMenuButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        sideMenuButton.setImage(UIImage(named: "main-hamburger"), forState: UIControlState.Normal)
        let sideMenuButtonWidth: CGFloat = 30
        sideMenuButton.frame = CGRect(x: 0, y: 0, width: sideMenuButtonWidth, height: sideMenuButtonWidth)
        sideMenuButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        sideMenuButton.addTarget(self, action: "sideMenuTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // 2.1 badge for notifications attached to hamburger
        let badgeWidth:CGFloat = 20
        mainBadge.frame = CGRectMake(sideMenuButtonWidth, sideMenuButtonWidth / 2 - badgeWidth / 2, badgeWidth, badgeWidth)
        mainBadge.backgroundColor = sprubixColor
        mainBadge.layer.cornerRadius = badgeWidth / 2
        mainBadge.clipsToBounds = true
        mainBadge.layer.borderWidth = 1.0
        mainBadge.layer.borderColor = sprubixGray.CGColor
        mainBadge.textColor = UIColor.whiteColor()
        mainBadge.textAlignment = NSTextAlignment.Center
        mainBadge.font = UIFont(name: mainBadge.font.fontName, size: 10)
        mainBadge.text = "\(SidePanelOption.alerts.total!)"
        
        if SidePanelOption.alerts.total <= 0 {
            mainBadge.alpha = 0
        }
        
        sideMenuButton.addSubview(mainBadge)
        
        var sideMenuButtonItem: UIBarButtonItem = UIBarButtonItem(customView: sideMenuButton)
        sideMenuButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        var negativeSpacerItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        negativeSpacerItem.width = -16
        
        self.navigationItem.leftBarButtonItems = [negativeSpacerItem, sideMenuButtonItem]
        
        // 5. search button
        var searchButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-search")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        searchButton.setImage(image, forState: UIControlState.Normal)
        searchButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        searchButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        searchButton.imageView?.tintColor = UIColor.lightGrayColor()
        searchButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        var searchBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: searchButton)
        self.navigationItem.rightBarButtonItems = [searchBarButtonItem]
        
        // sprubix title
        let logoImageWidth:CGFloat = 50
        let logoImageHeight:CGFloat = 30
        
        sprubixTitle = SprubixButtonIconRight(frame: CGRect(x: -logoImageWidth / 2, y: -logoImageHeight / 2, width: logoImageWidth, height: logoImageHeight))
        
        sprubixTitle.addTarget(self, action: "navbarTitlePressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var dropdownImage = UIImage(named: "others-dropdown-down")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        sprubixTitle.setImage(dropdownImage, forState: UIControlState.Normal)
        
        var dropupImage = UIImage(named: "others-dropdown-up")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        sprubixTitle.setImage(dropupImage, forState: UIControlState.Selected)
        
        sprubixTitle.setTitle("People", forState: UIControlState.Normal)
        sprubixTitle.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        sprubixTitle.titleLabel?.font = UIFont.boldSystemFontOfSize(sprubixTitle.titleLabel!.font.pointSize)
        sprubixTitle.imageEdgeInsets = UIEdgeInsetsMake(7, 2, 7, 0)
        sprubixTitle.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        sprubixTitle.imageView?.tintColor = UIColor.blackColor()
        
        self.navigationItem.titleView = sprubixTitle
        self.navigationItem.titleView?.userInteractionEnabled = true
    }
    
    func initDropdown() {
        // init dropdown
        if dropdownWrapper == nil {
            dropdownWrapper = UIView(frame: CGRectMake(0, navigationHeight, screenWidth, screenHeight - navigationHeight))
            dropdownWrapper?.clipsToBounds = true
            dropdownWrapper?.userInteractionEnabled = true
            dropdownWrapper?.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.3)
            dropdownWrapper?.alpha = 0.0
            
            // gesture recognizer to dismiss dropdown
            var dropdownDismissTap = UITapGestureRecognizer(target: self, action: Selector("dismissDropdown:"))
            dropdownDismissTap.numberOfTapsRequired = 1
            
            dropdownWrapper?.addGestureRecognizer(dropdownDismissTap)
            
            view.addSubview(dropdownWrapper!)
        }
        
        // create 3 buttons
        // // following, browse, people
        if dropdownView == nil {
            dropdownView = UIView(frame: CGRectMake(0, -dropdownViewHeight, screenWidth, dropdownViewHeight))
            dropdownView!.backgroundColor = sprubixLightGray
        }
        
        // // following
        let followingButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        followingButton.frame = CGRectMake(0, 0, screenWidth, dropdownButtonHeight)
        var image: UIImage = UIImage(named: "main-following")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        followingButton.setImage(image, forState: UIControlState.Normal)
        followingButton.setTitle("Following", forState: UIControlState.Normal)
        followingButton.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        followingButton.titleLabel?.font = UIFont.systemFontOfSize(16.0)
        followingButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        followingButton.imageView?.tintColor = UIColor.lightGrayColor()
        followingButton.backgroundColor = sprubixLightGray
        followingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        followingButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        followingButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0)
        followingButton.addTarget(self, action: "mainFeedTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // // browse
        let browseButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        browseButton.frame = CGRectMake(0, dropdownButtonHeight, screenWidth, dropdownButtonHeight)
        image = UIImage(named: "main-discover")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        browseButton.setImage(image, forState: UIControlState.Normal)
        browseButton.setTitle("Browse", forState: UIControlState.Normal)
        browseButton.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        browseButton.titleLabel?.font = UIFont.systemFontOfSize(16.0)
        browseButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        browseButton.imageView?.tintColor = UIColor.lightGrayColor()
        browseButton.backgroundColor = sprubixLightGray
        browseButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        browseButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        browseButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0)
        browseButton.addTarget(self, action: "browseFeedTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // // people
        let peopleButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        peopleButton.frame = CGRectMake(0, dropdownButtonHeight * 2, screenWidth, dropdownButtonHeight)
        image = UIImage(named: "main-following")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        peopleButton.setImage(image, forState: UIControlState.Normal)
        peopleButton.setTitle("People", forState: UIControlState.Normal)
        peopleButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        peopleButton.titleLabel?.font = UIFont.systemFontOfSize(16.0)
        peopleButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        peopleButton.imageView?.tintColor = sprubixColor
        peopleButton.backgroundColor = sprubixLightGray
        peopleButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        peopleButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        peopleButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0)
        
        dropdownView!.addSubview(followingButton)
        dropdownView!.addSubview(browseButton)
        dropdownView!.addSubview(peopleButton)
        
        view.addSubview(dropdownView!)
    }
    
    func navbarTitlePressed(sender: UIButton) {
        if dropdownVisible != true {
            sprubixTitle.selected = true
            
            // show dropdownView
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.dropdownWrapper!.alpha = 1.0
                self.dropdownView?.frame.origin.y = navigationHeight

                self.dropdownVisible = true
                }, completion: nil)
        } else {
            dismissDropdown(UITapGestureRecognizer())
        }
    }
    
    func dismissDropdown(gesture: UITapGestureRecognizer) {
        // hide dropdownView
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.dropdownWrapper!.alpha = 0.0
            self.dropdownView?.frame.origin.y = -self.dropdownViewHeight

            self.dropdownVisible = false
            }, completion: nil)
        
        sprubixTitle.selected = false
    }
    
    func browseFeedTapped(sender: UIButton) {
        
        // check if previous vc is browseFeed
        // // if yes, pop, if no, push new
        
        var childrenCount = self.navigationController!.viewControllers.count
        var prevChild: AnyObject = self.navigationController!.viewControllers[childrenCount-2]
        
        if prevChild.isKindOfClass(BrowseFeedController) {
            UIView.transitionWithView(self.navigationController!.view, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.navigationController?.popViewControllerAnimated(false)
                }, completion: nil)
            
            dismissDropdown(UITapGestureRecognizer())
        } else {
            if browseFeedController == nil {
                browseFeedController = BrowseFeedController()
                browseFeedController!.delegate = containerViewController
            }
            
            UIView.transitionWithView(self.navigationController!.view, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.navigationController?.pushViewController(browseFeedController!, animated: false)
                }, completion: nil)
            
            dismissDropdown(UITapGestureRecognizer())
        }
    }
    
    func mainFeedTapped(sender: UIButton) {
        
        // check if previous vc is mainFeed
        // // if yes, pop, if no, pop twice
        
        var childrenCount = self.navigationController!.viewControllers.count
        var prevChild: AnyObject = self.navigationController!.viewControllers[childrenCount-2]
        
        if prevChild.isKindOfClass(MainFeedController) {
            UIView.transitionWithView(self.navigationController!.view, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.navigationController?.popViewControllerAnimated(false)
                }, completion: nil)
            
            dismissDropdown(UITapGestureRecognizer())
        } else {
            UIView.transitionWithView(self.navigationController!.view, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.navigationController?.popToRootViewControllerAnimated(false)
                }, completion: nil)
            
            dismissDropdown(UITapGestureRecognizer())
        }
    }
    
    func sideMenuTapped(sender: UIBarButtonItem) {
        delegate?.toggleSidePanel!()
    }
}

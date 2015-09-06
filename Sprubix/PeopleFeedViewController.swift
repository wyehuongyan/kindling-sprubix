//
//  PeopleFeedViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import AFNetworking

class PeopleFeedViewController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UITableViewDataSource, UITableViewDelegate, PeopleInteractionProtocol {

    var delegate: SidePanelViewControllerDelegate?
    
    let userImageViewWidth: CGFloat = 60.0
    let itemPreviewImageViewWidth = (screenWidth - 40.0) / 3
    
    let peopleFeedCellIdentifier: String = "PeopleFeedCell"
    var people: [NSDictionary] = [NSDictionary]()
    var peopleTableView: UITableView!
    
    var refreshControl: UIRefreshControl!
    var activityView: UIActivityIndicatorView!
    
    // drop down
    var sprubixTitle: SprubixButtonIconRight!
    var dropdownWrapper: UIView?
    var dropdownView: UIView?
    var dropdownVisible: Bool = false
    let dropdownButtonHeight = navigationHeight
    let dropdownViewHeight = navigationHeight * 3
    
    // feed
    var discoverFeedController: DiscoverFeedController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        initTableView()
        initDropdown()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        containerViewController.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        initNavBar()
        retrievePeople()
        
        if self.shyNavBarManager.scrollView == nil {
            self.shyNavBarManager.scrollView = self.peopleTableView
        }
        
        // Mixpanel - Viewed Main Feed, Following
        MixpanelService.track("Viewed Main Feed", propertySet: ["Page": "People"])
        // Mixpanel - End
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.shyNavBarManager = nil
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        containerViewController.statusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
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
        negativeSpacerItem.width = -10
        
        self.navigationItem.leftBarButtonItems = [negativeSpacerItem, sideMenuButtonItem]
        
        // 5. search button
        var searchButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-search")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        searchButton.setImage(image, forState: UIControlState.Normal)
        searchButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        searchButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        searchButton.imageView?.tintColor = UIColor.lightGrayColor()
        searchButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        searchButton.addTarget(self, action: "searchButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
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
    
    func initTableView() {
        peopleTableView = UITableView(frame: view.bounds)
        peopleTableView.dataSource = self
        peopleTableView.delegate = self
        peopleTableView.backgroundColor = sprubixGray
        
        peopleTableView.registerClass(PeopleFeedCell.self, forCellReuseIdentifier: peopleFeedCellIdentifier)
        
        // get rid of line seperator for empty cells
        peopleTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // empty dataset
        peopleTableView.emptyDataSetSource = self
        peopleTableView.emptyDataSetDelegate = self
        
        view.addSubview(peopleTableView)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: screenHeight / 3 - activityViewWidth / 2, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = sprubixColor
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        peopleTableView.insertSubview(refreshControl, atIndex: 0)
        refreshControl.endRefreshing()
    }
    
    func initDropdown() {
        // init dropdown
        if dropdownWrapper == nil {
            dropdownWrapper = UIView(frame: CGRectMake(0, navigationHeaderAndStatusbarHeight, screenWidth, screenHeight - navigationHeaderAndStatusbarHeight))
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
        var image: UIImage = UIImage(named: "main-home")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        followingButton.setImage(image, forState: UIControlState.Normal)
        followingButton.setTitle("Home", forState: UIControlState.Normal)
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
        let discoverButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        discoverButton.frame = CGRectMake(0, dropdownButtonHeight, screenWidth, dropdownButtonHeight)
        image = UIImage(named: "main-discover")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        discoverButton.setImage(image, forState: UIControlState.Normal)
        discoverButton.setTitle("Discover", forState: UIControlState.Normal)
        discoverButton.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        discoverButton.titleLabel?.font = UIFont.systemFontOfSize(16.0)
        discoverButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        discoverButton.imageView?.tintColor = UIColor.lightGrayColor()
        discoverButton.backgroundColor = sprubixLightGray
        discoverButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        discoverButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        discoverButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0)
        discoverButton.addTarget(self, action: "discoverFeedTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // // people
        let peopleButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        peopleButton.frame = CGRectMake(0, dropdownButtonHeight * 2, screenWidth, dropdownButtonHeight)
        image = UIImage(named: "main-people")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
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
        dropdownView!.addSubview(discoverButton)
        dropdownView!.addSubview(peopleButton)
        
        view.addSubview(dropdownView!)
    }
    
    func retrievePeople() {
        
        if people.count <= 0 {
            activityView.startAnimating()
        }
        
        // REST call to server to retrieve people
        manager.GET(SprubixConfig.URL.api + "/people/pieces",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.people = responseObject as! [NSDictionary]
                self.peopleTableView.reloadData()
                self.activityView.stopAnimating()
                self.refreshControl.endRefreshing()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)

                self.activityView.stopAnimating()
                self.refreshControl.endRefreshing()
                
                SprubixReachability.handleError(error.code)
        })
    }
    
    func refresh(sender: AnyObject) {
        retrievePeople()
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(peopleFeedCellIdentifier, forIndexPath: indexPath) as! PeopleFeedCell
        
        let person = people[indexPath.row] as NSDictionary
        
        let userImageString = person["image"] as! String
        let username = person["username"] as? String
        let name = person["name"] as? String
        let pieces = person["pieces"] as! [NSDictionary]
        
        cell.userImageView.setImageWithURL(NSURL(string: userImageString))
        cell.user = person
        cell.followed = person["followed"] as! Bool

        cell.delegate = self
        
        if username != nil {
            cell.userNameLabel.text = username!
        }
        
        if name != nil && name != "" {
            cell.userRealNameLabel.text = name!
        } else {
            if username != nil {
                cell.userRealNameLabel.text = username!
            }
        }
        
        cell.initItemPreview(pieces)
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var rowHeight: CGFloat = itemPreviewImageViewWidth + userImageViewWidth + 40.0
        
        if people.count > 0 {
            let person = people[indexPath.row] as NSDictionary
            let pieces = person["pieces"] as! [NSDictionary]
            
            if pieces.count > 3 {
                rowHeight = 2 * itemPreviewImageViewWidth + userImageViewWidth + 50.0
            }
        }
        
        return rowHeight
    }
    
    // PeopleInteractionProtocol
    func followUser(user: NSDictionary, sender: UIButton) {
        manager.POST(SprubixConfig.URL.api + "/user/follow",
            parameters: [
                "follow_user_id": user["id"] as! Int
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var status = responseObject["status"] as! String
                
                if status == "200" {
                    //println("followed")
                    
                } else if status == "500" {
                    //println("error in following user")
                    
                    sender.backgroundColor = UIColor.whiteColor()
                    sender.imageView?.tintColor = sprubixColor
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                sender.backgroundColor = UIColor.whiteColor()
                sender.imageView?.tintColor = sprubixColor
        })
    }
    
    func unfollowUser(user: NSDictionary, sender: UIButton) {
        manager.POST(SprubixConfig.URL.api + "/user/unfollow",
            parameters: [
                "unfollow_user_id": user["id"] as! Int
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var status = responseObject["status"] as! String
                
                if status == "200" {
                    //println("unfollowed")
                    
                } else if status == "500" {
                    //println("error in unfollowing user")
                    
                    sender.backgroundColor = sprubixColor
                    sender.imageView?.tintColor = UIColor.whiteColor()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                sender.backgroundColor = sprubixColor
                sender.imageView?.tintColor = UIColor.whiteColor()
        })
    }
    
    func showProfile(user: NSDictionary) {
        containerViewController.showUserProfile(user)
    }
    
    func showPieceDetails(piece: NSDictionary) {
        let pieceId = piece["id"] as? Int
        
        if pieceId != nil {
            manager.POST(SprubixConfig.URL.api + "/pieces",
                parameters: [
                    "id": pieceId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var piece = (responseObject["data"] as! NSArray)[0] as! NSDictionary
                    
                    let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: self.detailsViewControllerLayout(), currentIndexPath: NSIndexPath(forRow: 0, inSection: 0))
                    
                    pieceDetailsViewController.pieces = [piece]
                    pieceDetailsViewController.user = piece["user"] as! NSDictionary
                    
                    // push outfitDetailsViewController onto navigation stack
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.type = kCATransitionMoveIn
                    transition.subtype = kCATransitionFromTop
                    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                    
                    self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
                    self.navigationController!.pushViewController(pieceDetailsViewController, animated: false)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
    
    func detailsViewControllerLayout () -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        
        let itemSize = CGSizeMake(screenWidth, screenHeight)
        
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        return flowLayout
    }
    
    func searchButtonPressed(sender: UIButton) {
        let searchViewController = SearchViewController()
        
        /*
        UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
        self.navigationController?.pushViewController(searchViewController, animated: false)
        }, completion: nil)
        */
        
        self.navigationController?.pushViewController(searchViewController, animated: false)
    }
    
    func navbarTitlePressed(sender: UIButton) {
        if dropdownVisible != true {
            sprubixTitle.selected = true
            
            // show dropdownView
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.dropdownWrapper!.alpha = 1.0
                self.dropdownView?.frame.origin.y = navigationHeaderAndStatusbarHeight

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
    
    func discoverFeedTapped(sender: UIButton) {
        
        // check if previous vc is browseFeed
        // // if yes, pop, if no, push new
        
        var childrenCount = self.navigationController!.viewControllers.count
        var prevChild: AnyObject = self.navigationController!.viewControllers[childrenCount-2]
        
        if prevChild.isKindOfClass(DiscoverFeedController) {
            UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.navigationController?.popViewControllerAnimated(false)
                }, completion: nil)
            
            dismissDropdown(UITapGestureRecognizer())
        } else {
            if discoverFeedController == nil {
                discoverFeedController = DiscoverFeedController()
                discoverFeedController!.delegate = containerViewController
            }
            
            UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.navigationController?.pushViewController(discoverFeedController!, animated: false)
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
            UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.navigationController?.popViewControllerAnimated(false)
                }, completion: nil)
            
            dismissDropdown(UITapGestureRecognizer())
        } else {
            UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.navigationController?.popToRootViewControllerAnimated(false)
                }, completion: nil)
            
            dismissDropdown(UITapGestureRecognizer())
        }
    }
    
    func sideMenuTapped(sender: UIBarButtonItem) {
        dismissDropdown(UITapGestureRecognizer())
        delegate?.toggleSidePanel!()
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "Discover people"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "Find new people to follow."
        
        var paragraph: NSMutableParagraphStyle = NSMutableParagraphStyle.new()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = NSTextAlignment.Center
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(14.0),
            NSForegroundColorAttributeName: UIColor.lightGrayColor(),
            NSParagraphStyleAttributeName: paragraph
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    /*func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
    let text: String = "Button Title"
    
    let attributes: NSDictionary = [
    NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0)
    ]
    
    let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
    
    return attributedString
    }*/
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "emptyset-main-people")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
}

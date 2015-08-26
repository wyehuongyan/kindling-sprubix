//
//  MainFeedController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 26/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import CHTCollectionViewWaterfallLayout
import AFNetworking
import SVPullToRefresh
import TSMessages
import Crashlytics

class MainFeedController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDataSource, OutfitInteractionProtocol, CHTCollectionViewDelegateWaterfallLayout, TransitionProtocol {
    var delegate: SidePanelViewControllerDelegate?
    var outfits: [NSDictionary] = [NSDictionary]()
    var outfitsLiked: NSMutableDictionary = NSMutableDictionary()
    
    let cellInfoViewHeight: CGFloat = 80
    let mainFeedCellIdentifier = "MainFeedCell"
    var mainCollectionView: UICollectionView!
    var outfitsLayout: SprubixStretchyHeader!
    
    var createOutfitButton: UIButton!
    var lastContentOffset:CGFloat = 0
    var lastNavOffset:CGFloat = 0
    
    var refreshControl: UIRefreshControl!
    var activityView: UIActivityIndicatorView!
    
    var spruceViewController: SpruceViewController?
    var commentsViewController: CommentsViewController?
    
    // feed
    var browseFeedController: BrowseFeedController?
    var peopleFeedController: PeopleFeedViewController?
    
    // drop down
    var sprubixTitle: SprubixButtonIconRight!
    var dropdownWrapper: UIView?
    var dropdownView: UIView?
    var dropdownVisible: Bool = false
    let dropdownButtonHeight = navigationHeight
    let dropdownViewHeight = navigationHeight * 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initCollectionViewLayout()
        initCollectionView()
        
        //Crashlytics.sharedInstance().crash()
        
        // sprubix title
        let logoImageWidth:CGFloat = 80
        let logoImageHeight:CGFloat = 30
        
        sprubixTitle = SprubixButtonIconRight(frame: CGRect(x: -logoImageWidth / 2, y: -logoImageHeight / 2, width: logoImageWidth, height: logoImageHeight))
        
        sprubixTitle.addTarget(self, action: "navbarTitlePressed:", forControlEvents: UIControlEvents.TouchUpInside)

        var dropdownImage = UIImage(named: "others-dropdown-down")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        sprubixTitle.setImage(dropdownImage, forState: UIControlState.Normal)
        
        var dropupImage = UIImage(named: "others-dropdown-up")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        sprubixTitle.setImage(dropupImage, forState: UIControlState.Selected)
        
        sprubixTitle.setTitle("Home", forState: UIControlState.Normal)
        sprubixTitle.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        sprubixTitle.titleLabel?.font = UIFont.boldSystemFontOfSize(sprubixTitle.titleLabel!.font.pointSize)
        sprubixTitle.imageEdgeInsets = UIEdgeInsetsMake(7, 4, 7, 0)
        sprubixTitle.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        sprubixTitle.imageView?.tintColor = UIColor.blackColor()
        
        self.navigationItem.titleView = sprubixTitle
        self.navigationItem.titleView?.userInteractionEnabled = true

        // drawer navbar
        self.shyNavBarManager.expansionResistance = 20
        self.shyNavBarManager.contractionResistance = 0
        self.shyNavBarManager.alphaFadeEnabled = true
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = sprubixColor
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        mainCollectionView.insertSubview(refreshControl, atIndex: 0)
        refreshControl.endRefreshing()
        
        // if sign in view doesnt appear due to cookies
        FirebaseAuth.retrieveFirebaseToken()
        
        initButtons()
        initDropdown()
        
        // fresh login for initial load
        freshLogin = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // if shop logs in, show dashboard
        if freshLogin {
            if let userData: NSDictionary? = defaults.dictionaryForKey("userData"), shoppableType: String? = userData!["shoppable_type"] as? String {
                if shoppableType!.lowercaseString.rangeOfString("shopper") == nil {
                    var dashboardViewController: DashboardViewController? = UIStoryboard.dashboardViewController()
                    
                    if dashboardViewController == nil {
                        dashboardViewController = UIStoryboard.dashboardViewController()
                    }
                    
                    self.navigationController?.pushViewController(dashboardViewController!, animated: false)
                    freshLogin = false
                }
            }
        }
        
        containerViewController.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        initNavBar()
        
        // other stuff
        if(refreshControl.refreshing) {
            refreshControl.endRefreshing()
        }
        
        // reset
        spruceViewController?.view.removeFromSuperview()
        spruceViewController = nil
        
        self.shyNavBarManager.scrollView = self.mainCollectionView
        
        commentsViewController?.view.removeFromSuperview()
        commentsViewController = nil
        
        // retrieve following outfits
        retrieveOutfits()
        
        // Mixpanel - Viewed Main Feed, Following
        MixpanelService.track("Viewed Main Feed", propertySet: ["Page": "Following"])
        // Mixpanel - End
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        mainCollectionView.addInfiniteScrollingWithActionHandler({
            if SprubixReachability.isConnectedToNetwork() {
                self.insertMoreOutfits()
            }
        })
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
        
        // 1. create a custom button
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
    }
    
    func initCollectionViewLayout() {
        // layout for outfits tab
        outfitsLayout = SprubixStretchyHeader()
        
        outfitsLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        outfitsLayout.footerHeight = 10
        outfitsLayout.minimumColumnSpacing = 10
        outfitsLayout.minimumInteritemSpacing = 10
        outfitsLayout.columnCount = 2
    }
    
    func initCollectionView() {
        mainCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: outfitsLayout)
        
        mainCollectionView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        mainCollectionView.showsVerticalScrollIndicator = true
        
        mainCollectionView.registerClass(MainFeedCell.self, forCellWithReuseIdentifier: mainFeedCellIdentifier)
        
        mainCollectionView.alwaysBounceVertical = true
        mainCollectionView.backgroundColor = sprubixGray
        
        mainCollectionView.dataSource = self;
        mainCollectionView.delegate = self;
        
        // empty dataset
        mainCollectionView.emptyDataSetSource = self
        mainCollectionView.emptyDataSetDelegate = self
        
        view.addSubview(mainCollectionView)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: screenHeight / 3 - activityViewWidth / 2, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
    }
    
    // REST calls
    func retrieveOutfits(scrollToTop: Bool = false) {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            if outfits.count <= 0 {
                activityView.startAnimating()
            }
            
            // retrieve 3 example pieces
            manager.POST(SprubixConfig.URL.api + "/user/\(userId!)/outfits/following",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    self.outfits = responseObject["data"] as! [NSDictionary]
                    
                    if self.outfits.count <= 0 {
                        // empty dataset
                        self.mainCollectionView.emptyDataSetSource = self
                        self.mainCollectionView.emptyDataSetDelegate = self
                    } else {
                        self.mainCollectionView.emptyDataSetSource = nil
                        self.mainCollectionView.emptyDataSetDelegate = nil
                    }
                    
                    self.activityView.stopAnimating()
                    self.refreshControl.endRefreshing()
                    
                    if self.mainCollectionView.infiniteScrollingView != nil {
                        self.mainCollectionView.infiniteScrollingView.stopAnimating()
                    }
                    
                    self.mainCollectionView.reloadData()
                    
                    if scrollToTop {
                        self.mainCollectionView.layoutIfNeeded()
                        self.mainCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: true)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    self.activityView.stopAnimating()
                    self.refreshControl.endRefreshing()
                    
                    if self.mainCollectionView.infiniteScrollingView != nil {
                        self.mainCollectionView.infiniteScrollingView.stopAnimating()
                    }
                    
                    SprubixReachability.handleError(error.code)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    // infinite scrolling
    func insertMoreOutfits() {
        if outfits.count > 0 {
            let lastOutfit: NSDictionary = outfits.last!
            let lastOutfitId = lastOutfit["id"] as! Int
            let userId:Int? = defaults.objectForKey("userId") as? Int
            
            if userId != nil {
                // retrieve 3 example pieces
                manager.POST(SprubixConfig.URL.api + "/user/\(userId!)/outfits/following",
                    parameters: [
                        "last_outfit_id": lastOutfitId
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        let moreOutfits = responseObject as! [NSDictionary]
                        
                        for moreOutfit in moreOutfits {
                            self.outfits.append(moreOutfit)
                            
                            self.mainCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.outfits.count - 1, inSection: 0)])
                        }
                        
                        if self.mainCollectionView.infiniteScrollingView != nil {
                            self.mainCollectionView.infiniteScrollingView.stopAnimating()
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        if self.mainCollectionView.infiniteScrollingView != nil {
                            self.mainCollectionView.infiniteScrollingView.stopAnimating()
                        }
                        
                        SprubixReachability.handleError(error.code)
                })
            } else {
                println("userId not found, please login or create an account")
            }
        } else {
            if self.mainCollectionView.infiniteScrollingView != nil {
                self.mainCollectionView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    func refresh(sender: AnyObject) {
        retrieveOutfits(scrollToTop: true)
    }
    
    func sideMenuTapped(sender: UIBarButtonItem) {
        dismissDropdown(UITapGestureRecognizer())
        delegate?.toggleSidePanel!()
    }
    
    func initButtons() {
        // create outfit button at bottom right
        let createOutfitButtonWidth: CGFloat = 50
        let createOutfitButtonPadding: CGFloat = 15
        
        createOutfitButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        createOutfitButton.frame = CGRect(x: screenWidth - createOutfitButtonWidth - createOutfitButtonPadding, y: screenHeight - createOutfitButtonWidth - createOutfitButtonPadding, width: createOutfitButtonWidth, height: createOutfitButtonWidth)
        var image: UIImage = UIImage(named: "main-cta-add")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        createOutfitButton.backgroundColor = sprubixColor
        createOutfitButton.setImage(image, forState: UIControlState.Normal)
        createOutfitButton.imageView?.tintColor = UIColor.whiteColor()
        createOutfitButton.addTarget(self, action: "createOutfit:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // circle mask
        createOutfitButton.layer.cornerRadius = createOutfitButton.frame.size.width / 2
        createOutfitButton.clipsToBounds = true
        createOutfitButton.layer.borderWidth = 1.0
        createOutfitButton.layer.borderColor = sprubixLightGray.CGColor
        createOutfitButton.layer.shadowOpacity = 0.6;
        createOutfitButton.layer.shadowRadius = 10.0;
        createOutfitButton.layer.shadowColor = UIColor.blackColor().CGColor;
        createOutfitButton.layer.shadowOffset = CGSizeMake(0.0, 10.0);
        createOutfitButton.layer.masksToBounds = false
        createOutfitButton.userInteractionEnabled = true
        
        view.addSubview(createOutfitButton)
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
        followingButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        followingButton.titleLabel?.font = UIFont.systemFontOfSize(16.0)
        followingButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        followingButton.imageView?.tintColor = sprubixColor
        followingButton.backgroundColor = sprubixLightGray
        followingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        followingButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        followingButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0)
        
        // // browse
        let browseButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        browseButton.frame = CGRectMake(0, dropdownButtonHeight, screenWidth, dropdownButtonHeight)
        image = UIImage(named: "main-discover")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        browseButton.setImage(image, forState: UIControlState.Normal)
        browseButton.setTitle("Discover", forState: UIControlState.Normal)
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
        image = UIImage(named: "main-people")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        peopleButton.setImage(image, forState: UIControlState.Normal)
        peopleButton.setTitle("People", forState: UIControlState.Normal)
        peopleButton.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        peopleButton.titleLabel?.font = UIFont.systemFontOfSize(16.0)
        peopleButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        peopleButton.imageView?.tintColor = UIColor.lightGrayColor()
        peopleButton.backgroundColor = sprubixLightGray
        peopleButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        peopleButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        peopleButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0)
        peopleButton.addTarget(self, action: "peopleFeedTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        dropdownView!.addSubview(followingButton)
        dropdownView!.addSubview(browseButton)
        dropdownView!.addSubview(peopleButton)
        
        view.addSubview(dropdownView!)
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "This is your home"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "When you follow people, you'll see their latest outfits here."
        
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
        return UIImage(named: "emptyset-main-home")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return outfits.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:MainFeedCell = collectionView.dequeueReusableCellWithReuseIdentifier(mainFeedCellIdentifier, forIndexPath: indexPath) as! MainFeedCell

        var outfit = outfits[indexPath.row] as NSDictionary
        
        // assign delegate and indexPath
        cell.delegate = self
        cell.indexPath = indexPath
        
        var outfitId = outfit["id"] as! Int
        cell.itemIdentifier = "outfit_\(outfitId)"
        cell.outfitId = outfitId
        cell.purchasable = outfit["purchasable"] as? Bool
        
        // assign image
        var outfitImagesString = outfit["images"] as! NSString
        var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
        
        cell.imageURLString = outfitImageDict["small"] as! String
        cell.thumbnailURLString = outfitImageDict["thumbnail"] as! String
        
        // assign height
        let itemHeight = outfit["height"] as! CGFloat
        let itemWidth = outfit["width"] as! CGFloat
        let imageHeight = itemHeight * gridWidth/itemWidth
        cell.imageHeight = imageHeight
        
        // assign liked
        cell.liked = outfitsLiked[outfitId] as? Bool
        
        // assign user
        cell.user = outfit["user"] as! NSDictionary
        
        // assign creation time
        cell.creationTime = outfit["created_at_custom_format"] as! NSDictionary
        
        cell.setNeedsLayout()
        
        return cell
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var currentDistanceMoved:CGFloat = 0
        var currentNavMoved:CGFloat = 0
         
        lastContentOffset = scrollView.contentOffset.y
        
        // ensuring the createOutfitButton show/hides when navbar show/hides
        if lastNavOffset > self.navigationController!.navigationBar.frame.origin.y {
            // up
            
            currentNavMoved = lastNavOffset - self.navigationController!.navigationBar.frame.origin.y
            createOutfitButton.frame.origin.y += currentNavMoved * 1.5
            
        } else if lastNavOffset < self.navigationController!.navigationBar.frame.origin.y {
            // down
            
            currentNavMoved =  self.navigationController!.navigationBar.frame.origin.y - lastNavOffset
            createOutfitButton.frame.origin.y -= currentNavMoved * 1.5
        }
        
        if createOutfitButton.frame.origin.y < screenHeight - createOutfitButton.frame.size.height - 15  {
            createOutfitButton.frame.origin.y = screenHeight - createOutfitButton.frame.size.height - 15
        } else if createOutfitButton.frame.origin.y > screenHeight + 15 {
            createOutfitButton.frame.origin.y = screenHeight + 15
        }
        
        lastNavOffset = self.navigationController!.navigationBar.frame.origin.y
        
        // Count exposed outfits
        countExposedOutfits()
    }
    
    func detailsViewControllerLayout () -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        
        let itemSize = CGSizeMake(screenWidth, screenHeight) //self.navigationController!.navigationBarHidden ?
        //CGSizeMake(screenWidth, screenHeight+20) : CGSizeMake(screenWidth, screenHeight-navigationHeaderAndStatusbarHeight)
        
        //let itemSize = CGSizeMake(screenWidth, screenHeight + navigationHeight)
        
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        return flowLayout
    }
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        var itemHeight:CGFloat!
        var itemWidth:CGFloat!
    
        let outfit = outfits[indexPath.row] as NSDictionary
        itemHeight = outfit["height"] as! CGFloat
        itemWidth = outfit["width"] as! CGFloat
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight + cellInfoViewHeight)
    }
    
    // TransitionProtocol
    func transitionCollectionView() -> UICollectionView!{
        return mainCollectionView
    }
    
    // OutfitInteractionProtocol
    func setOutfitsLiked(outfitId: Int, liked: Bool) {
        outfitsLiked.setObject(liked, forKey: outfitId)
    }
    
    func unlikedOutfit(outfitId: Int, itemIdentifier: String, receiver: NSDictionary) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            // firebase collections: users, likes, poutfits and notifications
            let likesRef = firebaseRef.childByAppendingPath("likes")
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            let poutfitsRef = firebaseRef.childByAppendingPath("poutfits")
            let poutfitLikesRef = poutfitsRef.childByAppendingPath("\(itemIdentifier)/likes")
            
            let senderUsername = userData!["username"] as! String
            let receiverUsername = receiver["username"] as! String
            let poutfitRef = firebaseRef.childByAppendingPath("poutfits/\(itemIdentifier)")
            let poutfitLikesUserRef = poutfitLikesRef.childByAppendingPath(senderUsername) // to be removed
            
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            let senderLikesRef = firebaseRef.childByAppendingPath("users/\(senderUsername)/likes")
            
            // check if user has already liked this outfit
            poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if (snapshot.value as? NSNull) != nil {
                    // does not exist, already unliked
                    println("You have already unliked this outfit")
                    
                    self.outfitsLiked.setObject(false, forKey: outfitId)
                } else {
                    // was liked, set it to unliked here
                    poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                        snapshot in
                        
                        if (snapshot.value as? NSNull) != nil {
                            // does not exist
                            println("Error: Like key in Poutfits could not be found.")
                        } else {
                            // exists
                            var likeRefKey = snapshot.value as! String
                            
                            let likeRef = likesRef.childByAppendingPath(likeRefKey) // to be removed
                            
                            let likeRefNotificationKey = likeRef.childByAppendingPath("notification")
                            
                            likeRefNotificationKey.observeSingleEventOfType(.Value, withBlock: { snapshot in
                            
                                if (snapshot.value as? NSNull) != nil {
                                    // does not exist
                                    println("Error: Notification key in Likes could not be found.")
                                } else {
                                    var notificationRefKey = snapshot.value as! String
                                    
                                    let notificationRef = notificationsRef.childByAppendingPath(notificationRefKey) // to be removed
                                    
                                    let receiverUserNotificationRef = receiverUserNotificationsRef.childByAppendingPath(notificationRefKey) // to be removed
                                    
                                    let senderLikeRef = senderLikesRef.childByAppendingPath(likeRefKey) // to be removed
                                    
                                    // remove all values
                                    senderLikeRef.removeValue()
                                    notificationRef.removeValue()
                                    receiverUserNotificationRef.removeValue()
                                    likeRef.removeValue()
                                    poutfitLikesUserRef.removeValue()
                                    
                                    self.outfitsLiked.setObject(false, forKey: outfitId)
                                    
                                    // update poutfitRef num of likes
                                    let poutfitLikeCountRef = poutfitRef.childByAppendingPath("num_likes")
                                    
                                    poutfitLikeCountRef.runTransactionBlock({
                                        (currentData:FMutableData!) in
                                        
                                        var value = currentData.value as? Int
                                        
                                        if value == nil {
                                            value = 0
                                        } else {
                                            if value > 0 {
                                                value = value! - 1
                                            }
                                        }
                                        
                                        currentData.value = value!
                                        
                                        return FTransactionResult.successWithValue(currentData)
                                    })
                                    
                                    println("Outfit unliked successfully!")
                                }
                            })
                            
                        }
                    })
                    
                    // Mixpanel - Liked Outfit (decrement)
                    mixpanel.people.increment("Liked Outfits", by: -1)
                    // Mixpanel - End
                }
            })
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    func likedOutfit(outfitId: Int, thumbnailURLString: String, itemIdentifier: String, receiver: NSDictionary) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            // firebase collections: users, likes, poutfits and notifications
            let likesRef = firebaseRef.childByAppendingPath("likes")
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            let poutfitsRef = firebaseRef.childByAppendingPath("poutfits")
            let poutfitLikesRef = poutfitsRef.childByAppendingPath("\(itemIdentifier)/likes")
            
            let senderUsername = userData!["username"] as! String
            let senderImage = userData!["image"] as! String
            let receiverUsername = receiver["username"] as! String
            let poutfitRef = firebaseRef.childByAppendingPath("poutfits/\(itemIdentifier)")
            let poutfitLikesUserRef = poutfitLikesRef.childByAppendingPath(senderUsername)
            
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            let senderLikesRef = firebaseRef.childByAppendingPath("users/\(senderUsername)/likes")
            
            let createdAt = timestamp
            
            // check if user has already liked this outfit
            poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if (snapshot.value as? NSNull) != nil {
                    // does not exist, add it
                    let likeRef = likesRef.childByAutoId()
                    
                    let like = [
                        "author": senderUsername, // yourself
                        "created_at": createdAt,
                        "poutfit": itemIdentifier
                    ]
                    
                    likeRef.setValue(like, withCompletionBlock: {
                        (error:NSError?, ref:Firebase!) in
                        
                        if (error != nil) {
                            println("Error: Like could not be added.")
                        } else {
                            // like added successfully
                            
                            // update poutfitRef num of likes
                            let poutfitLikeCountRef = poutfitRef.childByAppendingPath("num_likes")
                            
                            poutfitLikeCountRef.runTransactionBlock({
                                (currentData:FMutableData!) in
                                
                                var value = currentData.value as? Int
                                
                                if value == nil {
                                    value = 0
                                }
                                
                                currentData.value = value! + 1
                                
                                return FTransactionResult.successWithValue(currentData)
                            })
                            
                            // update child values: poutfits
                            poutfitLikesRef.updateChildValues([
                                userData!["username"] as! String: likeRef.key
                                ])
                            
                            // update child values: user
                            let senderLikeRef = senderLikesRef.childByAppendingPath(likeRef.key)
                            
                            senderLikeRef.updateChildValues([
                                "created_at": createdAt,
                                "poutfit": itemIdentifier
                                ], withCompletionBlock: {
                                    
                                    (error:NSError?, ref:Firebase!) in
                                    
                                    if (error != nil) {
                                        println("Error: Like Key could not be added to User Likes.")
                                    }
                            })
                            
                            // push new notifications
                            let notificationRef = notificationsRef.childByAutoId()
                            
                            let notification = [
                                "poutfit": [
                                    "key": itemIdentifier,
                                    "image": thumbnailURLString
                                ],
                                "created_at": createdAt,
                                "sender": [
                                    "username": senderUsername, // yourself
                                    "image": senderImage
                                ],
                                "receiver": receiverUsername,
                                "type": "like",
                                "like": likeRef.key,
                                "unread": true
                            ]

                            notificationRef.setValue(notification, withCompletionBlock: {

                                (error:NSError?, ref:Firebase!) in
                                
                                if (error != nil) {
                                    println("Error: Notification could not be added.")
                                } else {
                                    // update target user notifications
                                    let receiverUserNotificationRef = receiverUserNotificationsRef.childByAppendingPath(notificationRef.key)
                                    
                                    receiverUserNotificationRef.updateChildValues([
                                        "created_at": createdAt,
                                        "unread": true
                                        ], withCompletionBlock: {
                                            
                                            (error:NSError?, ref:Firebase!) in
                                            
                                            if (error != nil) {
                                                println("Error: Notification Key could not be added to Users.")
                                            }
                                    })
                                    
                                    // update likes with notification key
                                    likeRef.updateChildValues([
                                        "notification": notificationRef.key
                                        ], withCompletionBlock: {
                                            
                                            (error:NSError?, ref:Firebase!) in
                                            
                                            if (error != nil) {
                                                println("Error: Notification Key could not be added to Likes.")
                                            } else {
                                                println("Outfit liked successfully!")
                                                // add to outfits dictionary
                                                self.outfitsLiked.setObject(true, forKey: outfitId)
                                            }
                                    })
                                    
                                    // send APNS
                                    let recipientId = receiver["id"] as! Int
                                    let senderId = userData!["id"] as! Int
                                    
                                    if recipientId != senderId {
                                        let pushMessage = "\(senderUsername) liked your outfit."
                                        
                                        APNS.sendPushNotification(pushMessage, recipientId: recipientId)
                                    }
                                }
                            })
                            
                            // Mixpanel - Liked Outfit
                            mixpanel.track("Liked Outfits", properties: [
                                "Outfit ID": outfitId,
                                "Owner User ID": receiver["id"] as! Int
                            ])
                            mixpanel.people.increment("Liked Outfits", by: 1)
                            // Mixpanel - End
                        }
                    })
                    
                } else {
                    println("You have already liked this outfit")
                    
                    // add to outfits dictionary
                    self.outfitsLiked.setObject(true, forKey: outfitId)
                }
            })
            
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    func commentOutfit(poutfitIdentifier: String, thumbnailURLString: String, receiverUsername: String, outfitId: Int, receiverId: Int) {
        commentsViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("CommentsView") as? CommentsViewController
        
        // init
        commentsViewController?.delegate = containerViewController
        commentsViewController?.prevViewIsOutfit = true
        commentsViewController?.poutfitImageURL = thumbnailURLString
        commentsViewController?.receiverUsername = receiverUsername
        commentsViewController?.receiverId = receiverId
        commentsViewController?.poutfitIdentifier = poutfitIdentifier
        
        navigationController!.delegate = nil
        navigationController!.pushViewController(commentsViewController!, animated: true)
        
        // Mixpanel - Viewed Outfit Comments, Main Feed
        mixpanel.track("Viewed Outfit Comments", properties: [
            "Source": "Main Feed",
            "Outfit ID": outfitId,
            "Owner User ID": receiverId
        ])
        mixpanel.people.increment("Viewed Outfit Comments", by: 1)
        // Mixpanel - End
    }
    
    func showProfile(user: NSDictionary) {
        delegate?.showUserProfile(user)
        
        // Mixpanel - Viewed User Profile, Main Feed
        mixpanel.track("Viewed User Profile", properties: [
            "Source": "Main Feed",
            "Tab": "Outfit",
            "Target User ID": user.objectForKey("id") as! Int
        ])
        // Mixpanel - End
    }
    
    func tappedOutfit(indexPath: NSIndexPath) {
        mainCollectionView.layoutIfNeeded()
        
        let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath:indexPath)
        outfitDetailsViewController.outfits = outfits
        
        mainCollectionView.setToIndexPath(indexPath)
        
        navigationController!.delegate = transitionDelegateHolder
        navigationController!.pushViewController(outfitDetailsViewController, animated: true)
    }
    
    func spruceOutfit(indexPath: NSIndexPath) {
        var selectedOutfit = outfits[indexPath.row] as NSDictionary
        var user = selectedOutfit["user"] as! NSDictionary
        
        if spruceViewController == nil {
            spruceViewController = SpruceViewController()
            spruceViewController?.outfit = selectedOutfit
            spruceViewController?.userIdFrom = user["id"] as! Int
            spruceViewController?.usernameFrom = user["username"] as! String
            spruceViewController?.userThumbnailFrom = user["image"] as! String
            
            self.shyNavBarManager = nil
            navigationController!.delegate = nil
            self.navigationController?.pushViewController(self.spruceViewController!, animated: true)
        }
    }
    
    // button callbacks
    func createOutfit(sender: UIButton) {
        delegate?.showCreateOutfit()
        
        // Mixpanel - Viewed Create Outfit, Main Feed
        mixpanel.track("Viewed Create Outfit", properties: [
            "Source": "Main Feed"
        ])
        // Mixpanel - End
    }
    
    func navbarTitlePressed(sender: UIButton) {
        if dropdownVisible != true {
            sprubixTitle.selected = true
            
            // show dropdownView
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.dropdownWrapper!.alpha = 1.0
                self.dropdownView?.frame.origin.y = navigationHeaderAndStatusbarHeight
                self.mainCollectionView.scrollEnabled = false
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
            self.mainCollectionView.scrollEnabled = true
            self.dropdownVisible = false
            }, completion: nil)
        
        sprubixTitle.selected = false
    }
    
    func browseFeedTapped(sender: UIButton) {
        
        if browseFeedController == nil {
            browseFeedController = BrowseFeedController()
            browseFeedController!.delegate = containerViewController
        }
        
        UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.pushViewController(browseFeedController!, animated: false)
        }, completion: nil)
        
        dismissDropdown(UITapGestureRecognizer())
    }
    
    func peopleFeedTapped(sender: UIButton) {
        
        if peopleFeedController == nil {
            peopleFeedController = PeopleFeedViewController()
            peopleFeedController!.delegate = containerViewController
        }
        
        UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.pushViewController(peopleFeedController!, animated: false)
            }, completion: nil)
        
        dismissDropdown(UITapGestureRecognizer())
    }
    
    func countExposedOutfits() {
        let cells = mainCollectionView.visibleCells() as! [MainFeedCell]
        
        // For every visible cell
        for cell in cells {
            // Outfits that don't exist in array
            if !contains(exposedOutfits,cell.outfitId) {
                let cellAbsolutePos: CGRect = view.convertRect(cell.frame, fromView: mainCollectionView)
                let posMoved: CGFloat = view.frame.height - cellAbsolutePos.origin.y
                
                // Outfit considered seen if half-of-cell is on-screen
                if posMoved > cell.frame.height/2 {
                    exposedOutfits.append(cell.outfitId)
                    
                    // Mixpanel - Exposed Outfits
                    mixpanel.people.increment("Exposed Outfits", by: 1)
                    // Mixpanel - End
                }
            }
        }
    }
}

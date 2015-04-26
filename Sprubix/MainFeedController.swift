//
//  MainFeedController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 26/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class MainFeedController: UIViewController, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout, TransitionProtocol {
    var delegate:SprubixFeedControllerDelegate?
    
    let mainFeedCellIdentifier = "MainFeedCell"
    
    var mainCollectionView: UICollectionView!
    
    var followingUsers:[NSDictionary] = [NSDictionary]()
    var outfits:[NSDictionary] = [NSDictionary]()
    var outfitsLayout:SprubixStretchyHeader!
    
    var refreshControl:UIRefreshControl!
    var createOutfitButton:UIButton!
    var lastContentOffset:CGFloat = 0
    var lastNavOffset:CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initCollectionViewLayout()
        
        mainCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: outfitsLayout)
        mainCollectionView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        mainCollectionView.showsVerticalScrollIndicator = false
        
        mainCollectionView.registerClass(MainFeedCell.self, forCellWithReuseIdentifier: mainFeedCellIdentifier)
        
        mainCollectionView.alwaysBounceVertical = true
        mainCollectionView.backgroundColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1)
        
        mainCollectionView.dataSource = self;
        mainCollectionView.delegate = self;
        
        view.addSubview(mainCollectionView)
        
        // sprubix logo
        var logoImageView = UIImageView(image: UIImage(named: "main-sprubix-logo"))
        let logoImageWidth:CGFloat = 50
        let logoImageHeight:CGFloat = 30
        logoImageView.frame = CGRect(x: -logoImageWidth / 2, y: -logoImageHeight / 2, width: logoImageWidth, height: logoImageHeight)
        logoImageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.navigationItem.titleView = UIView()
        self.navigationItem.titleView?.addSubview(logoImageView)
        
        // drawer navbar
        self.shyNavBarManager.scrollView = self.mainCollectionView
        self.shyNavBarManager.expansionResistance = 50
        self.shyNavBarManager.contractionResistance = 0
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = sprubixColor
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        mainCollectionView.insertSubview(refreshControl, atIndex: 0)
        refreshControl.endRefreshing()
        
        // create outfit CTA
        initButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        // 1. add a new navigation item w/title to the new nav bar
        var newNavItem:UINavigationItem = UINavigationItem()
        newNavItem.title = "Create an Account"
        
        // 2. create a custom back button
        var sideMenuButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        sideMenuButton.setImage(UIImage(named: "main-hamburger"), forState: UIControlState.Normal)
        sideMenuButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        sideMenuButton.imageEdgeInsets = UIEdgeInsetsMake(5, -20, 5, 23)
        sideMenuButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        sideMenuButton.addTarget(self, action: "sideMenuTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var SideMenuButtonItem:UIBarButtonItem = UIBarButtonItem(customView: sideMenuButton)
        SideMenuButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        self.navigationItem.leftBarButtonItem = SideMenuButtonItem
        
        if(refreshControl.refreshing) {
            refreshControl.endRefreshing()
        }
        
        retrieveOutfits()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
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
    
    func retrieveOutfits() {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            // retrieve 3 example pieces
            manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/outfits/following",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    self.followingUsers = responseObject["data"] as! [NSDictionary]
                    
                    // reset
                    self.outfits = [NSDictionary]()
                    
                    for followingUser in self.followingUsers {
                        var currentOutfits = followingUser["outfits"] as! [NSDictionary]
                        
                        for outfit in currentOutfits {
                            self.outfits.append(outfit)
                        }
                    }
                    
                    self.mainCollectionView.reloadData()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    func refresh(sender: AnyObject) {
        //retrieveOutfits()
        
        refreshControl.endRefreshing()
    }
    
    func sideMenuTapped(sender: UIBarButtonItem) {
        delegate?.toggleSidePanel!()
    }
    
    func initButtons() {
        // create outfit button at bottom right
        createOutfitButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        createOutfitButton.frame = CGRect(x: screenWidth - 50, y: screenHeight - 50, width: 40, height: 40)
        createOutfitButton.backgroundColor = UIColor.whiteColor()
        createOutfitButton.setImage(UIImage(named: "main-cta-add"), forState: UIControlState.Normal)
        createOutfitButton.addTarget(self, action: "createOutfit", forControlEvents: UIControlEvents.TouchUpInside)
        
        // circle mask
        createOutfitButton.layer.cornerRadius = createOutfitButton.frame.size.width / 2
        createOutfitButton.clipsToBounds = true
        createOutfitButton.layer.borderWidth = 1.0
        createOutfitButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        createOutfitButton.userInteractionEnabled = true
        
        view.addSubview(createOutfitButton)
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return outfits.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:MainFeedCell = collectionView.dequeueReusableCellWithReuseIdentifier(mainFeedCellIdentifier, forIndexPath: indexPath) as! MainFeedCell
        
        var outfit = outfits[indexPath.row] as NSDictionary
        
        cell.imageURLString = outfit["images"] as! String
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
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
        
        if createOutfitButton.frame.origin.y < screenHeight - createOutfitButton.frame.size.height - 10  {
            createOutfitButton.frame.origin.y = screenHeight - createOutfitButton.frame.size.height - 10
        } else if createOutfitButton.frame.origin.y > screenHeight + 10 {
            createOutfitButton.frame.origin.y = screenHeight + 10
        }
        
        lastNavOffset = self.navigationController!.navigationBar.frame.origin.y
    }
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        var itemHeight:CGFloat!
        var itemWidth:CGFloat!
    
        let outfit = outfits[indexPath.row] as NSDictionary
        itemHeight = outfit["height"] as! CGFloat
        itemWidth = outfit["width"] as! CGFloat
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight)
    }
    
    // TransitionProtocol
    func transitionCollectionView() -> UICollectionView!{
        return mainCollectionView
    }
    
}

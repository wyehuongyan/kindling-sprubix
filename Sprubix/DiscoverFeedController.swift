//
//  DiscoverFeedController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 18/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import AFNetworking

class DiscoverFeedController: UIViewController, UITextFieldDelegate, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout {
    
    var delegate: SidePanelViewControllerDelegate?
    var outfits: [NSDictionary] = [NSDictionary]()
    var outfitsLiked: NSMutableDictionary = NSMutableDictionary()
    
    // collection view
    let cellInfoViewHeight: CGFloat = 80
    let discoverFeedCellIdentifier = "MainFeedCell"
    var outfitsLayout: SprubixStretchyHeader!
    var discoverCollectionView: UICollectionView!
    
    // search
    let searchBarViewHeight: CGFloat = 44
    let searchBarTextFieldHeight: CGFloat = 24
    var searchBarTextField: UITextField!
    var searchBarPlaceholderText: String = "Looking for something?"
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        initToolbar()
        initCollectionView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        
        if self.shyNavBarManager.scrollView == nil {
            self.shyNavBarManager.scrollView = self.discoverCollectionView
        }
        
        retrieveOutfits()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.shyNavBarManager = nil
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func initCollectionViewLayout() {
        // layout for outfits tab
        outfitsLayout = SprubixStretchyHeader()
        
        outfitsLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        outfitsLayout.footerHeight = 10
        outfitsLayout.minimumColumnSpacing = 10
        outfitsLayout.minimumInteritemSpacing = 10
        outfitsLayout.columnCount = 2
    }
    
    func initCollectionView() {
        initCollectionViewLayout()
        
        discoverCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: outfitsLayout)
        
        discoverCollectionView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        discoverCollectionView.showsVerticalScrollIndicator = false
        
        discoverCollectionView.registerClass(MainFeedCell.self, forCellWithReuseIdentifier: discoverFeedCellIdentifier)
        
        discoverCollectionView.alwaysBounceVertical = true
        discoverCollectionView.backgroundColor = sprubixGray
        
        discoverCollectionView.dataSource = self;
        discoverCollectionView.delegate = self;
        
        // infinite scrolling
        discoverCollectionView.addInfiniteScrollingWithActionHandler({
            //self.insertMoreOutfits()
        })
        
        view.addSubview(discoverCollectionView)
    }
    
    func initNavBar() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        // 1. add a new title to the nav bar
        self.navigationItem.title = "Discover"
        
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
        negativeSpacerItem.width = -20
        
        self.navigationItem.leftBarButtonItems = [negativeSpacerItem, sideMenuButtonItem]
        
        // 5. go back to main feed buton
        var mainFeedButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "profile-community")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        mainFeedButton.setImage(image, forState: UIControlState.Normal)
        mainFeedButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        mainFeedButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        mainFeedButton.addTarget(self, action: "mainFeedTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var mainFeedBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: mainFeedButton)
        self.navigationItem.rightBarButtonItems = [mainFeedBarButtonItem]
    }

    func initToolbar() {
        // search bar
        let searchBarView = UIView(frame: CGRectMake(0, navigationHeight, screenWidth, searchBarViewHeight))
        
        searchBarView.backgroundColor = sprubixLightGray
        
        searchBarTextField = UITextField(frame: CGRectMake(10, 10, screenWidth - 20, searchBarTextFieldHeight))
        
        searchBarTextField.placeholder = searchBarPlaceholderText
        searchBarTextField.backgroundColor = UIColor.whiteColor()
        searchBarTextField.layer.cornerRadius = 3.0
        searchBarTextField.textColor = UIColor.darkGrayColor()
        searchBarTextField.tintColor = sprubixColor
        searchBarTextField.font = UIFont.systemFontOfSize(15.0)
        //searchBarTextField.textContainerInset = UIEdgeInsetsMake(3, 3, 0, 0);
        searchBarTextField.delegate = self
        searchBarTextField.textAlignment = NSTextAlignment.Center
        
        searchBarView.addSubview(searchBarTextField)
        
        self.shyNavBarManager.extensionView = searchBarView
    }
    
    // REST calls
    func retrieveOutfits() {
        // retrieve 3 example pieces
        manager.POST(SprubixConfig.URL.api + "/outfits/ids",
            parameters: [
                "ids": ["5", "6", "7", "8"]
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.outfits = responseObject["data"] as! [NSDictionary]
                
                /*
                if self.outfits.count <= 0 {
                    // empty dataset
                    self.discoverCollectionView.emptyDataSetSource = self
                    self.discoverCollectionView.emptyDataSetDelegate = self
                } else {
                    self.discoverCollectionView.emptyDataSetSource = nil
                    self.discoverCollectionView.emptyDataSetDelegate = nil
                }
                */
                
                self.discoverCollectionView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return outfits.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:MainFeedCell = collectionView.dequeueReusableCellWithReuseIdentifier(discoverFeedCellIdentifier, forIndexPath: indexPath) as! MainFeedCell
        
        var outfit = outfits[indexPath.row] as NSDictionary
        
        // assign delegate and indexPath
        //cell.delegate = self
        cell.indexPath = indexPath
        
        var outfitId = outfit["id"] as! Int
        cell.itemIdentifier = "outfit_\(outfitId)"
        cell.outfitId = outfitId
        
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
    
    // nav bar button callbacks
    func mainFeedTapped(sender: UIBarButtonItem) {
        UIView.transitionWithView(self.navigationController!.view, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.popViewControllerAnimated(false)
            }, completion: nil)
    }
    
    func sideMenuTapped(sender: UIBarButtonItem) {
        delegate?.toggleSidePanel!()
    }
}

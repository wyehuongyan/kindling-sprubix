//
//  MainFeedController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 26/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

@objc
protocol MainFeedControllerDelegate {
    optional func toggleSidePanel()
    func showUserProfile(user: NSDictionary)
}

class MainFeedController: UIViewController, UICollectionViewDataSource, OutfitInteractionProtocol, CHTCollectionViewDelegateWaterfallLayout, TransitionProtocol {
    var delegate: MainFeedControllerDelegate?
    
    let mainFeedCellIdentifier = "MainFeedCell"
    var mainCollectionView: UICollectionView!
    
    var outfits:[NSDictionary] = [NSDictionary]()
    var outfitsLiked:NSMutableDictionary = NSMutableDictionary()
    var outfitsLayout:SprubixStretchyHeader!
    
    var refreshControl:UIRefreshControl!
    var createOutfitButton:UIButton!
    var lastContentOffset:CGFloat = 0
    var lastNavOffset:CGFloat = 0
    
    let cellInfoViewHeight: CGFloat = 80
    
    var spruceViewController: SpruceViewController?
    
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
        self.shyNavBarManager.expansionResistance = 20
        self.shyNavBarManager.contractionResistance = 0
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = sprubixColor
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        mainCollectionView.insertSubview(refreshControl, atIndex: 0)
        refreshControl.endRefreshing()
        
        initButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        // 1. add a new navigation item w/title to the new nav bar
        var newNavItem:UINavigationItem = UINavigationItem()
        
        // 2. create a custom button
        var sideMenuButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        sideMenuButton.setImage(UIImage(named: "main-hamburger"), forState: UIControlState.Normal)
        let sideMenuButtonWidth: CGFloat = 30
        sideMenuButton.frame = CGRect(x: 0, y: 0, width: sideMenuButtonWidth, height: sideMenuButtonWidth)
        sideMenuButton.imageEdgeInsets = UIEdgeInsetsMake(5, -20, 5, 23)
        sideMenuButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        sideMenuButton.addTarget(self, action: "sideMenuTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // 2.1 badge for notifications attached to hamburger
        let badgeWidth:CGFloat = 20
        mainBadge.frame = CGRectMake(5, sideMenuButtonWidth / 2 - badgeWidth / 2, badgeWidth, badgeWidth)
        mainBadge.backgroundColor = sprubixColor
        mainBadge.layer.cornerRadius = badgeWidth / 2
        mainBadge.clipsToBounds = true
        mainBadge.layer.borderWidth = 1.0
        mainBadge.layer.borderColor = sprubixGray.CGColor
        mainBadge.textColor = UIColor.whiteColor()
        mainBadge.textAlignment = NSTextAlignment.Center
        mainBadge.font = UIFont(name: mainBadge.font.fontName, size: 10)
        mainBadge.text = "\(sprubixNotificationsCount)"
        
        if sprubixNotificationsCount <= 0 {
            mainBadge.alpha = 0
        }
        
        sideMenuButton.addSubview(mainBadge)
        
        var SideMenuButtonItem:UIBarButtonItem = UIBarButtonItem(customView: sideMenuButton)
        SideMenuButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        self.navigationItem.leftBarButtonItem = SideMenuButtonItem
        
        if(refreshControl.refreshing) {
            refreshControl.endRefreshing()
        }
        
        spruceViewController?.view.removeFromSuperview()
        spruceViewController = nil
        
        if self.shyNavBarManager.scrollView == nil {
            self.shyNavBarManager.scrollView = self.mainCollectionView
        }
        
        retrieveOutfits()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.shyNavBarManager = nil
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
    
    // REST calls
    func retrieveOutfits() {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            // retrieve 3 example pieces
            manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/outfits/following",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    self.outfits = responseObject["data"] as! [NSDictionary]
                    
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
        createOutfitButton.addTarget(self, action: "createOutfit:", forControlEvents: UIControlEvents.TouchUpInside)
        
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
        
        // assign delegate and indexPath
        cell.delegate = self
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
    
    func unlikedOutfit(outfitId: Int, itemIdentifier: String, user receiver: NSDictionary) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            // firebase collections: users, likes, poutfits and notifications
            let likesRef = firebaseRef.childByAppendingPath("likes")
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            let poutfitsRef = firebaseRef.childByAppendingPath("poutfits")
            let poutfitLikesRef = poutfitsRef.childByAppendingPath("\(itemIdentifier)/likes")
            
            let senderUsername = userData!["username"] as! String
            let receiverUsername = receiver["username"] as! String
            let poutfitLikesUserRef = poutfitLikesRef.childByAppendingPath(senderUsername) // to be removed
            
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            
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
                                    
                                    let userNotificationRef = receiverUserNotificationsRef.childByAppendingPath(notificationRefKey) // to be removed
                                    
                                    // remove all values
                                    notificationRef.removeValue()
                                    userNotificationRef.removeValue()
                                    likeRef.removeValue()
                                    poutfitLikesUserRef.removeValue()
                                    
                                    self.outfitsLiked.setObject(false, forKey: outfitId)
                                    
                                    println("Outfit unliked successfully!")
                                }
                            })
                            
                        }
                    })
                }
            })
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    func likedOutfit(outfitId: Int, outfitImageURL: String, itemIdentifier: String, user receiver: NSDictionary) {
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
            let poutfitLikesUserRef = poutfitLikesRef.childByAppendingPath(senderUsername)
            
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            
            let createdAt = timestamp
            
            // check if user has already liked this outfit
            poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if (snapshot.value as? NSNull) != nil {
                    // does not exist, add it
                    let likeRef = likesRef.childByAutoId()
                    
                    let like = [
                        "author": senderUsername, // yourself
                        "created_at": timestamp,
                        "poutfit": itemIdentifier
                    ]
                    
                    likeRef.setValue(like, withCompletionBlock: {
                        (error:NSError?, ref:Firebase!) in
                        
                        if (error != nil) {
                            println("Error: Like could not be added.")
                        } else {
                            // update child values: poutfits
                            poutfitLikesRef.updateChildValues([
                                userData!["username"] as! String: likeRef.key
                                ])
                            
                            // push new notifications
                            let notificationRef = notificationsRef.childByAutoId()
                            
                            let notification = [
                                "poutfit": [
                                    "key": itemIdentifier,
                                    "image": outfitImageURL
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
                                }
                            })
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
    
    func commentOutfit() {
    }
    
    func showProfile(user: NSDictionary) {
        delegate?.showUserProfile(user)
    }
    
    func tappedOutfit(indexPath: NSIndexPath) {
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
            spruceViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SpruceView") as? SpruceViewController
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
        println("create button CTA")
    }
}
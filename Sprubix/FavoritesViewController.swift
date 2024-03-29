//
//  FavoritesViewController
//  Sprubix
//
//  Created by Yan Wye Huong on 7/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import CHTCollectionViewWaterfallLayout
import AFNetworking

enum FavoriteState {
    case Outfits
    case Pieces
}

class FavoritesViewController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout, TransitionProtocol {
    var currentFavoriteState: FavoriteState = .Outfits
    
    let profileOutfitCellIdentifier = "ProfileOutfitCell"
    let profilePieceCellIdentifier = "ProfilePieceCell"
    
    let toolbarHeight:CGFloat = 50
    var button1: UIButton!
    var button2: UIButton!
    var buttonLine: UIView!
    var currentChoice: UIButton!
    var activityView: UIActivityIndicatorView!
    
    var currentPage: Int?
    var lastPage: Int?
    
    // liked
    var likedOutfits:[NSDictionary] = [NSDictionary]()
    var likedPieces:[NSDictionary] = [NSDictionary]()
    var likedOutfitIds: [String]! = [String]()
    var likedPieceIds: [String]! = [String]()
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    // collection view layouts
    var likedOutfitsLayout: SprubixStretchyHeader!
    var likedPiecesLayout: SprubixStretchyHeader!
    
    // collection views
    var likedCollectionView: UICollectionView!
    
    // track first launch to prevent double counting (skip once)
    var firstLaunch: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        initLayout()
        initCollectionViews()
        retrieveLikedOutfits()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        
        self.navigationController!.delegate = nil
        
        firstLaunch = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        likedCollectionView.addInfiniteScrollingWithActionHandler({
            self.insertMoreItems()
        })
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Favorites"
        
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
    
    func initLayout() {
        // create toolbar
        var toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: toolbarHeight))
        toolbar.clipsToBounds = true
        toolbar.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        
        // toolbar items
        var buttonWidth = screenWidth / 2
        
        button1 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button1.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: toolbarHeight)
        button1.backgroundColor = UIColor.whiteColor()
        //button1.setImage(UIImage(named: "profile-myoutfits"), forState: UIControlState.Normal)
        button1.setTitle("Outfits", forState: UIControlState.Normal)
        button1.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button1.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //button1.setImage(UIImage(named: "profile-myoutfits"), forState: UIControlState.Selected)
        button1.tintColor = UIColor.lightGrayColor()
        button1.autoresizesSubviews = true
        button1.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button1.exclusiveTouch = true
        button1.addTarget(self, action: "likedOutfitsPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        button2 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button2.frame = CGRect(x: buttonWidth, y: 0, width: buttonWidth, height: toolbarHeight)
        button2.backgroundColor = UIColor.whiteColor()
        //button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Normal)
        button2.setTitle("Items", forState: UIControlState.Normal)
        button2.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button2.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Selected)
        button2.tintColor = UIColor.lightGrayColor()
        button2.autoresizesSubviews = true
        button2.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button2.exclusiveTouch = true
        button2.addTarget(self, action: "likedPiecesPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        toolbar.addSubview(button1)
        toolbar.addSubview(button2)
        
        view.addSubview(toolbar)
        
        // set when button is selected
        buttonLine = UIView(frame: CGRect(x: 0, y: button1.frame.height - 2.0, width: button1.frame.width, height: 2))
        buttonLine.backgroundColor = sprubixColor
        
        // button 1 is initially selected
        button1.addSubview(buttonLine)
        button1.tintColor = sprubixColor
    }
    
    func initCollectionViews() {
        // layout for outfits
        likedOutfitsLayout = SprubixStretchyHeader()
        
        likedOutfitsLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        likedOutfitsLayout.footerHeight = 10
        likedOutfitsLayout.minimumColumnSpacing = 10
        likedOutfitsLayout.minimumInteritemSpacing = 10
        likedOutfitsLayout.columnCount = 3
        
        // init collection view
        likedCollectionView = UICollectionView(frame: CGRectMake(0, navigationHeight + toolbarHeight, screenWidth, screenHeight - (navigationHeight + toolbarHeight)), collectionViewLayout: likedOutfitsLayout)
        
        likedCollectionView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        likedCollectionView.showsVerticalScrollIndicator = false
        likedCollectionView.bounces = true
        likedCollectionView.alwaysBounceVertical = true
        
        // // register classes
        likedCollectionView.registerClass(ProfileOutfitCell.self, forCellWithReuseIdentifier: profileOutfitCellIdentifier)
        likedCollectionView.registerClass(ProfilePieceCell.self, forCellWithReuseIdentifier: profilePieceCellIdentifier)
        
        // empty dataset
        likedCollectionView.emptyDataSetSource = self
        likedCollectionView.emptyDataSetDelegate = self
        
        likedCollectionView.dataSource = self
        likedCollectionView.delegate = self
        likedCollectionView.backgroundColor = sprubixGray
        
        view.addSubview(likedCollectionView)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: screenHeight / 3 - activityViewWidth / 2, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
    }
    
    func retrieveLikedOutfits() {
        // retrieve from poutfit identifiers from firebase first
        // then retrieve the complete data from kindling
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            activityView.startAnimating()
            
            let username = userData!["username"] as! String
            let userLikesRef = firebaseRef.childByAppendingPath("users/\(username)/likes")
            
            // oldest at index 0
            userLikesRef.queryOrderedByChild("created_at").observeSingleEventOfType(.Value, withBlock: { snapshot in
                if (snapshot.value as? NSNull) != nil {
                    // does not exist
                    println("Firebase snapshot for \'users/\(username)/likes\' does not exist")
                    
                    self.activityView.stopAnimating()
                } else {
                    let likedItems = snapshot.value as! NSDictionary
                    
                    for (key, value) in likedItems {
                        let likedItem = value as! NSDictionary
                        let poutfitIdentifier = likedItem["poutfit"] as! String
                        
                        let poutfitData = split(poutfitIdentifier) {$0 == "_"}
                        let poutfitType = poutfitData[0]
                        let poutfitId = poutfitData[1]
                        
                        switch poutfitType {
                        case "outfit":
                            self.likedOutfitIds.insert(poutfitId, atIndex: 0)
                        case "piece":
                            self.likedPieceIds.insert(poutfitId, atIndex: 0)
                        default:
                            fatalError("Error: Unknown poutfitType.")
                        }
                    }
                    
                    if self.likedOutfitIds.count > 0 {
                        self.likedOutfitsPressed(self.button1)
                    } else {
                        self.activityView?.stopAnimating()
                    }
                }
            })
            
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String = ""
        
        switch(currentFavoriteState) {
        case .Outfits:
            text = "\nOutfits that you've liked"
        case .Pieces:
            text = "\nItems that you've liked"
        }
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String = ""
        
        switch(currentFavoriteState) {
        case .Outfits:
            text = "When you like an outfit, you'll see it here."
        case .Pieces:
            text = "When you like an item, you'll see it here."
        }
        
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
        var image: UIImage!
        
        switch(currentFavoriteState) {
        case .Outfits:
            image = UIImage(named: "emptyset-favorites-outfit")
        case .Pieces:
            image = UIImage(named: "emptyset-favorites-piece")
        }
        
        return image
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        var itemHeight: CGFloat!
        var itemWidth: CGFloat!
        
        switch(currentFavoriteState) {
        case .Outfits:
            let likedOutfit = likedOutfits[indexPath.row] as NSDictionary
            itemHeight = likedOutfit["height"] as! CGFloat
            itemWidth = likedOutfit["width"] as! CGFloat
        case .Pieces:
            let likedPiece = likedPieces[indexPath.row] as NSDictionary
            itemHeight = likedPiece["height"] as! CGFloat
            itemWidth = likedPiece["height"] as! CGFloat
        }
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight)
    }

    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        switch(currentFavoriteState) {
        case .Outfits:
            count = likedOutfits.count
        case .Pieces:
            count = likedPieces.count
        }
        
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell:UICollectionViewCell!
        
        switch(currentFavoriteState) {
        case .Outfits:
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(profileOutfitCellIdentifier, forIndexPath: indexPath) as! ProfileOutfitCell
            
            var likedOutfit = likedOutfits[indexPath.row] as NSDictionary
            var outfitImagesString = likedOutfit["images"] as! NSString
            var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
            
            (cell as! ProfileOutfitCell).imageURLString = outfitImageDict["small"] as! String
            
        case .Pieces:
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(profilePieceCellIdentifier, forIndexPath: indexPath) as! ProfilePieceCell
            
            var likedPiece = likedPieces[indexPath.row] as NSDictionary
            var pieceImagesString = likedPiece["images"] as! NSString
            var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
            (cell as! ProfilePieceCell).imageURLString = pieceImagesDict["cover"] as! String
            
            // this part is to calculate the correct dimensions of the ProfilePieceCell.
            // On the UI it appears as a square but the real dimensions must be recorded for the animation scale to work properly
            let pieceHeight = likedPiece["height"] as! CGFloat
            let pieceWidth = likedPiece["width"] as! CGFloat
            
            let imageGridHeight = pieceHeight * gridWidth/pieceWidth
            
            (cell as! ProfilePieceCell).imageGridSize = CGRect(x: 0, y: 0, width: gridWidth, height: imageGridHeight)
        }
        
        cell.setNeedsLayout()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        switch(currentFavoriteState) {
        case .Outfits:
            let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath: indexPath)
            
            outfitDetailsViewController.outfits = likedOutfits
            outfitDetailsViewController.delegate = containerViewController.mainInstance()
            
            collectionView.setToIndexPath(indexPath)
            
            self.navigationController!.delegate = transitionDelegateHolder
            navigationController!.pushViewController(outfitDetailsViewController, animated: true)
            
            // Mixpanel - Viewed Outfit Details
            mixpanel.track("Viewed Outfit Details", properties: [
                "Source": "Favorites View",
                "Outfit ID": likedOutfits[indexPath.row].objectForKey("id") as! Int,
                "Owner User ID": likedOutfits[indexPath.row].objectForKey("user_id") as! Int
            ])
            // Mixpanel - End
        case .Pieces:
            let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath: indexPath)
            
            pieceDetailsViewController.pieces = likedPieces
            collectionView.setToIndexPath(indexPath)
            
            self.navigationController!.delegate = transitionDelegateHolder
            navigationController!.pushViewController(pieceDetailsViewController, animated: true)
            
            // Mixpanel - Viewed Piece Details
            mixpanel.track("Viewed Piece Details", properties: [
                "Source": "Favorites View",
                "Piece ID": likedPieces[indexPath.row].objectForKey("id") as! Int,
                "Owner User ID": likedPieces[indexPath.row].objectForKey("user_id") as! Int
            ])
            // Mixpanel - End
        default:
            break
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

    // TransitionProtocol
    func transitionCollectionView() -> UICollectionView!{
        return likedCollectionView
    }
    
    // button callbacks
    func likedOutfitsPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            self.currentPage = nil
            self.lastPage = nil
            self.currentFavoriteState = FavoriteState.Outfits
        
            activityView.startAnimating()
            
            manager.POST(SprubixConfig.URL.api + "/outfits/ids",
                parameters: [
                    "ids": self.likedOutfitIds
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    self.likedOutfits = responseObject["data"] as! [NSDictionary]
                    
                    // if state is still outfits (user may switch away)
                    if self.currentFavoriteState == .Outfits {
                        self.currentPage = responseObject["current_page"] as? Int
                        self.lastPage = responseObject["last_page"] as? Int
                        self.currentFavoriteState = FavoriteState.Outfits

                        self.activityView.stopAnimating()
                        self.likedCollectionView.reloadData()
                        
                        self.likedCollectionView.collectionViewLayout.invalidateLayout()
                        self.likedCollectionView.setCollectionViewLayout(self.likedOutfitsLayout, animated: false)
                        }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    self.activityView.stopAnimating()
            })
            
            
            // Mixpanel - Viewed Favorites, Outfit
            if !firstLaunch {
                mixpanel.track("Viewed Favorites", properties: [
                    "Source": "Favorites View",
                    "Tab": "Outfit"
                ])
            }
            firstLaunch = false
            // Mixpanel - End
        }
    }
    
    func likedPiecesPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            self.currentPage = nil
            self.lastPage = nil
            self.currentFavoriteState = FavoriteState.Pieces
            
            // // pieces
            activityView.startAnimating()
            
            manager.POST(SprubixConfig.URL.api + "/pieces/ids",
                parameters: [
                    "ids": likedPieceIds
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in

                    self.likedPieces = responseObject["data"] as! [NSDictionary]
                    
                    // if state is still pieces (user may switch away)
                    if self.currentFavoriteState == .Pieces {
                        self.currentPage = responseObject["current_page"] as? Int
                        self.lastPage = responseObject["last_page"] as? Int
                        self.currentFavoriteState = FavoriteState.Pieces
                        
                        self.activityView.stopAnimating()
                        self.likedCollectionView.reloadData()
                        
                        self.likedCollectionView.collectionViewLayout.invalidateLayout()
                        self.likedCollectionView.setCollectionViewLayout(self.likedOutfitsLayout, animated: false)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    self.activityView?.stopAnimating()
            })
            
            // Mixpanel - Viewed Favorites, Piece
            mixpanel.track("Viewed Favorites", properties: [
                "Source": "Favorites View",
                "Tab": "Piece"
            ])
            // Mixpanel - End
        }
    }
    
    func insertMoreItems() {
        println("insert more items")
        
        if currentPage < lastPage {
            switch(currentFavoriteState) {
            case .Outfits:
                insertMoreOutfits()
            case .Pieces:
                insertMorePieces()
            }
        } else {
            // currentPage >= lastPage
            if self.likedCollectionView.infiniteScrollingView != nil {
                self.likedCollectionView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    private func insertMoreOutfits() {
        let nextPage = currentPage! + 1
        
        manager.POST(SprubixConfig.URL.api + "/outfits/ids?page=\(nextPage)",
            parameters: [
                "ids": self.likedOutfitIds
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                let moreOutfits = responseObject["data"] as! [NSDictionary]
                
                for moreOutfit in moreOutfits {
                    self.likedOutfits.append(moreOutfit)
                    
                    self.likedCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.likedOutfits.count - 1, inSection: 0)])
                }
                
                self.currentPage = nextPage
                
                if self.likedCollectionView.infiniteScrollingView != nil {
                    self.likedCollectionView.infiniteScrollingView.stopAnimating()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                self.activityView.stopAnimating()
                
                if self.likedCollectionView.infiniteScrollingView != nil {
                    self.likedCollectionView.infiniteScrollingView.stopAnimating()
                }
        })
    }
    
    private func insertMorePieces() {
        let nextPage = currentPage! + 1
        
        manager.POST(SprubixConfig.URL.api + "/pieces/ids?page=\(nextPage)",
            parameters: [
                "ids": likedPieceIds
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                let morePieces = responseObject["data"] as! [NSDictionary]
                
                for morePiece in morePieces {
                    self.likedPieces.append(morePiece)
                    
                    self.likedCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.likedPieces.count - 1, inSection: 0)])
                }
                
                self.currentPage = nextPage
                
                if self.likedCollectionView.infiniteScrollingView != nil {
                    self.likedCollectionView.infiniteScrollingView.stopAnimating()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                if self.likedCollectionView.infiniteScrollingView != nil {
                    self.likedCollectionView.infiniteScrollingView.stopAnimating()
                }
        })
    }
    
    private func deselectAllButtons() {
        buttonLine.removeFromSuperview()
        
        button1.tintColor = UIColor.lightGrayColor()
        button2.tintColor = UIColor.lightGrayColor()
        
        self.activityView.stopAnimating()
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

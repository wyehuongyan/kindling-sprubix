//
//  UserProfileViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import CHTCollectionViewWaterfallLayout
import AFNetworking

enum ProfileState {
    case Outfits
    case Pieces
    case Community
}

class UserProfileViewController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout, TransitionProtocol, UserProfileHeaderDelegate, EditProfileProtocol, PieceInteractionProtocol {
    
    var user: NSDictionary?
    
    var outfitsLoaded: Bool = false
    var piecesLoaded: Bool = false
    var communityLoaded: Bool = false
    var currentPage: Int?
    var lastPage: Int?
    
    var ownProfile: Bool = false
    var alreadyFollowed: Bool?
    
    let profileOutfitCellIdentifier = "ProfileOutfitCell"
    let profilePieceCellIdentifier = "ProfilePieceCell"
    let userProfileHeaderIdentifier = "UserProfileHeader"
    let userProfileFooterIdentifier = "UserProfileFooter"

    var headerReusableView: UserProfileHeader?
    var footerReusableView: UserProfileFooter?
    
    var userOutfitsLayout:SprubixStretchyHeader!
    var userPiecesLayout:SprubixStretchyHeader!
    
    let userProfileHeaderHeight:CGFloat = 300;
    var emptyDataTableView: UITableView?
    var emptyDataView: UIView?
    
    var outfits:[NSDictionary] = [NSDictionary]()
    var pieces:[NSDictionary] = [NSDictionary]()
    var communityOutfits:[NSDictionary] = [NSDictionary]()
    
    var profileCollectionView: UICollectionView!
    var currentProfileState: ProfileState = .Pieces
    var activityView: UIActivityIndicatorView?
    
    @IBOutlet var closeUserProfileButton: UIBarButtonItem!
    @IBAction func closeUserProfile(sender: UIBarButtonItem) {
        self.navigationController!.delegate = nil
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    @IBOutlet var followUserButton: UIButton!
    @IBAction func followUser(sender: AnyObject) {
        if ownProfile == true {
            // followUserButton is now an edit profile button
            let editProfileViewController = UIStoryboard.editProfileViewController()
            
            editProfileViewController!.delegate = self
            
            self.navigationController?.delegate = nil
            self.navigationController?.pushViewController(editProfileViewController!, animated: true)
        } else {
            // follow user
            if alreadyFollowed != true {
                self.followUserButton.setTitle("Unfollow", forState: UIControlState.Normal)
                
                manager.POST(SprubixConfig.URL.api + "/user/follow",
                    parameters: [
                        "follow_user_id": user!["id"] as! Int
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        var status = responseObject["status"] as! String
                        
                        if status == "200" {
                            //println("followed")
                            // send notification to followed user
                            let receiverUsername = self.user!["username"] as! String
                            let recipientId = self.user!["id"] as! Int
                            
                            self.sendNotification(receiverUsername, recipientId: recipientId)
                            
                            self.alreadyFollowed = true
                            
                        } else if status == "500" {
                            //println("error in following user")
                            
                            self.followUserButton.setTitle("Follow", forState: UIControlState.Normal)
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        self.followUserButton.setTitle("Follow", forState: UIControlState.Normal)
                })
            } else {
                // unfollow user
                
                let username = user!["username"] as! String
                
                var alert = UIAlertController(title: "Stop following \(username)?", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.view.tintColor = sprubixColor
                
                // Yes
                alert.addAction(UIAlertAction(title: "Unfollow", style: UIAlertActionStyle.Destructive, handler: { action in
                    
                    self.followUserButton.setTitle("Follow", forState: UIControlState.Normal)
                    
                    manager.POST(SprubixConfig.URL.api + "/user/unfollow",
                        parameters: [
                            "unfollow_user_id": self.user!["id"] as! Int
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                            
                            var status = responseObject["status"] as! String
                            
                            if status == "200" {
                                //println("unfollowed")
                                self.alreadyFollowed = false
                                
                            } else if status == "500" {
                                //println("error in unfollowing user")
                                
                                self.followUserButton.setTitle("UnFollow", forState: UIControlState.Normal)
                            }
                        },
                        failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                            println("Error: " + error.localizedDescription)
                            
                            self.followUserButton.setTitle("UnFollow", forState: UIControlState.Normal)
                    })
                }))
                
                // No
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        // initialization
        if user != nil {
            initUserProfile()
            loadUserFollow()
            //loadUserOutfits()
        } else {
            fatalError("User Profile user is nil.")
        }
        
        Glow.addGlow(followUserButton)
        
        // barbuttons title text color
        var shadow = NSShadow()
        shadow.shadowColor = UIColor.lightGrayColor()
        shadow.shadowOffset = CGSizeMake(1.0, 1.0)
        shadow.shadowBlurRadius = 100.0
        
        var color: UIColor = sprubixColor
        var titleFont: UIFont = UIFont.boldSystemFontOfSize(17)
        
        closeUserProfileButton.setTitleTextAttributes([
            NSFontAttributeName: titleFont,
            NSForegroundColorAttributeName: color,
            NSShadowAttributeName: shadow
            ], forState: UIControlState.Normal)
        
        self.navigationController!.delegate = transitionDelegateHolder
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func initUserProfile() {
        initCollectionViewLayouts()
        
        profileCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: userOutfitsLayout)
        profileCollectionView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        profileCollectionView.showsVerticalScrollIndicator = false
        
        profileCollectionView.registerClass(ProfileOutfitCell.self, forCellWithReuseIdentifier: profileOutfitCellIdentifier)
        profileCollectionView.registerClass(ProfilePieceCell.self, forCellWithReuseIdentifier: profilePieceCellIdentifier)
        profileCollectionView.registerClass(UserProfileHeader.self, forSupplementaryViewOfKind: CHTCollectionElementKindSectionHeader, withReuseIdentifier: userProfileHeaderIdentifier)
        profileCollectionView.registerClass(UserProfileFooter.self, forSupplementaryViewOfKind: CHTCollectionElementKindSectionFooter, withReuseIdentifier: userProfileFooterIdentifier)
        
        profileCollectionView.alwaysBounceVertical = true
        profileCollectionView.backgroundColor = sprubixGray
        
        profileCollectionView.dataSource = self;
        profileCollectionView.delegate = self;
        
        view.addSubview(profileCollectionView)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView?.color = sprubixColor
        activityView?.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: 0.6 * screenHeight - activityViewWidth / 2, width: activityViewWidth, height: activityViewWidth)
        
        profileCollectionView.addSubview(activityView!)
    }
    
    func initCollectionViewLayouts() {
        //var userPieceslayout:CHTCollectionViewWaterfallLayout = CHTCollectionViewWaterfallLayout()
        
        // layout for outfits tab
        userOutfitsLayout = SprubixStretchyHeader()
        
        userOutfitsLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        userOutfitsLayout.headerHeight = userProfileHeaderHeight
        userOutfitsLayout.footerHeight = 10
        userOutfitsLayout.minimumColumnSpacing = 10
        userOutfitsLayout.minimumInteritemSpacing = 10
        userOutfitsLayout.columnCount = 3
        
        // layout for pieces tab
        userPiecesLayout = SprubixStretchyHeader()
        
        userPiecesLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        userPiecesLayout.headerHeight = userProfileHeaderHeight
        userPiecesLayout.footerHeight = 10
        userPiecesLayout.minimumColumnSpacing = 10
        userPiecesLayout.minimumInteritemSpacing = 10
        userPiecesLayout.columnCount = 3
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadUserItems()
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        profileCollectionView.addInfiniteScrollingWithActionHandler({
            self.insertMoreItems()
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = nil
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 22 {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        } else {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        var itemHeight:CGFloat!
        var itemWidth:CGFloat!
        
        switch(currentProfileState) {
        case .Outfits:
            let outfit = outfits[indexPath.row] as NSDictionary
            itemHeight = outfit["height"] as! CGFloat
            itemWidth = outfit["width"] as! CGFloat
        case .Pieces:
            if pieces.count > 0 {
                let piece = pieces[indexPath.row] as NSDictionary
                itemHeight = piece["height"] as! CGFloat
                itemWidth = piece["height"] as! CGFloat
            }
        case .Community:
            if communityOutfits.count > 0 {
                let communityOutfit = communityOutfits[indexPath.row] as NSDictionary
                itemHeight = communityOutfit["height"] as! CGFloat
                itemWidth = communityOutfit["width"] as! CGFloat
            }
        default:
            break
        }

        if itemWidth != nil {
            let imageHeight = itemHeight * gridWidth/itemWidth
            
            return CGSizeMake(gridWidth, imageHeight)
        } else {
            return CGSizeMake(gridWidth, 0)
        }
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        switch(currentProfileState) {
        case .Outfits:
            count = outfits.count
        case .Pieces:
            count = pieces.count
        case .Community:
            count = communityOutfits.count
        default:
            break
        }
        
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell:UICollectionViewCell!
        
        switch(currentProfileState) {
        case .Outfits:
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(profileOutfitCellIdentifier, forIndexPath: indexPath) as! ProfileOutfitCell
            
            if outfits.count > 0 {
                var outfit = outfits[indexPath.row] as NSDictionary
                var outfitImagesString = outfit["images"] as! NSString
                var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
                
                (cell as! ProfileOutfitCell).imageURLString = outfitImageDict["small"] as! String
            }

        case .Pieces:
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(profilePieceCellIdentifier, forIndexPath: indexPath) as! ProfilePieceCell
            
            if pieces.count > 0 {
                var piece = pieces[indexPath.row] as NSDictionary
                var pieceImagesString = piece["images"] as! NSString
                var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                (cell as! ProfilePieceCell).imageURLString = pieceImagesDict["cover"] as! String
                
                // this part is to calculate the correct dimensions of the ProfilePieceCell.
                // On the UI it appears as a square but the real dimensions must be recorded for the animation scale to work properly
                let pieceHeight = piece["height"] as! CGFloat
                let pieceWidth = piece["width"] as! CGFloat
                
                let imageGridHeight = pieceHeight * gridWidth/pieceWidth
                
                (cell as! ProfilePieceCell).imageGridSize = CGRect(x: 0, y: 0, width: gridWidth, height: imageGridHeight)
            }
        case .Community:
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(profileOutfitCellIdentifier, forIndexPath: indexPath) as! ProfileOutfitCell
            
            if communityOutfits.count > 0 {
                var communityOutfit = communityOutfits[indexPath.row] as NSDictionary
                var communityImagesString = communityOutfit["images"] as! NSString
                var communityImagesData:NSData = communityImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var communityImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(communityImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                var communityImageDict: NSDictionary = communityImagesDict["images"] as! NSDictionary
                
                (cell as! ProfileOutfitCell).imageURLString = communityImageDict["small"] as! String
            }
        default:
            break
        }
        
        cell.setNeedsLayout()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == CHTCollectionElementKindSectionHeader {
            if headerReusableView == nil {
                headerReusableView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: userProfileHeaderIdentifier, forIndexPath: indexPath) as? UserProfileHeader
                
                if user != nil {
                    headerReusableView!.user = user
                }
                
                headerReusableView!.setProfileInfo()
                headerReusableView!.delegate = self
            }
            
            return headerReusableView!
            
        } else if kind == CHTCollectionElementKindSectionFooter {
            footerReusableView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: userProfileFooterIdentifier, forIndexPath: indexPath) as? UserProfileFooter
        }
        
        return footerReusableView!
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        switch(currentProfileState) {
        case .Outfits:
            let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath:indexPath)
            outfitDetailsViewController.outfits = outfits
            outfitDetailsViewController.delegate = containerViewController.mainInstance()
            
            collectionView.setToIndexPath(indexPath)
            
            navigationController?.delegate = transitionDelegateHolder
            navigationController!.pushViewController(outfitDetailsViewController, animated: true)
            
            // Mixpanel - Viewed Outfit Details
            mixpanel.track("Viewed Outfit Details", properties: [
                "Source": "Profile View",
                "Tab": "Outfit",
                "Outfit ID": outfits[indexPath.row].objectForKey("id") as! Int,
                "Owner User ID": outfits[indexPath.row].objectForKey("user_id") as! Int
            ])
            // Mixpanel - End
        case .Pieces:
            let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath:indexPath)
            pieceDetailsViewController.pieces = pieces
            pieceDetailsViewController.user = user
            pieceDetailsViewController.pieceInteractionDelegate = self
            
            collectionView.setToIndexPath(indexPath)
            
            navigationController?.delegate = transitionDelegateHolder
            navigationController!.pushViewController(pieceDetailsViewController, animated: true)
            
            // Mixpanel - Viewed Piece Details
            mixpanel.track("Viewed Piece Details", properties: [
                "Source": "Profile View",
                "Tab": "Piece",
                "Piece ID": pieces[indexPath.row].objectForKey("id") as! Int,
                "Owner User ID": pieces[indexPath.row].objectForKey("user_id") as! Int
            ])
            // Mixpanel - End
        case .Community:
            let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath:indexPath)
            outfitDetailsViewController.outfits = communityOutfits
            outfitDetailsViewController.delegate = containerViewController.mainInstance()
            
            collectionView.setToIndexPath(indexPath)
            
            navigationController?.delegate = transitionDelegateHolder
            navigationController!.pushViewController(outfitDetailsViewController, animated: true)
            
            // Mixpanel - Viewed Outfit Details
            mixpanel.track("Viewed Outfit Details", properties: [
                "Source": "Profile View",
                "Tab": "Community",
                "Outfit ID": communityOutfits[indexPath.row].objectForKey("id") as! Int,
                "Owner User ID": communityOutfits[indexPath.row].objectForKey("user_id") as! Int
            ])
            // Mixpanel - End
        default:
            break
        }
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
    
    // determine if this user can be followed or not
    func loadUserFollow() {
        let targetUserId:Int? = user!["id"] as? Int
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if targetUserId != nil && targetUserId != userId {
            manager.POST(SprubixConfig.URL.api + "/user/followed",
                parameters: [
                    "id": targetUserId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    self.alreadyFollowed = responseObject["already_followed"] as? Bool
                    
                    //println(responseObject)
                    
                    if self.alreadyFollowed != nil {
                        if self.alreadyFollowed == true {
                            // already followed
                            self.followUserButton.setTitle("Unfollow", forState: UIControlState.Normal)
                        } else {
                            self.followUserButton.setTitle("Follow", forState: UIControlState.Normal)
                        }
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            //println("this is your own profile")
            ownProfile = true
            self.followUserButton.setTitle("Edit Profile", forState: UIControlState.Normal)
        }
    }
    
    func showEmptyDataSet() {
        emptyDataTableView?.removeFromSuperview()
        emptyDataView?.removeFromSuperview()
        
        emptyDataTableView = UITableView(frame: CGRectMake(0, userProfileHeaderHeight, screenWidth, screenHeight - userProfileHeaderHeight))
        
        emptyDataView = UIView(frame: CGRectMake(0, userProfileHeaderHeight + emptyDataTableView!.frame.height, screenWidth, screenHeight))
        emptyDataView?.backgroundColor = sprubixGray
        
        profileCollectionView?.insertSubview(emptyDataTableView!, belowSubview: activityView!)
        profileCollectionView?.insertSubview(emptyDataView!, belowSubview: activityView!)
        
        emptyDataTableView?.emptyDataSetDelegate = self
        emptyDataTableView?.emptyDataSetSource = self
        emptyDataTableView?.tableFooterView = UIView()
    }
    
    func hideEmptyDataSet() {
        emptyDataTableView?.removeFromSuperview()
        emptyDataView?.removeFromSuperview()
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String = ""
        
        // Default descriptions, for other profiles
        switch(currentProfileState) {
        case .Outfits:
            text = "Outfits created"
        case .Pieces:
            text = "Items in closet"
        case .Community:
            text = "Outfits created by the community"
        }
        
        // Own profile
        if let targetUserId:Int? = user!["id"] as? Int, userId:Int? = defaults.objectForKey("userId") as? Int {
            if targetUserId == userId {
                switch(currentProfileState) {
                case .Outfits:
                    text = "Outfits you've created"
                case .Pieces:
                    text = "Items in your closet"
                case .Community:
                    text = "Outfits created by the community"
                }
            }
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
        
        // Default descriptions, for other profiles
        switch(currentProfileState) {
        case .Outfits:
            text = "When the user creates or spruces an outfit, you'll see it here."
        case .Pieces:
            text = "When the user uploads an item, you'll see it here."
        case .Community:
            text = "When the community creates an outfit for the user, you'll see it here."
        }
        
        // Own profile
        if let targetUserId:Int? = user!["id"] as? Int, userId:Int? = defaults.objectForKey("userId") as? Int {
            if targetUserId == userId {
                switch(currentProfileState) {
                case .Outfits:
                    text = "When you create or spruce an outfit, you'll see it here."
                case .Pieces:
                    text = "When you upload an item, you'll see it here."
                case .Community:
                    text = "When the community creates an outfit for you, you'll see it here."
                }
            }
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
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
    
    // infinite scrolling
    func insertMoreItems() {
        var userId:Int? = user!["id"] as? Int
        
        if userId != nil {
            if currentPage < lastPage {
                switch(currentProfileState) {
                case .Outfits:
                    insertMoreOutfits(userId!)
                case .Pieces:
                    insertMorePieces(userId!)
                case .Community:
                    insertMoreCommunityOutfits(userId!)
                }
            } else {
                // currentPage >= lastPage
                if self.profileCollectionView.infiniteScrollingView != nil {
                    self.profileCollectionView.infiniteScrollingView.stopAnimating()
                }
            }
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    private func insertMoreOutfits(userId: Int) {
        // GET page=2, page=3 and so on
        let nextPage = currentPage! + 1
        
        manager.GET(SprubixConfig.URL.api + "/user/\(userId)/outfits?page=\(nextPage)",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                let moreOutfits = responseObject["data"] as! [NSDictionary]
                
                for moreOutfit in moreOutfits {
                    self.outfits.append(moreOutfit)
                    
                    self.profileCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.outfits.count - 1, inSection: 0)])
                }
                
                self.currentPage = nextPage
                
                if self.profileCollectionView.infiniteScrollingView != nil {
                    self.profileCollectionView.infiniteScrollingView.stopAnimating()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                if self.profileCollectionView.infiniteScrollingView != nil {
                    self.profileCollectionView.infiniteScrollingView.stopAnimating()
                }
        })
    }
    
    private func insertMorePieces(userId: Int) {
        let nextPage = currentPage! + 1
        
        manager.GET(SprubixConfig.URL.api + "/user/\(userId)/pieces?page=\(nextPage)",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                let morePieces = responseObject["data"] as! [NSDictionary]
                
                for morePiece in morePieces {
                    self.pieces.append(morePiece)
                    
                    self.profileCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.pieces.count - 1, inSection: 0)])
                }
                
                self.currentPage = nextPage
                
                if self.profileCollectionView.infiniteScrollingView != nil {
                    self.profileCollectionView.infiniteScrollingView.stopAnimating()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                if self.profileCollectionView.infiniteScrollingView != nil {
                    self.profileCollectionView.infiniteScrollingView.stopAnimating()
                }
        })
    }
    
    private func insertMoreCommunityOutfits(userId: Int) {
        let nextPage = currentPage! + 1
        
        manager.GET(SprubixConfig.URL.api + "/user/\(userId)/community?page=\(nextPage)",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                let moreCommunityOutfits = responseObject["data"] as! [NSDictionary]
                
                for moreCommunityOutfit in moreCommunityOutfits {
                    self.communityOutfits.append(moreCommunityOutfit)
                    
                    self.profileCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.communityOutfits.count - 1, inSection: 0)])
                }
                
                self.currentPage = nextPage
                
                if self.profileCollectionView.infiniteScrollingView != nil {
                    self.profileCollectionView.infiniteScrollingView.stopAnimating()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                if self.profileCollectionView.infiniteScrollingView != nil {
                    self.profileCollectionView.infiniteScrollingView.stopAnimating()
                }
        })
    }
    
    // UserProfileHeaderDelegate
    func showFollowers() {
        showFollowList(false)
    }
    
    func showFollowing() {
        showFollowList(true)
    }
    
    private func showFollowList(following: Bool) {
        let userFollowListViewController = UIStoryboard.userFollowListViewController()
        
        userFollowListViewController!.following = following
        userFollowListViewController!.user = user
        
        self.navigationController?.delegate = nil
        self.navigationController?.pushViewController(userFollowListViewController!, animated: true)
    }
    
    func loadUserOutfits() {
        if outfitsLoaded != true {
            var userId:Int? = user!["id"] as? Int
            
            if userId != nil {
                self.currentProfileState = .Outfits
                activityView?.startAnimating()
                profileCollectionView.scrollEnabled = false
                
                manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/outfits",
                    parameters: nil,
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        self.outfits = responseObject["data"] as! [NSDictionary]
                        
                        // if state is still pieces (user may switch away)
                        if self.currentProfileState == .Outfits {
                            self.currentPage = responseObject["current_page"] as? Int
                            self.lastPage = responseObject["last_page"] as? Int
                            self.activityView?.stopAnimating()
                            
                            if self.outfits.count > 0 {
                                //self.outfitsLoaded = true
                                self.hideEmptyDataSet()
                                self.profileCollectionView.reloadData()
                                
                                // set layout
                                self.profileCollectionView.collectionViewLayout.invalidateLayout()
                                self.profileCollectionView.setCollectionViewLayout(self.userOutfitsLayout, animated: false)
                            } else {
                                //println("Oops, there are no outfits in your closet.")
                                self.showEmptyDataSet()
                            }
                        }
                        
                        self.profileCollectionView.scrollEnabled = true
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        self.activityView?.stopAnimating()
                        SprubixReachability.handleError(error.code)
                })
            } else {
                println("userId not found, please login or create an account")
            }
        } else {
            // outfits already loaded
            self.currentProfileState = .Outfits
            self.profileCollectionView.reloadData()
            
            // set layout
            self.profileCollectionView.setCollectionViewLayout(self.userOutfitsLayout, animated: false)
        }
    }
    
    func loadUserPieces() {
        if piecesLoaded != true {
            var userId:Int? = user!["id"] as? Int
            
            if userId != nil {
                self.currentProfileState = .Pieces
                activityView?.startAnimating()
                profileCollectionView.scrollEnabled = false
                
                manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/pieces",
                    parameters: nil,
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        self.pieces = responseObject["data"] as! [NSDictionary]
                        
                        // if state is still pieces (user may switch away)
                        if self.currentProfileState == .Pieces {
                            self.currentPage = responseObject["current_page"] as? Int
                            self.lastPage = responseObject["last_page"] as? Int
                            self.activityView?.stopAnimating()
                            
                            if self.pieces.count > 0 {
                                //self.piecesLoaded = true
                                self.hideEmptyDataSet()
                                self.profileCollectionView.reloadData()
                                
                                // set layout
                                self.profileCollectionView.collectionViewLayout.invalidateLayout()
                                self.profileCollectionView.setCollectionViewLayout(self.userPiecesLayout, animated: false)
                            } else {
                                //println("Oops, there are no pieces in your closet.")
                                self.showEmptyDataSet()
                            }
                        }
                        
                        self.profileCollectionView.scrollEnabled = true
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        self.activityView?.stopAnimating()
                        SprubixReachability.handleError(error.code)
                })
            } else {
                println("userId not found, please login or create an account")
            }
        } else {
            self.currentProfileState = .Pieces
            self.profileCollectionView.reloadData()
            
            // set layout
            self.profileCollectionView.setCollectionViewLayout(self.userPiecesLayout, animated: false)
        }
    }
    
    func loadCommunityOutfits() {
        if communityLoaded != true {
            var userId:Int? = user!["id"] as? Int
            
            if userId != nil {
                self.currentProfileState = .Community
                activityView?.startAnimating()
                profileCollectionView.scrollEnabled = false
                
                manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/outfits/community",
                    parameters: nil,
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        self.communityOutfits = responseObject["data"] as! [NSDictionary]
                        
                        // if state is still community (user may switch away)
                        if self.currentProfileState == .Community {
                            self.currentPage = responseObject["current_page"] as? Int
                            self.lastPage = responseObject["last_page"] as? Int
                            self.activityView?.stopAnimating()
                            
                            if self.communityOutfits.count > 0 {
                                //self.communityLoaded = true
                                self.hideEmptyDataSet()
                                self.profileCollectionView.reloadData()
                                
                                // set layout
                                self.profileCollectionView.collectionViewLayout.invalidateLayout()
                                self.profileCollectionView.setCollectionViewLayout(self.userOutfitsLayout, animated: false)
                            } else {
                                //println("Oops, there are no community outfits in your closet.")
                                self.showEmptyDataSet()
                            }
                        }
                        
                        self.profileCollectionView.scrollEnabled = true
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        self.activityView?.stopAnimating()
                        SprubixReachability.handleError(error.code)
                })
            } else {
                println("userId not found, please login or create an account")
            }
        } else {
            // community outfits already loaded
            self.currentProfileState = .Community
            self.profileCollectionView.reloadData()
            
            // set layout
            self.profileCollectionView.setCollectionViewLayout(self.userOutfitsLayout, animated: false)
        }
    }
    
    // send firebase notification for follow
    private func sendNotification(receiverUsername: String, recipientId: Int) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            // firebase collections: users and notifications
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            
            let senderUsername = userData!["username"] as! String
            let senderImage = userData!["image"] as! String
            
            if senderUsername != receiverUsername {
                
                let createdAt = timestamp
                let shoppableType: String? = userData!["shoppable_type"] as? String
                
                let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
                
                // push new notifications
                let notificationRef = notificationsRef.childByAutoId()
                
                let notification = [
                    "created_at": createdAt,
                    "sender": [
                        "username": senderUsername, // yourself
                        "image": senderImage
                    ],
                    "receiver": receiverUsername,
                    "type": "follow",
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
                                } else {
                                    let pushMessage = "@\(senderUsername) started following you."
                                    
                                    APNS.sendPushNotification(pushMessage, recipientId: recipientId)
                                }
                        })
                    }
                })
            }
        }
    }
    
    // EditProfileProtocol
    func updateUser(user: NSDictionary) {
        self.user = user
        
        headerReusableView!.user = user
        headerReusableView!.setProfileInfo()
        headerReusableView!.setNeedsDisplay()
        headerReusableView!.setNeedsLayout()
    }
    
    private func reloadUserItems() {
        switch(currentProfileState) {
        case .Outfits:
            outfitsLoaded = false
            loadUserOutfits()
        case .Pieces:
            piecesLoaded = false
            loadUserPieces()
        case .Community:
            communityLoaded = false
            loadCommunityOutfits()
        }
    }
    
    // PieceInteractionProtocol
    func likedPiece(piece: NSDictionary) {
        // needed:
        // // pieceId, thumbnailURLString, itemIdentifier, receiver
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            let pieceId = piece["id"] as! Int
            let receiver = piece["user"] as! NSDictionary
            let pieceImagesString = piece["images"] as! NSString
            let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
            
            let thumbnailURLString = pieceImageDict["thumbnail"] as! String
            let itemIdentifier = "piece_\(pieceId)"
            
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
            
            // check if user has already liked this piece
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
                                    
                                    if receiverUsername != senderUsername {
                                        receiverUserNotificationRef.updateChildValues([
                                            "created_at": createdAt,
                                            "unread": true
                                            ], withCompletionBlock: {
                                                
                                                (error:NSError?, ref:Firebase!) in
                                                
                                                if (error != nil) {
                                                    println("Error: Notification Key could not be added to Users.")
                                                } else {
                                                    // send APNS
                                                    let recipientId = receiver["id"] as! Int
                                                    let senderId = userData!["id"] as! Int
                                                    
                                                    if recipientId != senderId {
                                                        let pushMessage = "\(senderUsername) liked your item."
                                                        
                                                        APNS.sendPushNotification(pushMessage, recipientId: recipientId)
                                                    }
                                                }
                                        })
                                    }
                                    
                                    // update likes with notification key
                                    likeRef.updateChildValues([
                                        "notification": notificationRef.key
                                        ], withCompletionBlock: {
                                            
                                            (error:NSError?, ref:Firebase!) in
                                            
                                            if (error != nil) {
                                                println("Error: Notification Key could not be added to Likes.")
                                                
                                            } else {
                                                println("Piece liked successfully!")
                                            }
                                    })
                                }
                            })
                            
                            // Mixpanel - Liked Pieces
                            mixpanel.track("Liked Pieces", properties: [
                                "Piece ID": pieceId,
                                "Owner User ID": receiver["id"] as! Int
                                ])
                            mixpanel.people.increment("Pieces Liked", by: 1)
                            // Mixpanel - End
                        }
                    })
                    
                } else {
                    println("You have already liked this piece")
                }
            })
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    func unlikedPiece(piece: NSDictionary) {
        // needed:
        // // pieceId, itemIdentifier, receiver
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            let pieceId = piece["id"] as! Int
            let receiver = piece["user"] as! NSDictionary
            let itemIdentifier = "piece_\(pieceId)"
            
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
                    println("You have already unliked this piece")
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
                                    
                                    println("Piece unliked successfully!")
                                }
                            })
                            
                            // Mixpanel - Liked Pieces (decrement)
                            mixpanel.people.increment("Pieces Liked", by: -1)
                            // Mixpanel - End
                        }
                    })
                }
            })
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    // TransitionProtocol
    func transitionCollectionView() -> UICollectionView!{
        return profileCollectionView
    }
}

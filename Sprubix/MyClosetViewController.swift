//
//  MyClosetViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 16/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import AFNetworking

protocol SpruceSelectedPiecesProtocol {
    func insertSelectedClosetPieces(closetPieces: [NSDictionary])
}

class MyClosetViewController: UIViewController, UICollectionViewDataSource,  CHTCollectionViewDelegateWaterfallLayout {
    
    var delegate: SpruceSelectedPiecesProtocol?
    
    let toolBarHeight: CGFloat = 70
    
    var results: [NSDictionary] = [NSDictionary]()
    var currentPage: Int = 0
    var lastPage: Int = 0
    
    var resultsLayout: SprubixStretchyHeader!
    var resultsCollectionView: UICollectionView!
    let resultCellIdentifier = "ProfilePieceCell"
    
    var pieceTypes: [String] = ["HEAD", "TOP", "BOTTOM", "FEET"]
    var pieceTypeButtons: [UIButton] = [UIButton]()
    var selectedPieceTypes: [String: Bool] = ["HEAD": false, "TOP": false, "BOTTOM": false, "FEET": false]
    
    var selectedPieces: [NSDictionary] = [NSDictionary]()
    var selectedPieceIds: NSMutableArray = NSMutableArray()
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    var activityView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        initToolbar()
        initCollectionView()
        
        // retrieve user pieces
        retrieveUserPieces()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        resultsCollectionView.addInfiniteScrollingWithActionHandler({
            self.insertMorePieces()
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "My Closet"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        backButton.setTitle("X", forState: UIControlState.Normal)
        backButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        backButton.addTarget(self, action: "closeTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("done", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "doneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initToolbar() {
        // tool bar
        let pieceTypeFilterScrollView = UIScrollView(frame: CGRectMake(0, navigationHeight, screenWidth, toolBarHeight))
        pieceTypeFilterScrollView.backgroundColor = sprubixLightGray
        
        var prevButtonPos: CGFloat = 0
        let pieceTypeButtonWidth: CGFloat = 50
        let buttonPadding: CGFloat = (screenWidth - (CGFloat(pieceTypes.count) * pieceTypeButtonWidth)) / (CGFloat(pieceTypes.count) + 1)
        
        // create buttons for each piece type
        for var i = 0; i < pieceTypes.count; i++ {
            var pieceType = pieceTypes[i]
            
            let pieceTypeButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            
            let image: UIImage = UIImage(named: getButtonImage(pieceType))!
            pieceTypeButton.frame = CGRectMake(buttonPadding + prevButtonPos, 10, pieceTypeButtonWidth, pieceTypeButtonWidth)
            pieceTypeButton.setImage(image, forState: UIControlState.Normal)
            pieceTypeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            pieceTypeButton.backgroundColor = UIColor.lightGrayColor()
            pieceTypeButton.layer.cornerRadius = pieceTypeButtonWidth / 2
            pieceTypeButton.exclusiveTouch = true
            pieceTypeButton.addTarget(self, action: "pieceTypeButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            
            prevButtonPos = pieceTypeButton.frame.origin.x + pieceTypeButton.frame.size.width
            
            pieceTypeFilterScrollView.addSubview(pieceTypeButton)
            pieceTypeButtons.append(pieceTypeButton)
        }
        
        view.addSubview(pieceTypeFilterScrollView)
    }
    
    private func getButtonImage(pieceType: String) -> String {
        switch(pieceType) {
        case "HEAD":
            return "view-item-cat-head"
        case "TOP":
            return "view-item-cat-top"
        case "BOTTOM":
            return "view-item-cat-bot"
        case "FEET":
            return "view-item-cat-feet"
        default:
            fatalError("Error: Unknown piece type, unable to return button image string.")
        }
    }
    
    func initCollectionViewLayout() {
        // layout for pieces tab
        resultsLayout = SprubixStretchyHeader()
        
        resultsLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        resultsLayout.footerHeight = 10
        resultsLayout.minimumColumnSpacing = 10
        resultsLayout.minimumInteritemSpacing = 10
        resultsLayout.columnCount = 3
    }
    
    func initCollectionView() {
        initCollectionViewLayout()
        
        // collection view
        resultsCollectionView = UICollectionView(frame: CGRectMake(0, navigationHeight + toolBarHeight, screenWidth, screenHeight - navigationHeight - toolBarHeight), collectionViewLayout: resultsLayout)
        
        resultsCollectionView.registerClass(ProfilePieceCell.self, forCellWithReuseIdentifier: resultCellIdentifier)
        
        resultsCollectionView.alwaysBounceVertical = true
        resultsCollectionView.backgroundColor = sprubixGray
        
        resultsCollectionView.dataSource = self;
        resultsCollectionView.delegate = self;
        
        view.addSubview(resultsCollectionView)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: ((screenHeight - navigationHeight - toolBarHeight) / 2 - activityViewWidth / 2), width: activityViewWidth, height: activityViewWidth)
        
        resultsCollectionView.addSubview(activityView)
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return results.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(resultCellIdentifier, forIndexPath: indexPath) as! ProfilePieceCell
        
        var result = results[indexPath.row] as NSDictionary
        var pieceImagesString = result["images"] as! NSString
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        (cell as! ProfilePieceCell).imageURLString = pieceImagesDict["cover"] as! String
        
        // this part is to calculate the correct dimensions of the ProfilePieceCell.
        // On the UI it appears as a square but the real dimensions must be recorded for the animation scale to work properly
        let pieceHeight = result["height"] as! CGFloat
        let pieceWidth = result["width"] as! CGFloat
        
        let imageGridHeight = pieceHeight * gridWidth/pieceWidth
        
        (cell as! ProfilePieceCell).imageGridSize = CGRect(x: 0, y: 0, width: gridWidth, height: imageGridHeight)
        
        // check if piece was selected by user previously
        let pieceId = result["id"] as! Int
        
        if selectedPieceIds.containsObject(pieceId) == true {
            // selected previously
            cell.layer.borderColor = sprubixColor.CGColor
            cell.layer.borderWidth = 3.0
        } else {
            cell.layer.borderColor = UIColor.lightGrayColor().CGColor
            cell.layer.borderWidth = 1.0
        }
        
        cell.setNeedsLayout()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell: UICollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! ProfilePieceCell
        let selectedPiece = results[indexPath.row]
        let selectedPieceId = selectedPiece["id"] as! Int
        
        if selectedPieceIds.containsObject(selectedPieceId) == true {
            // remove object
            selectedPieceIds.removeObjectIdenticalTo(selectedPieceId)
            
            var pos = find(selectedPieces, selectedPiece)
            selectedPieces.removeAtIndex(pos!)
            
            cell.layer.borderColor = UIColor.lightGrayColor().CGColor
            cell.layer.borderWidth = 1.0
        } else {
            selectedPieceIds.addObject(selectedPieceId)
            selectedPieces.append(selectedPiece)
            
            cell.layer.borderColor = sprubixColor.CGColor
            cell.layer.borderWidth = 3.0
        }
    }
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        var itemHeight:CGFloat!
        var itemWidth:CGFloat!
        
        let piece = results[indexPath.row] as NSDictionary
        itemHeight = piece["height"] as! CGFloat
        itemWidth = piece["height"] as! CGFloat
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight)
    }
    
    // piece type filter button callback
    func pieceTypeButtonTapped(sender: UIButton) {
        let pos = find(pieceTypeButtons, sender)
        
        let pieceType = pieceTypes[pos!]
        
        if sender.selected != true {
            sender.backgroundColor = sprubixColor
            sender.selected = true
            selectedPieceTypes[pieceType] = true
        } else {
            sender.backgroundColor = UIColor.lightGrayColor()
            sender.selected = false
            selectedPieceTypes[pieceType] = false
        }
        
        retrieveUserPieces()
    }
    
    func retrieveUserPieces() {
        var types: [String] = [String]()
        
        for (key, value) in selectedPieceTypes {
            if value == true {
                types.append(key)
            }
        }
        
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            
            self.resultsCollectionView.reloadData()
            activityView.startAnimating()
            
            manager.POST(SprubixConfig.URL.api + "/pieces",
                parameters: [
                    "user_id": userId!,
                    "types": types
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    self.results = responseObject["data"] as! [NSDictionary]
                    self.currentPage = responseObject["current_page"] as! Int
                    self.lastPage = responseObject["last_page"] as! Int
                    
                    self.resultsCollectionView.reloadData()
                    self.activityView.stopAnimating()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    func insertMorePieces() {
        if currentPage < lastPage {
            var types: [String] = [String]()
            
            for (key, value) in selectedPieceTypes {
                if value == true {
                    types.append(key)
                }
            }
            
            let userId:Int? = defaults.objectForKey("userId") as? Int
            
            if userId != nil {
                let nextPage = currentPage + 1
                
                manager.POST(SprubixConfig.URL.api + "/pieces?page=\(nextPage)",
                    parameters: [
                        "user_id": userId!,
                        "types": types
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        let moreOutfits = responseObject["data"] as! [NSDictionary]
                        
                        for moreOutfit in moreOutfits {
                            self.results.append(moreOutfit)
                            
                            self.resultsCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.results.count - 1, inSection: 0)])
                        }
                        
                        self.currentPage = nextPage
                        
                        if self.resultsCollectionView.infiniteScrollingView != nil {
                            self.resultsCollectionView.infiniteScrollingView.stopAnimating()
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            } else {
                println("userId not found, please login or create an account")
            }
        } else {
            if self.resultsCollectionView.infiniteScrollingView != nil {
                self.resultsCollectionView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    // navigation bar button callbacks
    func doneTapped(sender: UIBarButtonItem) {
        delegate?.insertSelectedClosetPieces(selectedPieces)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func closeTapped(sender: UIBarButtonItem) {
        self.navigationController?.delegate = nil
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromBottom
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
        self.navigationController?.popViewControllerAnimated(false)
    }
}

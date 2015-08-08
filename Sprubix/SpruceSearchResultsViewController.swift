//
//  SpruceSearchResultsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 18/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import AFNetworking

class SpruceSearchResultsViewController: UIViewController, UICollectionViewDataSource,  CHTCollectionViewDelegateWaterfallLayout {
    
    var delegate: SpruceSelectedPiecesProtocol?
    
    var searchTagStrings: [String] = [String]()
    var types: [String] = [String]()
    
    // collection view
    var results: [NSDictionary] = [NSDictionary]()
    var currentPage: Int!
    var lastPage: Int!
    
    var resultsLayout: SprubixStretchyHeader!
    var resultsCollectionView: UICollectionView!
    let resultCellIdentifier = "ProfilePieceCell"
    
    // selected
    var selectedPieceTypes: [String: Bool] = ["HEAD": false, "TOP": false, "BOTTOM": false, "FEET": false]
    
    var selectedPieces: [NSDictionary] = [NSDictionary]()
    var selectedPieceIds: NSMutableArray = NSMutableArray()
    
    // keyboard
    var dismissKeyboardTap: UITapGestureRecognizer!
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    var activityView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        initCollectionView()
        
        // retrieve search results
        retrieveSearchPieces()
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
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Results"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("done", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "doneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
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
        resultsCollectionView = UICollectionView(frame: CGRectMake(0, navigationHeight, screenWidth, screenHeight - navigationHeight), collectionViewLayout: resultsLayout)
        
        resultsCollectionView.registerClass(ProfilePieceCell.self, forCellWithReuseIdentifier: resultCellIdentifier)
        
        resultsCollectionView.alwaysBounceVertical = true
        resultsCollectionView.backgroundColor = sprubixGray
        
        resultsCollectionView.dataSource = self;
        resultsCollectionView.delegate = self;
        
        view.addSubview(resultsCollectionView)
        
        // gesture recognizer on tableview to dismiss keyboard on tap
        dismissKeyboardTap = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        
        dismissKeyboardTap.numberOfTapsRequired = 1
        dismissKeyboardTap.cancelsTouchesInView = false
        dismissKeyboardTap.enabled = true
        
        resultsCollectionView.addGestureRecognizer(dismissKeyboardTap)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: (screenHeight / 2 - activityViewWidth / 2), width: activityViewWidth, height: activityViewWidth)
        
        resultsCollectionView.addSubview(activityView)
    }
    
    func retrieveSearchPieces() {
        var fullTextSearchString: String = join(" ", searchTagStrings)
        
        activityView.startAnimating()
        
        // REST call to server to retrieve search pieces
        manager.POST(SprubixConfig.URL.api + "/pieces",
            parameters: [
                "full_text": fullTextSearchString,
                "types": types
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.results = responseObject["data"] as! [NSDictionary]
                self.currentPage = responseObject["current_page"] as? Int
                self.lastPage = responseObject["last_page"] as? Int
                
                self.resultsCollectionView.reloadData()
                self.activityView.stopAnimating()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func insertMorePieces() {
        if currentPage < lastPage {
            var fullTextSearchString: String = join(" ", searchTagStrings)
            
            activityView.startAnimating()
            
            let nextPage = currentPage! + 1
            
            manager.POST(SprubixConfig.URL.api + "/pieces?page=\(nextPage)",
                parameters: [
                    "full_text": fullTextSearchString,
                    "types": types
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    let moreOutfits = responseObject["data"] as! [NSDictionary]
                    
                    for moreOutfit in moreOutfits {
                        self.results.append(moreOutfit)
                        
                        self.resultsCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.results.count - 1, inSection: 0)])
                    }
                    
                    self.currentPage = nextPage
                    self.resultsCollectionView.infiniteScrollingView.stopAnimating()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            self.resultsCollectionView.infiniteScrollingView.stopAnimating()
        }
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
    
    // gesture recognizer callbacks
    func dismissKeyboard(gesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // nav bar button callbacks
    func doneTapped(sender: UIBarButtonItem) {
        delegate?.insertSelectedClosetPieces(selectedPieces)
        
        let spruceViewController: SpruceViewController = self.navigationController?.viewControllers[self.navigationController!.viewControllers.count - 3] as! SpruceViewController
        self.navigationController?.popToViewController(spruceViewController, animated: true)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

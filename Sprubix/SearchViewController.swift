//
//  SearchViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 3/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import AFNetworking

enum SearchBarState {
    case Outfits
    case Pieces
    case People
}

class SearchViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, TransitionProtocol {
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    var searchBar: UISearchBar!
    let searchBarHeight: CGFloat = 50
    
    let toolbarHeight:CGFloat = 50
    var outfitToolbarButton: UIButton!
    var pieceToolbarButton: UIButton!
    var peopleToolbarButton: UIButton!
    var buttonLine: UIView!
    var toolbarLine: UIView!
    
    var pieces: [NSDictionary] = [NSDictionary]()
    var outfits: [NSDictionary] = [NSDictionary]()
    var people: [NSDictionary] = [NSDictionary]()
    var currentPage: Int! = 0
    var lastPage: Int!
    
    // collection view
    var outfitsPiecesCollectionView: UICollectionView!
    
    var resultsPieceLayout: SprubixStretchyHeader!
    var resultsOutfitLayout: SprubixStretchyHeader!
    
    // table view
    let resultsPieceCellIdentifier = "ProfilePieceCell"
    let resultsOutfitCellIdentifier = "ProfileOutfitCell"
    let resultsSearchUserCellIdentifier: String = "SearchUserCell"
    
    var peopleTableView: UITableView!
    
    // search outfits and pieces
    var fullTextSearchString: String = ""
    var types: [String] = ["HEAD", "TOP", "BOTTOM", "FEET"]
    
    var activityView: UIActivityIndicatorView!
    
    var currentSearchBarState: SearchBarState = SearchBarState.Outfits
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()

        initSearchBar()
        initToolBar()
        initCollectionView()
        initTableView()
        
        // default selected
        outfitToolbarButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        
        // infinite scrolling
        outfitsPiecesCollectionView.addInfiniteScrollingWithActionHandler({
            if SprubixReachability.isConnectedToNetwork() {
                self.insertMoreItems()
            }
        })
        
        peopleTableView.addInfiniteScrollingWithActionHandler({
            if SprubixReachability.isConnectedToNetwork() {
                self.insertMoreItems()
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Search"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        //var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        //backButton.setImage(image, forState: UIControlState.Normal)
        backButton.setTitle("X", forState: UIControlState.Normal)
        backButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
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
        nextButton.setTitle("search", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "searchTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.popViewControllerAnimated(false)
            }, completion: nil)
    }
    
    func searchTapped(sender: UIBarButtonItem) {
        search()
    }
    
    func initSearchBar() {
        let searchBarY: CGFloat = navigationHeight
        searchBar = UISearchBar(frame: CGRect(x: 0, y: searchBarY, width: screenWidth, height: searchBarHeight))
        searchBar.delegate = self
        searchBar.barTintColor = sprubixLightGray
        searchBar.placeholder = "Search for outfits, items or people"
        
        view.addSubview(searchBar)
    }
    
    func initToolBar() {
        // create toolbar
        let toolbarY: CGFloat = navigationHeight + searchBarHeight
        var toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: toolbarY, width: screenWidth, height: toolbarHeight))
        toolbar.clipsToBounds = false
        toolbar.shadowImageForToolbarPosition(UIBarPosition.Bottom)
        toolbar.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        
        // toolbar items
        var buttonWidth = screenWidth / 3
        
        outfitToolbarButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        outfitToolbarButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: toolbarHeight)
        outfitToolbarButton.backgroundColor = UIColor.whiteColor()
        outfitToolbarButton.setTitle("Outfits", forState: UIControlState.Normal)
        outfitToolbarButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        outfitToolbarButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        outfitToolbarButton.tintColor = UIColor.lightGrayColor()
        outfitToolbarButton.autoresizesSubviews = true
        outfitToolbarButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        outfitToolbarButton.exclusiveTouch = true
        outfitToolbarButton.addTarget(self, action: "outfitsPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceToolbarButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        pieceToolbarButton.frame = CGRect(x: buttonWidth, y: 0, width: buttonWidth, height: toolbarHeight)
        pieceToolbarButton.backgroundColor = UIColor.whiteColor()
        pieceToolbarButton.setTitle("Items", forState: UIControlState.Normal)
        pieceToolbarButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        pieceToolbarButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        pieceToolbarButton.tintColor = UIColor.lightGrayColor()
        pieceToolbarButton.autoresizesSubviews = true
        pieceToolbarButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        pieceToolbarButton.exclusiveTouch = true
        pieceToolbarButton.addTarget(self, action: "itemsPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        peopleToolbarButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        peopleToolbarButton.frame = CGRect(x: buttonWidth*2, y: 0, width: buttonWidth, height: toolbarHeight)
        peopleToolbarButton.backgroundColor = UIColor.whiteColor()
        peopleToolbarButton.setTitle("People", forState: UIControlState.Normal)
        peopleToolbarButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        peopleToolbarButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        peopleToolbarButton.tintColor = UIColor.lightGrayColor()
        peopleToolbarButton.autoresizesSubviews = true
        peopleToolbarButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        peopleToolbarButton.exclusiveTouch = true
        peopleToolbarButton.addTarget(self, action: "peoplePressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        toolbar.addSubview(outfitToolbarButton)
        toolbar.addSubview(pieceToolbarButton)
        toolbar.addSubview(peopleToolbarButton)

        self.view.addSubview(toolbar)
        
        // toolbar bottom border
        toolbarLine = UIView(frame: CGRect(x: 0, y: outfitToolbarButton.frame.height - 0.5, width: screenWidth, height: 0.5))
        toolbarLine.backgroundColor = UIColor.lightGrayColor()
        
        toolbar.addSubview(toolbarLine)
        
        // set when button is selected
        buttonLine = UIView(frame: CGRect(x: 0, y: outfitToolbarButton.frame.height - 2.5, width: outfitToolbarButton.frame.width, height: 2))
        buttonLine.backgroundColor = sprubixColor
    }
    
    func outfitsPressed(sender: UIButton) {
        currentSearchBarState = SearchBarState.Outfits
        deselectAllButtons()
        
        sender.addSubview(buttonLine)
        sender.tintColor = sprubixColor
        
        resetView()
        
        if peopleTableView != nil && peopleTableView.superview != nil {
            peopleTableView.removeFromSuperview()
        }
        
        if outfitsPiecesCollectionView != nil && outfitsPiecesCollectionView.superview == nil {
           view.addSubview(outfitsPiecesCollectionView)
        }
        
        search()
    }
    
    func itemsPressed(sender: UIButton) {
        currentSearchBarState = SearchBarState.Pieces
        deselectAllButtons()
        
        sender.addSubview(buttonLine)
        sender.tintColor = sprubixColor
        
        resetView()
        
        if peopleTableView != nil && peopleTableView.superview != nil {
            peopleTableView.removeFromSuperview()
        }
        
        if outfitsPiecesCollectionView != nil && outfitsPiecesCollectionView.superview == nil {
            view.addSubview(outfitsPiecesCollectionView)
        }
        
        search()
    }
    
    func peoplePressed(sender: UIButton) {
        currentSearchBarState = SearchBarState.People
        deselectAllButtons()
        
        sender.addSubview(buttonLine)
        sender.tintColor = sprubixColor
        
        resetView()
        
        if outfitsPiecesCollectionView != nil && outfitsPiecesCollectionView.superview != nil {
            outfitsPiecesCollectionView.removeFromSuperview()
        }
        
        if peopleTableView != nil && peopleTableView.superview == nil {
            view.addSubview(peopleTableView)
        }
        
        search()
    }
    
    private func deselectAllButtons() {
        buttonLine.removeFromSuperview()
        
        outfitToolbarButton.tintColor = UIColor.lightGrayColor()
        pieceToolbarButton.tintColor = UIColor.lightGrayColor()
        peopleToolbarButton.tintColor = UIColor.lightGrayColor()
    }
    
    func initCollectionViewLayout() {
        // layout for outfits tab
        resultsOutfitLayout = SprubixStretchyHeader()
        resultsOutfitLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        resultsOutfitLayout.footerHeight = 10
        resultsOutfitLayout.minimumColumnSpacing = 10
        resultsOutfitLayout.minimumInteritemSpacing = 10
        resultsOutfitLayout.columnCount = 3
        
        // layout for pieces tab
        resultsPieceLayout = SprubixStretchyHeader()
        resultsPieceLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        resultsPieceLayout.footerHeight = 10
        resultsPieceLayout.minimumColumnSpacing = 10
        resultsPieceLayout.minimumInteritemSpacing = 10
        resultsPieceLayout.columnCount = 3
    }
    
    // Outfits and Pieces
    func initCollectionView() {
        initCollectionViewLayout()
        
        // collection view
        let outfitsPiecesCollectionViewY = navigationHeight + searchBarHeight + toolbarHeight
        outfitsPiecesCollectionView = UICollectionView(frame: CGRectMake(0, outfitsPiecesCollectionViewY, screenWidth, screenHeight - outfitsPiecesCollectionViewY), collectionViewLayout: resultsPieceLayout)
        
        outfitsPiecesCollectionView.registerClass(ProfileOutfitCell.self, forCellWithReuseIdentifier: resultsOutfitCellIdentifier)
        outfitsPiecesCollectionView.registerClass(ProfilePieceCell.self, forCellWithReuseIdentifier: resultsPieceCellIdentifier)
        
        outfitsPiecesCollectionView.alwaysBounceVertical = true
        outfitsPiecesCollectionView.backgroundColor = sprubixGray
        
        outfitsPiecesCollectionView.dataSource = self;
        outfitsPiecesCollectionView.delegate = self;
        
        view.addSubview(outfitsPiecesCollectionView)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        let activityViewY: CGFloat = (screenHeight / 2 - activityViewWidth / 2) - outfitsPiecesCollectionViewY
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: activityViewY, width: activityViewWidth, height: activityViewWidth)
        
        outfitsPiecesCollectionView.addSubview(activityView)
    }
    
    // People
    func initTableView() {
        let peopleTableViewY = navigationHeight + searchBarHeight + toolbarHeight
        peopleTableView = UITableView(frame: CGRectMake(0, peopleTableViewY, screenWidth, screenHeight - peopleTableViewY))
        
        peopleTableView.registerClass(SearchUserCell.self, forCellReuseIdentifier: resultsSearchUserCellIdentifier)
        
        peopleTableView.backgroundColor = sprubixGray
        peopleTableView.dataSource = self
        peopleTableView.delegate = self
        
        view.addSubview(peopleTableView)
        
        // get rid of line seperator for empty cells
        peopleTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        let activityViewY: CGFloat = (screenHeight / 2 - activityViewWidth / 2) - peopleTableViewY
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: activityViewY, width: activityViewWidth, height: activityViewWidth)
        
        peopleTableView.addSubview(activityView)
    }
    
    func retrieveSearchOutfits() {
        
        activityView.startAnimating()
        
        // REST call to server to retrieve search pieces
        manager.POST(SprubixConfig.URL.api + "/outfits/search",
            parameters: [
                "full_text": fullTextSearchString,
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.outfits = responseObject["data"] as! [NSDictionary]
                self.currentPage = responseObject["current_page"] as? Int
                self.lastPage = responseObject["last_page"] as? Int
                
                self.outfitsPiecesCollectionView.reloadData()
                self.activityView.stopAnimating()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func retrieveSearchPieces() {
        
        activityView.startAnimating()
        
        // REST call to server to retrieve search pieces
        manager.POST(SprubixConfig.URL.api + "/pieces/search",
            parameters: [
                "full_text": fullTextSearchString
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.pieces = responseObject["data"] as! [NSDictionary]
                self.currentPage = responseObject["current_page"] as? Int
                self.lastPage = responseObject["last_page"] as? Int
                
                self.outfitsPiecesCollectionView.reloadData()
                self.activityView.stopAnimating()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func retrieveSearchPeople() {
        
        activityView.startAnimating()
        
        // REST call to server to retrieve users
        manager.POST(SprubixConfig.URL.api + "/users/search",
            parameters: [
                "full_text": fullTextSearchString,
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.people = responseObject["data"] as! [NSDictionary]
                self.currentPage = responseObject["current_page"] as! Int
                self.lastPage = responseObject["last_page"] as? Int
                
                if self.peopleTableView.infiniteScrollingView != nil {
                    self.peopleTableView.infiniteScrollingView.stopAnimating()
                }
                
                self.peopleTableView.reloadData()
                self.activityView.stopAnimating()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                if self.peopleTableView.infiniteScrollingView != nil {
                    self.peopleTableView.infiniteScrollingView.stopAnimating()
                }
        })
    }
    
    // infinite scrolling
    func insertMoreItems() {
        if currentPage < lastPage {
            switch (currentSearchBarState) {
            case .Outfits:
                insertMoreOutfits()
            case .Pieces:
                insertMorePieces()
            case .People:
                insertMorePeople()
            default:
                break
            }
        } else {
            if self.outfitsPiecesCollectionView.infiniteScrollingView != nil {
                self.outfitsPiecesCollectionView.infiniteScrollingView.stopAnimating()
            }
            
            if self.peopleTableView.infiniteScrollingView != nil {
                self.peopleTableView.infiniteScrollingView.stopAnimating()
            }
        }
    }

    func insertMoreOutfits() {
        if outfits.count > 0 {
            let nextPage = currentPage! + 1
            
            // retrieve more outfits
            manager.POST(SprubixConfig.URL.api + "/outfits/search?page=\(nextPage)",
                parameters: [
                    "full_text": fullTextSearchString
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    let moreOutfits = responseObject["data"] as! [NSDictionary]
                    self.currentPage = responseObject["current_page"] as? Int
                    
                    for moreOutfit in moreOutfits {
                        // add only new pieces
                        if !contains(self.outfits, moreOutfit) {
                            self.outfits.append(moreOutfit)
                            
                            self.outfitsPiecesCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.outfits.count - 1, inSection: 0)])
                        }
                    }
                    
                    if self.outfitsPiecesCollectionView.infiniteScrollingView != nil {
                        self.outfitsPiecesCollectionView.infiniteScrollingView.stopAnimating()
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    if self.outfitsPiecesCollectionView.infiniteScrollingView != nil {
                        self.outfitsPiecesCollectionView.infiniteScrollingView.stopAnimating()
                    }
                    
                    SprubixReachability.handleError(error.code)
            })
            
        } else {
            if self.outfitsPiecesCollectionView.infiniteScrollingView != nil {
                self.outfitsPiecesCollectionView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    func insertMorePieces() {
        if pieces.count > 0 {
            let nextPage = currentPage! + 1
            
            // retrieve more pieces
            manager.POST(SprubixConfig.URL.api + "/pieces/search?page=\(nextPage)",
                parameters: [
                    "full_text": fullTextSearchString
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    let morePieces = responseObject["data"] as! [NSDictionary]
                    self.currentPage = responseObject["current_page"] as? Int
                    
                    for morePiece in morePieces {
                        // add only new pieces
                        if !contains(self.pieces, morePiece) {
                            self.pieces.append(morePiece)
                            
                            self.outfitsPiecesCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.pieces.count - 1, inSection: 0)])
                        }
                    }
                    
                    if self.outfitsPiecesCollectionView.infiniteScrollingView != nil {
                        self.outfitsPiecesCollectionView.infiniteScrollingView.stopAnimating()
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    if self.outfitsPiecesCollectionView.infiniteScrollingView != nil {
                        self.outfitsPiecesCollectionView.infiniteScrollingView.stopAnimating()
                    }
                    
                    SprubixReachability.handleError(error.code)
            })
            
        } else {
            if self.outfitsPiecesCollectionView.infiniteScrollingView != nil {
                self.outfitsPiecesCollectionView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    func insertMorePeople() {
        if people.count > 0 {
            let nextPage = currentPage! + 1
            
            // retrieve more users
            manager.POST(SprubixConfig.URL.api + "/users/search?page=\(nextPage)",
                parameters: [
                    "full_text": fullTextSearchString
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    let moreUsers = responseObject["data"] as! [NSDictionary]
                    self.currentPage = responseObject["current_page"] as? Int
                    
                    for moreUser in moreUsers {
                        // add only new pieces
                        if !contains(self.people, moreUser) {
                            self.people.append(moreUser)
                            
                            self.peopleTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.people.count - 1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Fade)
                        }
                    }
                    
                    if self.peopleTableView.infiniteScrollingView != nil {
                        self.peopleTableView.infiniteScrollingView.stopAnimating()
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    if self.peopleTableView.infiniteScrollingView != nil {
                        self.peopleTableView.infiniteScrollingView.stopAnimating()
                    }
                    
                    SprubixReachability.handleError(error.code)
            })
            
        } else {
            if self.peopleTableView.infiniteScrollingView != nil {
                self.peopleTableView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        switch (currentSearchBarState) {
        case .Outfits:
            count = outfits.count
        case .Pieces:
            count = pieces.count
        default:
            break
        }
        
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!
        
        switch(currentSearchBarState) {
        case .Outfits:
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(resultsOutfitCellIdentifier, forIndexPath: indexPath) as! ProfileOutfitCell
            
            var outfit = outfits[indexPath.row] as NSDictionary
            var outfitImagesString = outfit["images"] as! NSString
            var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
            
            (cell as! ProfileOutfitCell).imageURLString = outfitImageDict["small"] as! String
            
        case .Pieces:
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(resultsPieceCellIdentifier, forIndexPath: indexPath) as! ProfilePieceCell
            
            var result = pieces[indexPath.row] as NSDictionary
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
            
        default:
            break
        }
        
        cell.setNeedsLayout()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        switch(currentSearchBarState) {
        case .Outfits:
            let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath:indexPath)
            outfitDetailsViewController.outfits = outfits
            
            collectionView.setToIndexPath(indexPath)
            
            navigationController?.delegate = transitionDelegateHolder
            navigationController!.pushViewController(outfitDetailsViewController, animated: true)
            
        case .Pieces:
            let piece = pieces[indexPath.row] as NSDictionary
            let pieceId = piece["id"] as! Int
            
            // retrieve outfits using this piece
            manager.GET(SprubixConfig.URL.api + "/piece/\(pieceId)/user",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    let pieceOwner = responseObject as! NSDictionary
                    
                    let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: self.detailsViewControllerLayout(), currentIndexPath:indexPath)
                    pieceDetailsViewController.pieces = self.pieces
                    pieceDetailsViewController.user = pieceOwner
                    
                    collectionView.setToIndexPath(indexPath)
                    
                    self.navigationController?.delegate = transitionDelegateHolder
                    self.navigationController!.pushViewController(pieceDetailsViewController, animated: true)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })

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
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        var itemHeight:CGFloat!
        var itemWidth:CGFloat!
        
        switch(currentSearchBarState) {
        case .Outfits:
            let outfit = outfits[indexPath.row] as NSDictionary
            itemHeight = outfit["height"] as! CGFloat
            itemWidth = outfit["width"] as! CGFloat
        case .Pieces:
            let piece = pieces[indexPath.row] as NSDictionary
            itemHeight = piece["height"] as! CGFloat
            itemWidth = piece["height"] as! CGFloat
        default:
            break
        }
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight)
    }
    
    // UISearchBarDelegate
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        search()
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let user: NSDictionary = people[indexPath.row]
        
        let name = user["name"] as! String
        let username = user["username"] as! String
        let userImageURL = NSURL(string: user["image"] as! String)
        let userId = user["id"] as! Int
        
        var cell: UITableViewCell!
        
        switch(currentSearchBarState) {
        case .People:
            // use UserFollowListCell
            cell = tableView.dequeueReusableCellWithIdentifier(resultsSearchUserCellIdentifier, forIndexPath: indexPath) as! SearchUserCell
            
            (cell as! SearchUserCell).user = user
            (cell as! SearchUserCell).realname.text = name
            (cell as! SearchUserCell).username.text = "@\(username)"
            (cell as! SearchUserCell).userImageView.setImageWithURL(userImageURL)
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
        default:
            break
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch(currentSearchBarState) {
        case .People:
            showProfile(people[indexPath.row])
        default:
            break
        }
    }
    
    func search() {
        fullTextSearchString = searchBar.text

        dismissKeyboard()
        
        println("Search String: \(fullTextSearchString)")
        
        if fullTextSearchString != "" {
            switch(currentSearchBarState) {
            case .Outfits:
                retrieveSearchOutfits()
            case .Pieces:
                retrieveSearchPieces()
            case .People:
                retrieveSearchPeople()
            default:
                break
            }
        }
    }
    
    func showProfile(user: NSDictionary) {
        containerViewController.showUserProfile(user)
    }
    
    func resetView() {
        // reset page counter
        currentPage = 0
        
        if outfitsPiecesCollectionView != nil {
            outfits.removeAll()
            pieces.removeAll()
            outfitsPiecesCollectionView.reloadData()
        }
        
        if peopleTableView != nil {
            people.removeAll()
            peopleTableView.reloadData()
        }
    }
    
    func dismissKeyboard(){
        searchBar.endEditing(true)
    }
    
    // TransitionProtocol
    func transitionCollectionView() -> UICollectionView!{
        return outfitsPiecesCollectionView
    }
}

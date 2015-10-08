//
//  SearchResultsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 3/9/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import AFNetworking
import DZNEmptyDataSet

class SearchResultsViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout, TransitionProtocol, CategoryFilterProtocol, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var results: [NSDictionary] = [NSDictionary]()
    let resultsPieceCellIdentifier = "ProfilePieceCell"
    let resultsOutfitCellIdentifier = "ProfileOutfitCell"
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    var searchBar: UISearchBar?
    
    var searchString: String!
    var searchURL: String!
    var currentScope: Int = 0
    
    var currentPage: Int?
    var lastPage: Int?
    
    // collection view
    var resultsLayout: SprubixStretchyHeader!
    var resultsCollectionView: UICollectionView!
    var resultsCollectionViewY: CGFloat = 0
    
    // filter buttons
    var filterButtonHeight: CGFloat = 50
    var filterButtonCategory: UIButton!
    
    // categories
    var itemCategories: [NSDictionary] = [NSDictionary]()
    var selectedCategory: NSDictionary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        if currentScope == 0 {
            filterButtonHeight = 0
        }
        
        initSearchFilterButtons()
        
        resultsCollectionViewY = navigationHeaderAndStatusbarHeight + filterButtonHeight
        
        initCollectionView()
        
        // empty dataset
        resultsCollectionView.emptyDataSetSource = self
        resultsCollectionView.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        containerViewController.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        initNavBar()
        retrieveItemCategories()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        containerViewController.statusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        resultsCollectionView.addInfiniteScrollingWithActionHandler({
            self.insertMoreResults()
        })
    }
    
    private func retrieveItemCategories() {
        if itemCategories.count <= 0 {
            // REST call to retrieve piece categories
            manager.GET(SprubixConfig.URL.api + "/piece/categories",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    self.itemCategories = responseObject as! [NSDictionary]
                    
                    // insert "All" category
                    var allCategory = NSMutableDictionary()
                    allCategory.setObject("All", forKey: "name")
                    
                    self.itemCategories.insert(allCategory, atIndex: 0)
                    
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
    
    func initNavBar() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeaderAndStatusbarHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        newNavBar.backgroundColor = UIColor.whiteColor()
        newNavBar.translucent = false
        
        // 3. add a new navigation item w/title to the new nav bar
        let searchBarContainer = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight))
        searchBarContainer.backgroundColor = UIColor.whiteColor()
        searchBar = UISearchBar(frame: CGRectMake(0, 0, screenWidth - 50, navigationHeight))
        searchBar?.barTintColor = UIColor.whiteColor()
        searchBar?.backgroundColor = UIColor.whiteColor()
        searchBar?.setBackgroundImage(UIImage(), forBarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
        searchBar?.delegate = self
        searchBar?.text = searchString
        
        searchBarContainer.addSubview(searchBar!)
        
        newNavItem = UINavigationItem()
        newNavItem.titleView = searchBarContainer
        newNavItem.titleView?.userInteractionEnabled = true
        
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
    
    func initSearchFilterButtons() {
        let filterButtonViewY: CGFloat = navigationHeaderAndStatusbarHeight
        let filterButtonView = UIView(frame: CGRect(x: 0, y: filterButtonViewY, width: screenWidth, height: filterButtonHeight))
        filterButtonView.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(filterButtonView)
        
        filterButtonCategory = UIButton(frame: CGRect(x: 0, y: 0, width: screenWidth, height: filterButtonHeight))
        filterButtonCategory.setTitle("Category : All", forState: UIControlState.Normal)
        filterButtonCategory.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        filterButtonCategory.titleLabel?.font = UIFont.boldSystemFontOfSize(15)
        filterButtonCategory.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        filterButtonCategory.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        filterButtonCategory.addTarget(self, action: "categoryPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        filterButtonView.addSubview(filterButtonCategory)
        
        let lineY: CGFloat = filterButtonViewY + filterButtonHeight
        var line: UIView = UIView(frame: CGRect(x: 0, y: lineY - 1 , width: screenWidth, height: 2))
        line.backgroundColor = UIColor.lightGrayColor()
        
        view.addSubview(line)
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
    
    // Outfits and Pieces
    func initCollectionView() {
        initCollectionViewLayout()
        
        // collection view
        resultsCollectionView = UICollectionView(frame: CGRectMake(0, resultsCollectionViewY, screenWidth, screenHeight - navigationHeaderAndStatusbarHeight - filterButtonHeight), collectionViewLayout: resultsLayout)
        
        resultsCollectionView.registerClass(ProfilePieceCell.self, forCellWithReuseIdentifier: resultsPieceCellIdentifier)
        resultsCollectionView.registerClass(ProfileOutfitCell.self, forCellWithReuseIdentifier: resultsOutfitCellIdentifier)
        
        resultsCollectionView.alwaysBounceVertical = true
        resultsCollectionView.backgroundColor = sprubixGray
        
        resultsCollectionView.dataSource = self
        resultsCollectionView.delegate = self
        
        view.addSubview(resultsCollectionView)
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return results.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        switch currentScope {
        case 0:
            // outfits
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(resultsOutfitCellIdentifier, forIndexPath: indexPath) as! ProfileOutfitCell
            
            var outfit = results[indexPath.row] as NSDictionary
            var outfitImagesString = outfit["images"] as! NSString
            var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
            
            cell.imageURLString = outfitImageDict["small"] as! String
            
            return cell
            
        case 1:
            // piece
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(resultsPieceCellIdentifier, forIndexPath: indexPath) as! ProfilePieceCell
            
            var piece = results[indexPath.row] as NSDictionary
            var pieceImagesString = piece["images"] as! NSString
            var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
            (cell as ProfilePieceCell).imageURLString = pieceImagesDict["cover"] as! String
            
            // this part is to calculate the correct dimensions of the ProfilePieceCell.
            // On the UI it appears as a square but the real dimensions must be recorded for the animation scale to work properly
            let pieceHeight = piece["height"] as! CGFloat
            let pieceWidth = piece["width"] as! CGFloat
            
            let imageGridHeight = pieceHeight * gridWidth/pieceWidth
            
            (cell as ProfilePieceCell).imageGridSize = CGRect(x: 0, y: 0, width: gridWidth, height: imageGridHeight)
            
            cell.setNeedsLayout()
            
            return cell
            
        default:
            fatalError("Unknown scope in SearchResultsViewController")
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        switch currentScope {
        case 0:
            let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath: indexPath)
            
            outfitDetailsViewController.outfits = results
            outfitDetailsViewController.delegate = containerViewController.mainInstance()
            collectionView.setToIndexPath(indexPath)
            
            self.navigationController!.delegate = transitionDelegateHolder
            navigationController!.pushViewController(outfitDetailsViewController, animated: true)
            
            // Mixpanel - Viewed Outfit Details
            mixpanel.track("Viewed Outfit Details", properties: [
                "Source": "Search Results",
                "Outfit ID": results[indexPath.row].objectForKey("id") as! Int,
                "Owner User ID": results[indexPath.row].objectForKey("user_id") as! Int
            ])
            // Mixpanel - End
        case 1:
            let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath: indexPath)
            
            pieceDetailsViewController.pieces = results
            collectionView.setToIndexPath(indexPath)
            
            self.navigationController!.delegate = transitionDelegateHolder
            navigationController!.pushViewController(pieceDetailsViewController, animated: true)
            
            // Mixpanel - Viewed Piece Details
            mixpanel.track("Viewed Piece Details", properties: [
                "Source": "Search Results",
                "Piece ID": results[indexPath.row].objectForKey("id") as! Int,
                "Owner User ID": results[indexPath.row].objectForKey("user_id") as! Int
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
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        var itemHeight:CGFloat!
        var itemWidth:CGFloat!
        
        let result = results[indexPath.row] as NSDictionary
        
        switch currentScope {
        case 0:
            itemHeight = result["height"] as! CGFloat
            itemWidth = result["width"] as! CGFloat
        case 1:
            itemHeight = result["height"] as! CGFloat
            itemWidth = result["height"] as! CGFloat
        default:
            fatalError("Unknown scope in SearchResultsViewController")
        }
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight)
    }
    
    // TransitionProtocol
    func transitionCollectionView() -> UICollectionView!{
        return resultsCollectionView
    }
    
    // CategoryFilterProtocol
    func categorySelected(category: NSDictionary?) {
        if category!["name"] as! String == "All" {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
        
        currentPage = 0
        lastPage = nil
        
        // set category button title
        let categoryName = category!["name"] as! String
        
        filterButtonCategory.setTitle("Category : \(categoryName)", forState: UIControlState.Normal)
        
        retrieveFilteredResults()
    }
    
    func retrieveFilteredResults() {
        var params = NSMutableDictionary()
        
        params.setObject(searchString, forKey: "full_text")
        
        if selectedCategory != nil {
            let selectedCategoryId = selectedCategory!["id"] as! Int
            
            params.setObject(selectedCategoryId, forKey: "category_id")
        }
        
        // REST call to server to refresh the results
        manager.POST(SprubixConfig.URL.api + searchURL,
            parameters: params,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.results = responseObject["data"] as! [NSDictionary]
                self.currentPage = responseObject["current_page"] as? Int
                self.lastPage = responseObject["last_page"] as? Int
                
                self.resultsCollectionView.reloadData()
                
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
        })
    }
    
    func insertMoreResults() {
        if lastPage == nil || currentPage < lastPage {
            var params = NSMutableDictionary()
            
            params.setObject(searchString, forKey: "full_text")
            
            if selectedCategory != nil {
                let selectedCategoryId = selectedCategory!["id"] as! Int
                
                params.setObject(selectedCategoryId, forKey: "category_id")
            }
            
            let nextPage = currentPage! + 1
            
            // REST call to server to refresh the results
            manager.POST(SprubixConfig.URL.api + searchURL + "?page=\(nextPage)",
                parameters: params,
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    var results = responseObject["data"] as! [NSDictionary]
                    
                    self.currentPage = nextPage
                    
                    for result in results {
                        self.results.append(result)
                        
                        self.resultsCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.results.count - 1, inSection: 0)])
                        
                        if self.resultsCollectionView.infiniteScrollingView != nil {
                            self.resultsCollectionView.infiniteScrollingView.stopAnimating()
                        }
                    }
                    
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    if self.resultsCollectionView.infiniteScrollingView != nil {
                        self.resultsCollectionView.infiniteScrollingView.stopAnimating()
                    }
            })
        } else {
            if self.resultsCollectionView.infiniteScrollingView != nil {
                self.resultsCollectionView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    // UISearchBarDelegate
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        self.navigationController?.popViewControllerAnimated(false)
        
        return true
    }
    
    // nav bar callback
    func categoryPressed(sender: UIButton) {
        if itemCategories.count > 0 {
            // display category filter
            let searchResultsFilterViewController = SearchResultsFilterViewController()
            
            searchResultsFilterViewController.categories = itemCategories
            searchResultsFilterViewController.delegate = self
            
            self.navigationController?.presentViewController(searchResultsFilterViewController, animated: true, completion: nil)
        }
    }
    
    func backTapped(sender: UIBarButtonItem) {
        var childrenCount = self.navigationController!.viewControllers.count
        var feedChild: AnyObject = self.navigationController!.viewControllers[childrenCount-3]
        
        UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.popToViewController(feedChild as! UIViewController, animated: false)
            }, completion: nil)
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String = ""
        
        switch currentScope {
        case 0:
            // outfit
            text = "No outfits found"
        case 1:
            // piece
            text = "No items found"
        default:
            fatalError("Unknown scope in SearchResultsViewController")
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
        
        switch currentScope {
        case 0:
            // outfit
            text = "\nSuggestions to find more outfits:\n\n- Check if the spelling is correct\n- Use different keywords\n- Try general keywords"
        case 1:
            // piece
            text = "\nSuggestions to find more items:\n\n- Check if the spelling is correct\n- Use different keywords\n- Try general keywords"
        default:
            fatalError("Unknown scope in SearchResultsViewController")
        }
        
        var paragraph: NSMutableParagraphStyle = NSMutableParagraphStyle.new()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = NSTextAlignment.Left
        
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
        return UIImage(named: "emptyset-search-results")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
}

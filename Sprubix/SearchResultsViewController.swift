//
//  SearchResultsViewController.swift
//  Sprubix
//
//  Created by Shion Wah on 1/9/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import AFNetworking
import ActionSheetPicker_3_0

enum ScopeState {
    case Outfits
    case Pieces
    case People
}

class SearchResultsViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout, TransitionProtocol {
    
    var searchResultsController: UISearchController!
    var piecesTableView: UITableView!
    
    var outfits: [NSDictionary] = [NSDictionary]()
    var pieces: [NSDictionary] = [NSDictionary]()
    var currentPage: Int! = 0
    var lastPage: Int!
    
    // collection view
    var outfitsLayout: SprubixStretchyHeader!
    var outfitsPiecesCollectionView: UICollectionView!
    
    var resultsPieceLayout: SprubixStretchyHeader!
    var resultsOutfitLayout: SprubixStretchyHeader!
    
    // table view
    let resultsPieceCellIdentifier = "ProfilePieceCell"
    
    // search outfits and pieces
    var currentScopeState: ScopeState = ScopeState.Outfits
    var fullTextSearchString: String = ""
    let types: [String] = ["HEAD", "TOP", "BOTTOM", "FEET"]
    
    // filter
    let categoryList: [String] = ["All", "Accessory", "Hat", "Top", "Dress", "Pants", "Skirt", "Shoes"]
    var selectedCategory: String = "All"
    
    // filter buttons
    let searchBarHeight: CGFloat = 65
    let filterButtonHeight: CGFloat = 50
    var filterButtonCategory: UIButton!
    
    var activityView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        if searchResultsController == nil {
            searchResultsController = UISearchController(searchResultsController: nil)
            searchResultsController.dimsBackgroundDuringPresentation = false
            searchResultsController.hidesNavigationBarDuringPresentation = false
            
            searchResultsController.searchBar.barTintColor = sprubixLightGray
            searchResultsController.searchBar.text = fullTextSearchString
            searchResultsController.searchBar.sizeToFit()
        }
        
        //self.definesPresentationContext = true
        
        initSearchFilterButtons()
        initCollectionView()
        search()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        println(self.navigationController?.viewControllers)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !searchResultsController.active {
            self.presentViewController(searchResultsController!, animated: true, completion: nil)
            searchResultsController.resignFirstResponder()
        }
    }
    
    func initSearchFilterButtons() {
        let filterButtonViewY: CGFloat = searchBarHeight
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
        // layout for outfits tab
        resultsOutfitLayout = SprubixStretchyHeader()
        resultsOutfitLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        resultsOutfitLayout.footerHeight = 10
        resultsOutfitLayout.minimumColumnSpacing = 10
        resultsOutfitLayout.minimumInteritemSpacing = 10
        resultsOutfitLayout.columnCount = 2
        
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
        let outfitsPiecesCollectionViewY: CGFloat = searchBarHeight + filterButtonHeight
        outfitsPiecesCollectionView = UICollectionView(frame: CGRectMake(0, outfitsPiecesCollectionViewY, screenWidth, screenHeight - outfitsPiecesCollectionViewY), collectionViewLayout: resultsPieceLayout)
        
        //outfitsPiecesCollectionView.registerClass(ProfileOutfitCell.self, forCellWithReuseIdentifier: resultsOutfitCellIdentifier)
        outfitsPiecesCollectionView.registerClass(ProfilePieceCell.self, forCellWithReuseIdentifier: resultsPieceCellIdentifier)
        
        outfitsPiecesCollectionView.alwaysBounceVertical = true
        outfitsPiecesCollectionView.backgroundColor = sprubixGray
        
        outfitsPiecesCollectionView.dataSource = self
        outfitsPiecesCollectionView.delegate = self
        
        view.addSubview(outfitsPiecesCollectionView)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        let activityViewY: CGFloat = (screenHeight / 2 - activityViewWidth / 2) - outfitsPiecesCollectionViewY
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: activityViewY, width: activityViewWidth, height: activityViewWidth)
        
        outfitsPiecesCollectionView.addSubview(activityView)
    }
    
    func retrieveSearchPieces() {
        
        activityView.startAnimating()
        
        // REST call to server to retrieve search pieces
        manager.POST(SprubixConfig.URL.api + "/pieces/search",
            parameters: [
                "full_text": fullTextSearchString,
                "category": selectedCategory
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
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        switch (currentScopeState) {
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

        
        
        
        
        
        
        cell.setNeedsLayout()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        
        
        
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
                
                //self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
                self.navigationController!.delegate = transitionDelegateHolder
                self.navigationController!.pushViewController(pieceDetailsViewController, animated: true)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
        
        
        

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
        

        
        
        
        let piece = pieces[indexPath.row] as NSDictionary
        itemHeight = piece["height"] as! CGFloat
        itemWidth = piece["height"] as! CGFloat

        
        
        
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight)
    }
    
    // TransitionProtocol
    func transitionCollectionView() -> UICollectionView!{
        return outfitsPiecesCollectionView
    }
    
    // UISearchBarDelegate
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        println(self.navigationController!.viewControllers)
        dismissSearchViewController()
    }
    
    private func dismissSearchViewController() {
        let prevIndex: Int = self.navigationController!.viewControllers.count - 3
        var prevVC = self.navigationController!.viewControllers[prevIndex] as! UIViewController
        println(self.navigationController!.viewControllers)
        
        self.navigationController!.popToViewController(prevVC, animated: true)
    }
    
    func search() {
        println("Result Scope: \(currentScopeState.hashValue) , Text: \(fullTextSearchString)")
        
        if fullTextSearchString != "" {
            switch(currentScopeState) {
            case .Outfits:
                //retrieveSearchOutfits()
                println("ret outfits")
            case .Pieces:
                retrieveSearchPieces()
            case .People:
                //retrieveSearchPeople()
                println("ret people")
            default:
                break
            }
        }
    }
    
    func categoryPressed(sender: UIButton) {
        let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Filter Items", rows: categoryList, initialSelection: 0,
            doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                
                self.selectedCategory = selectedValue as! String
                self.filterButtonCategory.setTitle("Category : \(self.selectedCategory)", forState: UIControlState.Normal)
                self.search()
                
            }, cancelBlock: nil, origin: view)
        
        // custom done button
        let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        doneButton.setTitleTextAttributes([NSForegroundColorAttributeName: sprubixColor], forState: UIControlState.Normal)
        
        picker.setDoneButton(doneButton)
        
        // custom cancel button
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        cancelButton.setTitle("X", forState: UIControlState.Normal)
        cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
        
        picker.showActionSheetPicker()
    }
    
    
}

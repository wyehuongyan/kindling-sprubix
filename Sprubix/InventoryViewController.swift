//
//  InventoryViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 21/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import AFNetworking

enum InventoryState {
    case All
    case LowStock
}

class InventoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UITextFieldDelegate {
    
    var currentInventoryState: InventoryState = .All
    
    // tool bar
    var toolBarView: UIView!
    let searchBarViewHeight: CGFloat = 0 // navigationHeight
    let searchBarTextFieldHeight: CGFloat = 24
    
    var searchBarTextField: UITextField!
    var searchBarPlaceholderText: String = "Search your inventory"
    
    var activityView: UIActivityIndicatorView!
    
    var button1: UIButton! // all
    var button2: UIButton! // low stock
    var buttonLine: UIView!
    var currentChoice: UIButton!
    
    let inventoryCellIdentifier: String = "InventoryCell"
    let inventorySKUCellIdentifier: String = "InventorySKUCell"
    
    // table view
    var pieces: [NSDictionary] = [NSDictionary]()
    @IBOutlet var inventoryTableView: UITableView!
    
    var currentPage: Int = 0
    var lastPage: Int?
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var selectedIndexPath: NSIndexPath!
    var selectedPiece: NSDictionary!
    
    var tableTapGestureRecognizer: UITapGestureRecognizer!
    var makeKeyboardVisible = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        initTableView()
        initToolBar()
        retrieveInventoryPieces()
        
        // shop onboarding
        defaults.setBool(true, forKey: "onboardedInventory")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        makeKeyboardVisible = true
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil)
        
        initNavBar()
        refreshEditedPiece()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        makeKeyboardVisible = false
        self.view.endEditing(true)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        inventoryTableView.addInfiniteScrollingWithActionHandler({
            if self.currentInventoryState == InventoryState.All {
                self.retrieveInventoryPieces()
            }
        })
    }
    
    func initTableView() {
        // get rid of line seperator for empty cells
        inventoryTableView.backgroundColor = sprubixGray
        inventoryTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // empty dataset
        inventoryTableView.emptyDataSetSource = self
        inventoryTableView.emptyDataSetDelegate = self
        
        // gesture recognizer for table view
        tableTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tableTapped:")
        tableTapGestureRecognizer.enabled = false
        self.view.addGestureRecognizer(tableTapGestureRecognizer)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: screenHeight / 3 - activityViewWidth / 2, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Inventory"
        
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
        
        // 5. create a options button
        var optionsButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        optionsButton.setTitle("options", forState: UIControlState.Normal)
        optionsButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        optionsButton.frame = CGRect(x: 0, y: 0, width: 70, height: 20)
        optionsButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        optionsButton.addTarget(self, action: "inventoryOptionsTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var optionsBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: optionsButton)
        newNavItem.rightBarButtonItem = optionsBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initToolBar() {
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
        searchBarTextField.returnKeyType = UIReturnKeyType.Search
        //searchBarTextField.textContainerInset = UIEdgeInsetsMake(3, 3, 0, 0);
        searchBarTextField.delegate = self
        searchBarTextField.textAlignment = NSTextAlignment.Center
        
        searchBarView.addSubview(searchBarTextField)
        
        view.addSubview(searchBarView)
        
        // toolbar items
        let toolbarHeight: CGFloat = 50.0
        var toolBarView = UIView(frame: CGRectMake(0, navigationHeight + searchBarViewHeight, screenWidth, toolbarHeight))
        var buttonWidth = screenWidth / 2
        
        button1 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button1.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: toolbarHeight)
        button1.backgroundColor = UIColor.whiteColor()
        //button1.setImage(UIImage(named: "profile-myoutfits"), forState: UIControlState.Normal)
        button1.setTitle("All", forState: UIControlState.Normal)
        button1.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button1.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //button1.setImage(UIImage(named: "profile-myoutfits"), forState: UIControlState.Selected)
        button1.tintColor = UIColor.lightGrayColor()
        button1.autoresizesSubviews = true
        button1.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button1.exclusiveTouch = true
        button1.addTarget(self, action: "allPiecesPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        button2 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button2.frame = CGRect(x: buttonWidth, y: 0, width: buttonWidth, height: toolbarHeight)
        button2.backgroundColor = UIColor.whiteColor()
        //button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Normal)
        button2.setTitle("Low Stock", forState: UIControlState.Normal)
        button2.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button2.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Selected)
        button2.tintColor = UIColor.lightGrayColor()
        button2.autoresizesSubviews = true
        button2.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button2.exclusiveTouch = true
        button2.addTarget(self, action: "lowStockPiecesPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        toolBarView.addSubview(button1)
        toolBarView.addSubview(button2)
        
        // set when button is selected
        buttonLine = UIView(frame: CGRect(x: 0, y: button1.frame.height - 2.0, width: button1.frame.width, height: 2))
        buttonLine.backgroundColor = sprubixColor
        
        // button 1 is initially selected
        button1.addSubview(buttonLine)
        button1.tintColor = sprubixColor
        
        view.addSubview(toolBarView)
    }
    
    func refreshEditedPiece() {
        if selectedPiece != nil {
            manager.POST(SprubixConfig.URL.api + "/pieces",
                parameters: [
                    "id": selectedPiece["id"] as! Int
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var updatedPiece = (responseObject["data"] as! [NSDictionary]).first
                    
                    if updatedPiece != nil {
                        self.pieces.insert(updatedPiece!, atIndex: self.selectedIndexPath.row)
                        self.pieces.removeAtIndex(self.selectedIndexPath.row + 1)
                        
                        self.inventoryTableView.reloadRowsAtIndexPaths([self.selectedIndexPath], withRowAnimation: UITableViewRowAnimation.None)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            inventoryTableView.reloadData()
        }
    }
    
    func retrieveInventoryPieces() {
        let nextPage = currentPage + 1
        
        if nextPage <= lastPage || lastPage == nil {
            let userId:Int? = defaults.objectForKey("userId") as? Int
            
            if userId != nil {
                
                if lastPage == nil {
                    activityView.startAnimating()
                }
                
                manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/pieces?page=\(nextPage)",
                    parameters: nil,
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        if self.currentInventoryState == InventoryState.All {
                            
                            self.activityView.stopAnimating()
                            self.currentPage = responseObject["current_page"] as! Int
                            self.lastPage = responseObject["last_page"] as? Int
                            
                            let pieces = responseObject["data"] as! [NSDictionary]
                            
                            if self.pieces.count > 0 {
                                for piece in pieces {
                                    self.pieces.append(piece)
                                    
                                    self.inventoryTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.pieces.count - 1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                                }
                            } else {
                                self.pieces = pieces
                                self.inventoryTableView.reloadData()
                            }
                            
                            if self.inventoryTableView.infiniteScrollingView != nil {
                                self.inventoryTableView.infiniteScrollingView.stopAnimating()
                            }
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        self.activityView.stopAnimating()
                        
                        if self.inventoryTableView.infiniteScrollingView != nil {
                            self.inventoryTableView.infiniteScrollingView.stopAnimating()
                        }
                })
            } else {
                println("userId not found, please login or create an account")
                
                if self.inventoryTableView.infiniteScrollingView != nil {
                    self.inventoryTableView.infiniteScrollingView.stopAnimating()
                }
            }
        } else {
            if self.inventoryTableView.infiniteScrollingView != nil {
                self.inventoryTableView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    func retrieveLowInventoryPieces() {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            activityView.startAnimating()
            
            manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/low/pieces",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    // if inventory state still = .LowStock
                    if self.currentInventoryState == InventoryState.LowStock {
                        self.activityView.stopAnimating()
                        self.pieces = responseObject as! [NSDictionary]
                        
                        if self.pieces.count > 0 {
                            self.inventoryTableView.reloadData()
                        } else {
                            println("There are currently no pieces in low stock.")
                        }
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    self.activityView.stopAnimating()
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "\nItems you're selling"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "When you put an item up for sale, you'll see it here."
        
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
        return UIImage(named: "emptyset-inventory-instock")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pieces.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch currentInventoryState {
        case .All:
            var cell: UITableViewCell!
            
            let piece = pieces[indexPath.row] as NSDictionary
            var piecePrice = piece["price"] as! String
            var pieceSKU = piece["sku"] as? String
            
            if pieceSKU != nil && pieceSKU != "" {
                cell = tableView.dequeueReusableCellWithIdentifier(inventorySKUCellIdentifier, forIndexPath: indexPath) as! InventorySKUCell
                
                if !piece["quantity"]!.isKindOfClass(NSNull) {
                    var pieceQuantityString = piece["quantity"] as! String
                    var pieceQuantityData:NSData = pieceQuantityString.dataUsingEncoding(NSUTF8StringEncoding)!
                    
                    var pieceQuantityDict = NSJSONSerialization.JSONObjectWithData(pieceQuantityData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                    
                    // get low stock limit
                    let userData: NSDictionary! = defaults.dictionaryForKey("userData")
                    let shoppable = userData["shoppable"] as! NSDictionary
                    let lowStockLimit = shoppable["low_stock_limit"] as! Int
                    
                    var total = 0
                    var lowSizes = NSMutableArray()
                    
                    for (size, pieceQuantity) in pieceQuantityDict {
                        var stock = (pieceQuantity as! String).toInt()!
                        total += stock
                        
                        // check if there's low stock for size here
                        if stock <= lowStockLimit {
                            lowSizes.addObject(size)
                        }
                    }
                    
                    if lowSizes.count > 0 {
                        let lowSizesText = lowSizes.componentsJoinedByString(", ")
                        
                        (cell as! InventorySKUCell).inventoryQuantity.text = "Low: \(lowSizesText)"
                        (cell as! InventorySKUCell).inventoryQuantity.textColor = UIColor.redColor()
                        (cell as! InventorySKUCell).backgroundColor = sprubixYellow
                    } else {
                        (cell as! InventorySKUCell).inventoryQuantity.text = "\(total) left in stock"
                        (cell as! InventorySKUCell).inventoryQuantity.textColor = UIColor.darkGrayColor()
                        (cell as! InventorySKUCell).backgroundColor = UIColor.whiteColor()
                    }
                }
                
                (cell as! InventorySKUCell).inventoryName.text = piece["name"] as? String
                (cell as! InventorySKUCell).inventoryPrice.text = "$\(piecePrice)"
                (cell as! InventorySKUCell).SKU.text = "SKU: \(pieceSKU!)"
                
                let pieceImagesString = piece["images"] as! NSString
                let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                let imageURL = NSURL(string: pieceImagesDict["cover"] as! String)
                
                (cell as! InventorySKUCell).inventoryImage.image = nil
                (cell as! InventorySKUCell).inventoryImage.setImageWithURL(imageURL)
                
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier(inventoryCellIdentifier, forIndexPath: indexPath) as! InventoryCell
            
                
                if !piece["quantity"]!.isKindOfClass(NSNull) {
                    var pieceQuantityString = piece["quantity"] as! String
                    var pieceQuantityData:NSData = pieceQuantityString.dataUsingEncoding(NSUTF8StringEncoding)!
                    
                    var pieceQuantityDict = NSJSONSerialization.JSONObjectWithData(pieceQuantityData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                    
                    // get low stock limit
                    let userData: NSDictionary! = defaults.dictionaryForKey("userData")
                    let shoppable = userData["shoppable"] as! NSDictionary
                    let lowStockLimit = shoppable["low_stock_limit"] as! Int
                    
                    var total = 0
                    var lowSizes = NSMutableArray()
                    
                    for (size, pieceQuantity) in pieceQuantityDict {
                        var stock = (pieceQuantity as! String).toInt()!
                        total += stock
                        
                        // check if there's low stock for size here
                        if stock <= lowStockLimit {
                            lowSizes.addObject(size)
                        }
                    }
                    
                    if lowSizes.count > 0 {
                        let lowSizesText = lowSizes.componentsJoinedByString(", ")
                        
                        (cell as! InventoryCell).inventoryQuantity.text = "Low: \(lowSizesText)"
                        (cell as! InventoryCell).inventoryQuantity.textColor = UIColor.redColor()
                        (cell as! InventoryCell).backgroundColor = sprubixYellow
                    } else {
                        (cell as! InventoryCell).inventoryQuantity.text = "\(total) left in stock"
                        (cell as! InventoryCell).inventoryQuantity.textColor = UIColor.darkGrayColor()
                        (cell as! InventoryCell).backgroundColor = UIColor.whiteColor()
                    }
                }
                
                (cell as! InventoryCell).inventoryName.text = piece["name"] as? String
                (cell as! InventoryCell).inventoryPrice.text = "$\(piecePrice)"
                
                let pieceImagesString = piece["images"] as! NSString
                let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                let imageURL = NSURL(string: pieceImagesDict["cover"] as! String)
                
                (cell as! InventoryCell).inventoryImage.image = nil
                (cell as! InventoryCell).inventoryImage.setImageWithURL(imageURL)
            }
                
            return cell
        case .LowStock:
            let cell = tableView.dequeueReusableCellWithIdentifier(inventoryCellIdentifier, forIndexPath: indexPath) as! InventoryCell
            
            let piece = pieces[indexPath.row] as NSDictionary
            var piecePrice = piece["price"] as! String
            
            if !piece["quantity"]!.isKindOfClass(NSNull) {
                var pieceQuantityString = piece["quantity"] as! String
                var pieceQuantityData:NSData = pieceQuantityString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var pieceQuantityDict = NSJSONSerialization.JSONObjectWithData(pieceQuantityData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                // get low stock limit
                let userData: NSDictionary! = defaults.dictionaryForKey("userData")
                let shoppable = userData["shoppable"] as! NSDictionary
                let lowStockLimit = shoppable["low_stock_limit"] as! Int
                
                var total = 0
                var lowSizes = NSMutableArray()
                
                for (size, pieceQuantity) in pieceQuantityDict {
                    var stock = (pieceQuantity as! String).toInt()!
                    total += stock
                    
                    // check if there's low stock for size here
                    if stock <= lowStockLimit {
                        lowSizes.addObject(size)
                    }
                }
                
                let lowSizesText = lowSizes.componentsJoinedByString(", ")
                
                cell.inventoryQuantity.text = "Low: \(lowSizesText)"
                cell.inventoryQuantity.textColor = UIColor.redColor()
                cell.backgroundColor = sprubixYellow
            }
            
            cell.inventoryName.text = piece["name"] as? String
            cell.inventoryPrice.text = "$\(piecePrice)"
            
            let pieceImagesString = piece["images"] as! NSString
            let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
            let imageURL = NSURL(string: pieceImagesDict["cover"] as! String)
            
            cell.inventoryImage.setImageWithURL(imageURL)
            
            return cell
        default:
            fatalError("Unknown inventory state in InventoryViewController")
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if textField.text != "" && userId != nil {
            // REST call to server to do full text search
            manager.POST(SprubixConfig.URL.api + "/pieces",
                parameters: [
                    "user_id": userId!,
                    "full_text": textField.text
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    self.pieces = responseObject["data"] as! [NSDictionary]
                    
                    self.inventoryTableView.reloadData()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
        
        return true
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let piece = pieces[indexPath.row] as NSDictionary
        var pieceSKU = piece["sku"] as? String
        
        if pieceSKU != nil && pieceSKU != "" {
            return 128.0
        } else {
            return 100.0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let snapshotDetailsController = SnapshotDetailsController()
        
        let piece = pieces[indexPath.row] as NSDictionary
        let sprubixPiece = SprubixPiece()
        selectedPiece = piece
        selectedIndexPath = indexPath
        
        // get images
        var pieceImagesString = piece["images"] as! String
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        var pieceImageURL = NSURL(string: pieceImagesDict["cover"] as! String)
        
        snapshotDetailsController.itemCoverImageView.setImageWithURL(pieceImageURL)
        
        let pieceImagesArray = pieceImagesDict["images"] as! NSArray
        
        for var i = 0; i < pieceImagesArray.count ; i++ {
            var imageDict = pieceImagesArray[i] as! NSDictionary
            let imageURL = NSURL(string: imageDict["original"] as! String)
            
            sprubixPiece.imageURLs.append(imageURL!)
        }
        
        // init sprubix piece
        let pieceId = piece["id"] as? Int
        sprubixPiece.id = pieceId // important, this is an existing piece
        sprubixPiece.name = piece["name"] as? String
        
        let pieceCategory = piece["category"] as? NSDictionary
        sprubixPiece.category = pieceCategory?["name"] as? String
        
        let pieceBrand = piece["brand"] as? NSDictionary
        sprubixPiece.brand = pieceBrand?["name"] as? String
    
        sprubixPiece.size = piece["size"] as? String
        
        if !piece["quantity"]!.isKindOfClass(NSNull) {
            var pieceQuantityString = piece["quantity"] as! String
            var pieceQuantityData:NSData = pieceQuantityString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceQuantityDict = NSJSONSerialization.JSONObjectWithData(pieceQuantityData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
            sprubixPiece.quantity = pieceQuantityDict
        }
        
        sprubixPiece.price = piece["price"] as? String
        sprubixPiece.sku = piece["sku"] as? String
        sprubixPiece.desc = piece["description"] as? String
        sprubixPiece.isDress = piece["is_dress"] as! Bool
        sprubixPiece.type = piece["type"] as? String
        
        snapshotDetailsController.sprubixPiece = sprubixPiece
        snapshotDetailsController.fromInventoryView = true
        
        self.navigationController?.pushViewController(snapshotDetailsController, animated: true)
    }
    
    // tool bar button callbacks
    func allPiecesPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            currentInventoryState = .All
            currentPage = 0
            lastPage = nil
            
            // empty pieces
            pieces.removeAll()
            inventoryTableView.reloadData()
            
            retrieveInventoryPieces()
            
            // Mixpanel - Viewed Inventory, All
            mixpanel.track("Viewed Inventory", properties: [
                "Source": "Inventory View",
                "Tab": "All"
            ])
            // Mixpanel - End
        }
    }
    
    func lowStockPiecesPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            currentInventoryState = .LowStock
            
            // empty pieces
            pieces.removeAll()
            inventoryTableView.reloadData()
            
            retrieveLowInventoryPieces()
            
            // Mixpanel - Viewed Inventory, Low Stock
            mixpanel.track("Viewed Inventory", properties: [
                "Source": "Inventory View",
                "Tab": "Low Stock"
            ])
            // Mixpanel - End
        }
    }
    
    private func deselectAllButtons() {
        buttonLine.removeFromSuperview()
        
        button1.tintColor = UIColor.lightGrayColor()
        button2.tintColor = UIColor.lightGrayColor()
    }
    
    func keyboardWillChange(notification: NSNotification) {
        if makeKeyboardVisible {
            tableTapGestureRecognizer.enabled = true
        } else {
            tableTapGestureRecognizer.enabled = false
            self.makeKeyboardVisible = true
        }
    }
    
    func tableTapped(gesture: UITapGestureRecognizer) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func inventoryOptionsTapped(sender: UIBarButtonItem) {
        // reset selected piece
        selectedPiece = nil
        
        let inventoryOptionsViewController = InventoryOptionsViewController()
        
        self.navigationController?.pushViewController(inventoryOptionsViewController, animated: true)
    }
}
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

class InventoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // tool bar
    @IBOutlet var toolBarView: UIView!
    var button1: UIButton! // all
    var button2: UIButton! // low stock
    var buttonLine: UIView!
    var currentChoice: UIButton!
    
    // table view
    var pieces: [NSDictionary] = [NSDictionary]()
    let inventoryCellIdentifier: String = "InventoryCell"
    @IBOutlet var inventoryTableView: UITableView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var selectedIndexPath: NSIndexPath!
    var selectedPiece: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // get rid of line seperator for empty cells
        inventoryTableView.backgroundColor = sprubixGray
        inventoryTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // empty dataset
        inventoryTableView.emptyDataSetSource = self
        inventoryTableView.emptyDataSetDelegate = self
        
        initToolBar()
        retrieveInventoryPieces()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        refreshEditedPiece()
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
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initToolBar() {
        // toolbar items
        let toolbarHeight = toolBarView.frame.size.height
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
        }
    }
    
    func retrieveInventoryPieces() {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/pieces",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    self.pieces = responseObject["data"] as! [NSDictionary]
                    
                    if self.pieces.count > 0 {
                        self.inventoryTableView.reloadData()
                    } else {
                        println("Oops, there are no pieces in your closet.")
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "Title For Empty Data Set"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        
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
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let text: String = "Button Title"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0)
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "main-like-filled-large")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pieces.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(inventoryCellIdentifier, forIndexPath: indexPath) as! InventoryCell
        
        let piece = pieces[indexPath.row] as NSDictionary
        var piecePrice = piece["price"] as! String
        var pieceQuantity = piece["quantity"] as! Int
        
        cell.inventoryName.text = piece["name"] as? String
        cell.inventoryPrice.text = "$\(piecePrice)"
        cell.inventoryQuantity.text = "\(pieceQuantity) left in stock"
        
        let pieceImagesString = piece["images"] as! NSString
        let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        let imageURL = NSURL(string: pieceImagesDict["cover"] as! String)
        
        cell.inventoryImage.setImageWithURL(imageURL)
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
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
        sprubixPiece.quantity = piece["quantity"] as? Int
        sprubixPiece.price = piece["price"] as? String
        sprubixPiece.desc = piece["description"] as? String
        sprubixPiece.isDress = piece["is_dress"] as? Bool
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
        }
    }
    
    func lowStockPiecesPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
        }
    }
    
    private func deselectAllButtons() {
        buttonLine.removeFromSuperview()
        
        button1.tintColor = UIColor.lightGrayColor()
        button2.tintColor = UIColor.lightGrayColor()
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}
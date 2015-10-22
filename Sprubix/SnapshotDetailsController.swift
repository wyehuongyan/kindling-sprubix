//
//  SnapshotDetailsController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import MRProgress
import PermissionScope
import ActionSheetPicker_3_0
import MLPAutoCompleteTextField
import TSMessages

class SprubixItemThumbnail: UIButton {
    var hasThumbnail: Bool = false
    var imageURL: NSURL!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, thumbnail: String = "icon-placeholder.png") {
        self.init()
        
        self.setImage(UIImage(named: thumbnail), forState: UIControlState.Normal)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol SprubixPieceProtocol {
    func setSprubixPiece(sprubixPiece: SprubixPiece, position: Int)
}

class SnapshotDetailsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SnapshotDetailsProtocol, AddMoreSizesProtocol {
    
    var delegate: SprubixPieceProtocol?
    var pos: Int!
    var sprubixPiece: SprubixPiece!
    
    // entered with only one piece
    var onlyOnePiece: Bool = false
    var addToClosetButton: UIButton?
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    // item
    var itemCoverImageView: UIImageView = UIImageView()
    var itemCategories: [String] = [String]()
    
    // tableview cells
    var itemTableView: UITableView!
    var itemImageCell: UITableViewCell = UITableViewCell()
    var itemThumbnailsCell: UITableViewCell = UITableViewCell()
    var itemDetailsCell: UITableViewCell = UITableViewCell()
    var itemDescriptionCell: UITableViewCell = UITableViewCell()
    
    // description
    let itemSpecHeight: CGFloat = 55
    let descriptionTextHeight: CGFloat = 100
    var descriptionText: UITextView!
    var placeholderText: String = "Tell us more about this item!"
    var makeKeyboardVisible = true
    var oldFrameRect: CGRect!
    
    // thumbnails
    var thumbnails: [SprubixItemThumbnail] = [SprubixItemThumbnail]()
    let thumbnailViewWidth: CGFloat = (screenWidth - 100) / 4
    var selectedThumbnail: SprubixItemThumbnail!
    
    // itemDetails textfields
    var pieceSpecsView: UIView!
    var itemDetailsName: UITextField!
    var itemDetailsCategoryButton: UIButton!
    var itemDetailsCategory: UITextField!
    var itemDetailsBrand: MLPAutoCompleteTextField!
    var itemDetailsSize: UITextField!
    var itemDetailsSizeButton: UIButton!
    var itemDetailsQuantity: UITextField!
    var itemDetailsPrice: UITextField!
    var itemDetailsPriceNumber: CGFloat = 0.00
    var itemDetailsSKU: UITextField!
    var itemIsDress: Bool = false
    var itemSpecHeightTotal: CGFloat = 220
    
    var pieceSizesArray: NSArray!
    var pieceQuantityDict: NSMutableDictionary = NSMutableDictionary()
    
    // to be pushed downwards when quantity increases in rows
    var itemPriceImage: UIButton!
    var itemSKUImage: UIButton!
    var moreQuantityTextFields: [UITextField] = [UITextField]()
    
    var isShop: Bool = false
    var snapshotDetailsSizeController: SnapshotDetailsSizeController?
    
    // trash button
    var trashButton: UIButton!
    
    // entered from inventory
    var fromInventoryView: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            isShop = false
        } else {
            // shop
            isShop = true
        }
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        // table
        itemTableView = UITableView(frame: CGRectMake(0, navigationHeight, screenWidth, screenHeight - navigationHeight))
        itemTableView.delegate = self
        itemTableView.dataSource = self
        itemTableView.showsVerticalScrollIndicator = false
        itemTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        itemTableView.userInteractionEnabled = true
        
        // register method when tapped to hide keyboard
        let tableTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tableTapped:")
        self.view.addGestureRecognizer(tableTapGestureRecognizer)
        
        self.view.addSubview(itemTableView)
        
        oldFrameRect = itemTableView.frame
        
        if onlyOnePiece {
            addToClosetButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
            addToClosetButton!.backgroundColor = sprubixColor
            addToClosetButton!.titleLabel?.font = UIFont.boldSystemFontOfSize(18.0)
            addToClosetButton!.setTitle("Add to Closet!", forState: UIControlState.Normal)
            addToClosetButton!.addTarget(self, action: "addToClosetPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            self.view.addSubview(addToClosetButton!)
        }
        
        retrieveItemCategories()
    }
    
    private func retrieveItemCategories() {
        if itemCategories.count <= 0 {
            // REST call to retrieve piece categories
            manager.GET(SprubixConfig.URL.api + "/piece/categories?piece_type=\(sprubixPiece.type)",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    var categories = responseObject as? [NSDictionary]
                    
                    if categories != nil {
                        for category in categories! {
                            var categoryName = category["name"] as? String
                            
                            self.itemCategories.append(categoryName!)
                        }
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil)
        
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Item Details"
        
        // 4. create a cancel button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        backButton.setTitle("cancel", forState: UIControlState.Normal)
        backButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.addTarget(self, action: "cancelTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        if onlyOnePiece != true {
            // 5. create a done buton
            var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            nextButton.setTitle("save", forState: UIControlState.Normal)
            nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
            nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
            nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            nextButton.addTarget(self, action: "doneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            
            var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
            newNavItem.rightBarButtonItem = nextBarButtonItem
        }
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
        
        // reset keyboard
        //makeKeyboardVisible = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        makeKeyboardVisible = false
        self.view.endEditing(true)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    // SnapshotDetailsProtocol
    func setPreviewStillImage(image: UIImage?, fromPhotoLibrary: Bool) {
        if image != nil {
            self.selectedThumbnail.setImage(image, forState: UIControlState.Normal)
            self.selectedThumbnail.hasThumbnail = true
            self.itemCoverImageView.image = image
            self.itemCoverImageView.alpha = 1.0
            
            self.itemTableView.scrollEnabled = true
            self.pieceSpecsView.alpha = 1.0
            self.itemDescriptionCell.alpha = 1.0
            self.addToClosetButton?.alpha = 1.0
            
            self.newNavBar.setItems([self.newNavItem], animated: true)
        } else {
            NSLog("Uh oh! Something went wrong. Try it again.")
        }
    }
    
    // tableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight : CGFloat!
        
        switch(indexPath.row)
        {
        case 0:
            cellHeight = screenWidth
        case 1:
            cellHeight = thumbnailViewWidth + 20 // itemThumbnails
        case 2:
            cellHeight = itemSpecHeightTotal + 10 // itemDetails
        case 3:
            cellHeight = descriptionTextHeight // description
        default:
            cellHeight = 300
        }
        
        return cellHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch(indexPath.row)
        {
        case 0:
            itemCoverImageView.frame = CGRectMake(0, 0, screenWidth, screenWidth)
            itemCoverImageView.contentMode = UIViewContentMode.ScaleAspectFit
            itemCoverImageView.backgroundColor = sprubixGray
            itemCoverImageView.userInteractionEnabled = true
            
            itemImageCell.addSubview(itemCoverImageView)
            itemImageCell.backgroundColor = sprubixGray
            
            if trashButton == nil {
                // trash button
                let trashButtonWidth = screenWidth / 10
                trashButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                var image = UIImage(named: "details-thumbnail-trash")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                trashButton.setImage(image, forState: UIControlState.Normal)
                trashButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                trashButton.imageView?.tintColor = sprubixGray
                trashButton.backgroundColor = UIColor.clearColor()
                trashButton.frame = CGRectMake(9 * trashButtonWidth, screenWidth - trashButtonWidth, trashButtonWidth, trashButtonWidth)
                trashButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
                trashButton.addTarget(self, action: "deleteImage:", forControlEvents: UIControlEvents.TouchUpInside)
                trashButton.exclusiveTouch = true
                Glow.addGlow(trashButton)
                
                itemCoverImageView.addSubview(trashButton)
            }
            
            return itemImageCell
            
        case 1:
            
            for var i = 0; i < 4; i++ {
                var thumbnailView: SprubixItemThumbnail = SprubixItemThumbnail.buttonWithType(UIButtonType.Custom) as! SprubixItemThumbnail
                
                if i == 0 {
                    // first one
                    thumbnailView.setImage(itemCoverImageView.image, forState: UIControlState.Normal)
                    thumbnailView.hasThumbnail = true
                    selectedThumbnail = thumbnailView
                } else {
                    // coming from inventory
                    if sprubixPiece.imageURLs.count > i {
                        thumbnailView.setImage(UIImage(data: NSData(contentsOfURL: sprubixPiece.imageURLs[i])!), forState: UIControlState.Normal)
                        
                        thumbnailView.hasThumbnail = true
                        
                    } else {
                        thumbnailView.setImage(UIImage(named: "details-thumbnail-add"), forState: UIControlState.Normal)
                    }
                    
                    // coming from create outfit
                    if sprubixPiece.images.count > i {
                        thumbnailView.setImage(sprubixPiece.images[i], forState: UIControlState.Normal)
                        
                        thumbnailView.hasThumbnail = true
                    } else {
                        thumbnailView.setImage(UIImage(named: "details-thumbnail-add"), forState: UIControlState.Normal)
                    }
                }
                
                // tap gesture recognizer
                var singleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
                singleTapGestureRecognizer.numberOfTapsRequired = 1
                
                thumbnailView.addGestureRecognizer(singleTapGestureRecognizer)
                
                thumbnailView.frame = CGRectMake(20 + CGFloat(i) * (thumbnailViewWidth + 20), 20, thumbnailViewWidth, thumbnailViewWidth)

                thumbnailView.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                thumbnailView.backgroundColor = sprubixGray
                
                thumbnails.append(thumbnailView)
                
                itemThumbnailsCell.addSubview(thumbnailView)
            }
            
            itemThumbnailsCell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return itemThumbnailsCell
            
        case 2:
            // init piece specifications
            itemSpecHeightTotal = isShop != true ? itemSpecHeight * 4 : itemSpecHeight * 7
            
            pieceSpecsView = UIView(frame: CGRect(x: 0, y: 10, width: screenWidth, height: itemSpecHeightTotal))
            pieceSpecsView.backgroundColor = UIColor.whiteColor()
            
            // generate 4 labels with icons
            let itemImageViewWidth:CGFloat = 0.3 * screenWidth
            
            // name
            var itemNameImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemNameImage.setImage(UIImage(named: "view-item-name"), forState: UIControlState.Normal)
            itemNameImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemNameImage.frame = CGRect(x: 0, y: 0, width: itemImageViewWidth, height: itemSpecHeight)
            itemNameImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemNameImage)
            
            itemDetailsName = UITextField(frame: CGRectMake(itemImageViewWidth, 0, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsName.tintColor = sprubixColor
            itemDetailsName.placeholder = "Name of your item?"
            itemDetailsName.returnKeyType = UIReturnKeyType.Done
            itemDetailsName.delegate = self

            if sprubixPiece.name != nil {
                itemDetailsName.text = sprubixPiece.name
            }
            
            // category
            var itemCategoryImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemCategoryImage.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
            itemCategoryImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemCategoryImage.frame = CGRect(x: 0, y: itemSpecHeight, width: itemImageViewWidth, height: itemSpecHeight)
            itemCategoryImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemCategoryImage)
            
            itemDetailsCategoryButton = UIButton(frame: CGRectMake(itemImageViewWidth, itemSpecHeight, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsCategory = UITextField(frame: CGRectMake(0, 0, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsCategory.tintColor = sprubixColor
            itemDetailsCategory.placeholder = "Which category is it from?"
            itemDetailsCategory.enabled = false
            itemDetailsCategoryButton.addSubview(itemDetailsCategory)
            itemDetailsCategoryButton.addTarget(self, action: "itemDetailsCategoryPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            if sprubixPiece.category != nil {
                
                itemDetailsCategory.text = sprubixPiece.category

                if sprubixPiece.type.lowercaseString == "top" {
                    if itemIsDress {
                        // already set as dress when entering
                        itemDetailsCategory.text = "Dress"
                    } else {
                        itemDetailsCategory.text = "Top"
                    }
                    
                    // disable the category selection
                    itemDetailsCategoryButton.enabled = false
                }
                
            }
            
            // brand
            var itemBrandImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemBrandImage.setImage(UIImage(named: "view-item-brand"), forState: UIControlState.Normal)
            itemBrandImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemBrandImage.frame = CGRect(x: 0, y: itemSpecHeight * 2, width: itemImageViewWidth, height: itemSpecHeight)
            itemBrandImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemBrandImage)
            
            itemDetailsBrand = MLPAutoCompleteTextField(frame: CGRectMake(itemImageViewWidth, itemSpecHeight * 2, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsBrand.tintColor = sprubixColor
            itemDetailsBrand.placeholder = "What brand is it?"
            itemDetailsBrand.returnKeyType = UIReturnKeyType.Done
            itemDetailsBrand.delegate = self
            
            // autocomplete
            itemDetailsBrand.autoCompleteDataSource = self
            itemDetailsBrand.autoCompleteTableAppearsAsKeyboardAccessory = true
            itemDetailsBrand.autoCompleteDelegate = self
            itemDetailsBrand.autoCompleteTableCellTextColor = sprubixColor
            itemDetailsBrand.autoCompleteTableBorderColor = sprubixLightGray
            
            if sprubixPiece.brand != nil {
                itemDetailsBrand.text = sprubixPiece.brand
            }
            
            // size
            var itemSizeImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemSizeImage.setImage(UIImage(named: "view-item-size"), forState: UIControlState.Normal)
            itemSizeImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemSizeImage.frame = CGRect(x: 0, y: itemSpecHeight * 3, width: itemImageViewWidth, height: itemSpecHeight)
            itemSizeImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemSizeImage)
            
            itemDetailsSizeButton = UIButton(frame: CGRectMake(itemImageViewWidth, itemSpecHeight * 3, screenWidth - itemImageViewWidth - 20, itemSpecHeight))
            itemDetailsSize = UITextField(frame: CGRectMake(0, 0, screenWidth - itemImageViewWidth - 20, itemSpecHeight))
            itemDetailsSize.tintColor = sprubixColor
            itemDetailsSize.placeholder = "What size is it?"
            itemDetailsSize.enabled = false
            itemDetailsSizeButton.addSubview(itemDetailsSize)
            itemDetailsSizeButton.addTarget(self, action: "addMoreSizesPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            if sprubixPiece.size != nil {
                var pieceSizesString = sprubixPiece.size
                var pieceSizesData:NSData = pieceSizesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                pieceSizesArray = NSJSONSerialization.JSONObjectWithData(pieceSizesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSArray
                
                if pieceSizesArray != nil {
                    itemDetailsSize.text = pieceSizesArray.componentsJoinedByString("/")
                } else {
                    // pieceSizesString is not a json string
                    // split it the usual way
                    pieceSizesArray = split(pieceSizesString) {$0 == "/"}
                    
                    itemDetailsSize.text = pieceSizesString
                }
            }
            
            // add more sizes
            let addMoreSizesWidth: CGFloat = 25
            var addMoreSizes = UIButton(frame: CGRectMake(0, -1, addMoreSizesWidth, addMoreSizesWidth))
            addMoreSizes.setImage(UIImage(named: "main-cta-add"), forState: UIControlState.Normal)
            addMoreSizes.addTarget(self, action: "addMoreSizesPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            addMoreSizes.imageView?.layer.cornerRadius = addMoreSizes.imageView!.frame.height / 2
            addMoreSizes.imageView?.layer.borderColor = sprubixLightGray.CGColor
            addMoreSizes.imageView?.layer.borderWidth = 2.0
            addMoreSizes.clipsToBounds = true
            
            var offsetView: UIView = UIView(frame: addMoreSizes.bounds)
            offsetView.addSubview(addMoreSizes)
            
            itemDetailsSize.rightView = offsetView
            itemDetailsSize.rightViewMode = UITextFieldViewMode.Always
            
            pieceSpecsView.addSubview(itemDetailsSizeButton)
            
            if isShop {
                // quantity
                var itemQuantityImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                itemQuantityImage.setImage(UIImage(named: "view-item-quantity"), forState: UIControlState.Normal)
                itemQuantityImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                itemQuantityImage.frame = CGRect(x: 0, y: itemSpecHeight * 4, width: itemImageViewWidth, height: itemSpecHeight)
                itemQuantityImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
                
                Glow.addGlow(itemQuantityImage)
                
                itemDetailsQuantity = UITextField(frame: CGRectMake(itemImageViewWidth, itemSpecHeight * 4, screenWidth - itemImageViewWidth, itemSpecHeight))
                itemDetailsQuantity.tintColor = sprubixColor
                itemDetailsQuantity.placeholder = "How much quantity?"
                itemDetailsQuantity.keyboardType = UIKeyboardType.NumberPad
                itemDetailsQuantity.returnKeyType = UIReturnKeyType.Done
                itemDetailsQuantity.delegate = self
                
                if sprubixPiece.quantity != nil {
                    if pieceSizesArray != nil && pieceSizesArray.count > 0 {
                        var itemQuantity = sprubixPiece.quantity[pieceSizesArray[0] as! String] as! String
                        
                        itemDetailsQuantity.text = "\(itemQuantity)"
                        
                        pieceQuantityDict.removeAllObjects()
                        pieceQuantityDict.setObject(itemDetailsQuantity.text, forKey: pieceSizesArray[0] as! String)
                    }
                }
                
                // price
                itemPriceImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                itemPriceImage.setImage(UIImage(named: "view-item-price"), forState: UIControlState.Normal)
                itemPriceImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                itemPriceImage.frame = CGRect(x: 0, y: itemSpecHeight * 5, width: itemImageViewWidth, height: itemSpecHeight)
                itemPriceImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
                
                Glow.addGlow(itemPriceImage)
                
                itemDetailsPrice = UITextField(frame: CGRectMake(itemImageViewWidth, itemSpecHeight * 5, screenWidth - itemImageViewWidth, itemSpecHeight))
                itemDetailsPrice.tintColor = sprubixColor
                itemDetailsPrice.placeholder = "How much does it cost?"
                itemDetailsPrice.keyboardType = UIKeyboardType.DecimalPad
                itemDetailsPrice.returnKeyType = UIReturnKeyType.Done
                itemDetailsPrice.delegate = self
                
                if sprubixPiece.price != nil {
                    itemDetailsPrice.text = sprubixPiece.price
                    
                    var dollarLabel: UILabel = UILabel(frame: CGRectMake(0, 0, 10, itemDetailsPrice.frame.height))
                    dollarLabel.text = "$"
                    dollarLabel.textColor = UIColor.lightGrayColor()
                    dollarLabel.textAlignment = NSTextAlignment.Left
                    
                    var offsetView: UIView = UIView(frame: dollarLabel.bounds)
                    offsetView.addSubview(dollarLabel)
                    
                    itemDetailsPrice.leftView = offsetView
                    itemDetailsPrice.leftViewMode = UITextFieldViewMode.Always
                }
                
                // sku
                itemSKUImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                itemSKUImage.setImage(UIImage(named: "view-item-sku"), forState: UIControlState.Normal)
                itemSKUImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                itemSKUImage.frame = CGRect(x: 0, y: itemSpecHeight * 6, width: itemImageViewWidth, height: itemSpecHeight)
                itemSKUImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
                
                Glow.addGlow(itemSKUImage)
                
                itemDetailsSKU = UITextField(frame: CGRectMake(itemImageViewWidth, itemSpecHeight * 6, screenWidth - itemImageViewWidth, itemSpecHeight))
                itemDetailsSKU.tintColor = sprubixColor
                itemDetailsSKU.placeholder = "SKU (Optional)"
                itemDetailsSKU.keyboardType = UIKeyboardType.Default
                itemDetailsSKU.returnKeyType = UIReturnKeyType.Done
                itemDetailsSKU.delegate = self
                
                if sprubixPiece.sku != nil {
                    itemDetailsSKU.text = sprubixPiece.sku
                }
                
                pieceSpecsView.addSubview(itemQuantityImage)
                pieceSpecsView.addSubview(itemDetailsQuantity)
                
                pieceSpecsView.addSubview(itemPriceImage)
                pieceSpecsView.addSubview(itemDetailsPrice)
                
                pieceSpecsView.addSubview(itemSKUImage)
                pieceSpecsView.addSubview(itemDetailsSKU)
            }
            
            pieceSpecsView.addSubview(itemNameImage)
            pieceSpecsView.addSubview(itemDetailsName)
            
            pieceSpecsView.addSubview(itemCategoryImage)
            pieceSpecsView.addSubview(itemDetailsCategoryButton)
            
            pieceSpecsView.addSubview(itemBrandImage)
            pieceSpecsView.addSubview(itemDetailsBrand)
            
            pieceSpecsView.addSubview(itemSizeImage)
            
            itemDetailsCell.addSubview(pieceSpecsView)
            itemDetailsCell.selectionStyle = UITableViewCellSelectionStyle.None
            
            // if there's more than 1 size there should be more quantity fields
            if pieceSizesArray != nil && pieceSizesArray.count > 1 {
                let heightIncrease = (CGFloat(pieceSizesArray.count) * itemSpecHeight) - itemSpecHeight
                
                // add size leftview on first quantity textfield
                var sizeLabel: UILabel = UILabel()
                sizeLabel.text = pieceSizesArray[0] as? String
                sizeLabel.frame = CGRectMake(0, 0, sizeLabel.intrinsicContentSize().width + 10, itemDetailsPrice.frame.height)
                sizeLabel.textColor = UIColor.lightGrayColor()
                sizeLabel.textAlignment = NSTextAlignment.Left
                
                itemDetailsQuantity.leftView = sizeLabel
                itemDetailsQuantity.leftViewMode = UITextFieldViewMode.Always
                
                pieceQuantityDict.setObject(itemDetailsQuantity.text, forKey: pieceSizesArray[0] as! String)
                
                // add more rows to quantity
                let numNewRows = pieceSizesArray.count - 1
                
                moreQuantityTextFields.removeAll()
                
                for var i = 0; i < numNewRows; i++ {
                    var itemDetailsMoreQuantity = UITextField(frame: CGRectMake(itemDetailsQuantity.frame.origin.x, itemDetailsPrice.frame.origin.y + (CGFloat(i) * itemSpecHeight), itemDetailsQuantity.frame.size.width, itemDetailsQuantity.frame.size.height))
                    itemDetailsMoreQuantity.tintColor = sprubixColor
                    itemDetailsMoreQuantity.placeholder = "How much quantity?"
                    itemDetailsMoreQuantity.keyboardType = UIKeyboardType.NumberPad
                    itemDetailsMoreQuantity.returnKeyType = UIReturnKeyType.Done
                    itemDetailsMoreQuantity.delegate = self
                    
                    // add leftview
                    var sizeLabel: UILabel = UILabel()
                    sizeLabel.text = pieceSizesArray[i + 1] as? String
                    sizeLabel.frame = CGRectMake(0, 0, sizeLabel.intrinsicContentSize().width + 10, itemDetailsPrice.frame.height)
                    sizeLabel.textColor = UIColor.lightGrayColor()
                    sizeLabel.textAlignment = NSTextAlignment.Left
                    
                    itemDetailsMoreQuantity.leftView = sizeLabel
                    itemDetailsMoreQuantity.leftViewMode = UITextFieldViewMode.Always
                    
                    if sprubixPiece.quantity != nil {
                        var itemQuantity = sprubixPiece.quantity[sizeLabel.text!] as! String
                        
                        itemDetailsMoreQuantity.text = "\(itemQuantity)"
                        
                        pieceQuantityDict.setObject(itemDetailsQuantity.text, forKey: sizeLabel.text!)
                    }
                    
                    pieceSpecsView.addSubview(itemDetailsMoreQuantity)
                    moreQuantityTextFields.append(itemDetailsMoreQuantity)
                }
                
                // shift the cells that are below quantity cell
                itemPriceImage.frame.origin.y += heightIncrease
                itemDetailsPrice.frame.origin.y += heightIncrease
                
                itemSKUImage.frame.origin.y += heightIncrease
                itemDetailsSKU.frame.origin.y += heightIncrease
                
                itemSpecHeightTotal = itemSpecHeightTotal + heightIncrease
                
                // update new height for pieceSpecsView
                pieceSpecsView.frame.size.height = itemSpecHeightTotal
            }
            
            return itemDetailsCell
            
        case 3:
            if descriptionText == nil {
                descriptionText = UITextView(frame: CGRectInset(CGRect(x: 0, y: 0, width: screenWidth, height: descriptionTextHeight), 15, 0))
            }
            
            descriptionText.tintColor = sprubixColor
            
            if sprubixPiece.desc != nil {
                descriptionText.text = "\(sprubixPiece.desc)"
            }
            
            if descriptionText.text == "" {
                descriptionText.text = placeholderText
                descriptionText.textColor = UIColor.lightGrayColor()
            }
            
            descriptionText.font = UIFont(name: descriptionText.font.fontName, size: 17)
            descriptionText.delegate = self
            
            itemDescriptionCell.addSubview(descriptionText)
            
            return itemDescriptionCell
            
        default: fatalError("Unknown row in section")
        }
    }
    
    // is dress? switch callback
    func isDressPressed(sender: UISwitch) {
        sprubixPiece.isDress = sender.on
    }
    
    // thumbnail tap gesture recognizer
    func handleTap(gesture: UITapGestureRecognizer) {
        
        selectedThumbnail = gesture.view as! SprubixItemThumbnail
        
        if selectedThumbnail.hasThumbnail != true {
            let sprubixCameraViewController = UIStoryboard.sprubixCameraViewController()
            sprubixCameraViewController?.fromAddDetails = true
            sprubixCameraViewController?.fromAddDetailsPieceType = sprubixPiece.type
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = kCATransitionMoveIn
            transition.subtype = kCATransitionFromTop
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
            
            self.navigationController?.pushViewController(sprubixCameraViewController!, animated: false)
            
        } else {
            itemCoverImageView.image = selectedThumbnail.imageView?.image
        }
    }
    
    func setNavBar(title: String, leftButtonTitle: String, leftButtonCallback: Selector, rightButtonTitle: String, rightButtonCallback: Selector) {
        // create a new navbar
        var emptyNavItem:UINavigationItem = UINavigationItem()
        emptyNavItem.title = title
        
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        cancelButton.setTitle(leftButtonTitle, forState: UIControlState.Normal)
        cancelButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        cancelButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        cancelButton.addTarget(self, action: leftButtonCallback, forControlEvents: UIControlEvents.TouchUpInside)
        
        var cancelBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: cancelButton)
        emptyNavItem.leftBarButtonItem = cancelBarButtonItem

        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle(rightButtonTitle, forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: rightButtonCallback, forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        emptyNavItem.rightBarButtonItem = nextBarButtonItem
        
        // set
        newNavBar.setItems([emptyNavItem], animated: false)

    }
    
    func addImageCancelTapped(sender: UIButton) {
        itemCoverImageView.alpha = 1.0
        
        itemTableView.scrollEnabled = true
        pieceSpecsView.alpha = 1.0
        itemDescriptionCell.alpha = 1.0
        addToClosetButton?.alpha = 1.0
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    // UITextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == placeholderText {
            descriptionText.text = ""
            descriptionText.textColor = UIColor.blackColor()
        }
        
        setNavBar("Item Description", leftButtonTitle: "", leftButtonCallback: nil, rightButtonTitle: "done", rightButtonCallback: "itemDetailsDoneTapped:")
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" {
            descriptionText.text = placeholderText
            descriptionText.textColor = UIColor.lightGrayColor()
            descriptionText.resignFirstResponder()
        }
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    func itemDetailsDoneTapped(sender: UIButton) {
        // format price
        if newNavBar.items[0].title == "Item Price" {
            formatPrice()
        }
        
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    /**
    * Handler for keyboard change event
    */
    func keyboardWillChange(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        if makeKeyboardVisible {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.itemTableView.frame.origin.y = self.oldFrameRect.origin.y - keyboardFrame.height
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                    }
            })
        } else {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.itemTableView.frame.origin.y = self.oldFrameRect.origin.y
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                        self.makeKeyboardVisible = true
                    }
            })
        }
    }
    
    /**
    * Called when the user click on the view (outside the UITextField).
    */
    func tableTapped(gesture: UITapGestureRecognizer) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }
    
    /**
    * Called when 'return' key pressed. return NO to ignore.
    */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        makeKeyboardVisible = false
        
        textField.resignFirstResponder()
        
        newNavBar.setItems([newNavItem], animated: true)
        
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        var navBarTitle: String = ""
        
        switch textField {
        case itemDetailsName:
            navBarTitle = "Item Name"
        case itemDetailsCategory:
            navBarTitle = "Item Category"
        case itemDetailsBrand:
            navBarTitle = "Item Brand"
        case itemDetailsSize:
            navBarTitle = "Item Size"
        case itemDetailsQuantity:
            navBarTitle = "Item Quantity"
        case itemDetailsPrice:
            navBarTitle = "Item Price"
            
            if itemDetailsPrice.text == "" {
                var dollarLabel: UILabel = UILabel(frame: CGRectMake(0, 0, 10, itemDetailsPrice.frame.height))
                dollarLabel.text = "$"
                dollarLabel.textColor = UIColor.lightGrayColor()
                dollarLabel.textAlignment = NSTextAlignment.Left
                
                itemDetailsPrice.leftView = dollarLabel
                itemDetailsPrice.leftViewMode = UITextFieldViewMode.Always
                
                itemDetailsPrice.placeholder = ""
                itemDetailsPrice.text = ""
            }
            
        default:
            navBarTitle = "Item Quantity"
            //fatalError("Error: Unknown textField object, unable to assign navBarTitle")
        }
        
        setNavBar(navBarTitle, leftButtonTitle: "", leftButtonCallback: nil, rightButtonTitle: "done", rightButtonCallback: "itemDetailsDoneTapped:")
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if itemDetailsPrice != nil {
            if textField == itemDetailsPrice && itemDetailsPrice.text == "" {
                itemDetailsPrice.leftView = nil
                itemDetailsPrice.placeholder = "How much does it cost?"
            }
        }
    }
    
    // MLPAutoCompleteTextFieldDataSource
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        
        var completions: [String] = [String]()
        
        manager.POST(SprubixConfig.URL.api + "/piece/brands",
            parameters: [
                "name": textField.text
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var brands = responseObject["data"] as! [NSDictionary]
                
                for brand in brands {
                    completions.append(brand["name"] as! String)
                }
                
                handler(completions)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MLPAutoCompleteTextFieldDelegate
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, didSelectAutoCompleteString selectedString: String!, withAutoCompleteObject selectedObject: MLPAutoCompletionObject!, forRowAtIndexPath indexPath: NSIndexPath!) {
        
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    // AddMoreSizesProtocol
    func setMoreSizes(sizes: NSArray) {
        itemDetailsSize.text = sizes.componentsJoinedByString("/")
        pieceSizesArray = sizes
        
        // increase the number of rows for quantity
        // // itemPriceImage and itemDetailsPrice posY ++ by height increment
        
        if isShop {
            // reset first
            itemPriceImage.frame.origin.y = itemSpecHeight * 5
            itemDetailsPrice.frame.origin.y = itemSpecHeight * 5
            
            itemSKUImage.frame.origin.y = itemSpecHeight * 6
            itemDetailsSKU.frame.origin.y = itemSpecHeight * 6
            
            itemSpecHeightTotal = isShop != true ? itemSpecHeight * 4 : itemSpecHeight * 7
            
            for moreQuantityTextField in moreQuantityTextFields {
                moreQuantityTextField.removeFromSuperview()
            }
            
            if sizes.count > 0 {
                let heightIncrease = (CGFloat(sizes.count) * itemSpecHeight) - itemSpecHeight
                
                // add size leftview on first quantity textfield
                var sizeLabel: UILabel = UILabel()
                sizeLabel.text = sizes[0] as? String
                sizeLabel.frame = CGRectMake(0, 0, sizeLabel.intrinsicContentSize().width + 10, itemDetailsPrice.frame.height)
                sizeLabel.textColor = UIColor.lightGrayColor()
                sizeLabel.textAlignment = NSTextAlignment.Left
                
                itemDetailsQuantity.leftView = sizeLabel
                itemDetailsQuantity.leftViewMode = UITextFieldViewMode.Always
                itemDetailsQuantity.text = pieceQuantityDict.objectForKey(sizeLabel.text!) as? String
                
                // add more rows to quantity
                let numNewRows = sizes.count - 1
                
                moreQuantityTextFields.removeAll()
                
                for var i = 0; i < numNewRows; i++ {
                    var itemDetailsMoreQuantity = UITextField(frame: CGRectMake(itemDetailsQuantity.frame.origin.x, itemDetailsPrice.frame.origin.y + (CGFloat(i) * itemSpecHeight), itemDetailsQuantity.frame.size.width, itemDetailsQuantity.frame.size.height))
                    itemDetailsMoreQuantity.tintColor = sprubixColor
                    itemDetailsMoreQuantity.placeholder = "How much quantity?"
                    itemDetailsMoreQuantity.keyboardType = UIKeyboardType.NumberPad
                    itemDetailsMoreQuantity.returnKeyType = UIReturnKeyType.Done
                    itemDetailsMoreQuantity.delegate = self
                    
                    // add leftview
                    var sizeLabel: UILabel = UILabel()
                    sizeLabel.text = sizes[i + 1] as? String
                    sizeLabel.frame = CGRectMake(0, 0, sizeLabel.intrinsicContentSize().width + 10, itemDetailsPrice.frame.height)
                    sizeLabel.textColor = UIColor.lightGrayColor()
                    sizeLabel.textAlignment = NSTextAlignment.Left
                    
                    itemDetailsMoreQuantity.leftView = sizeLabel
                    itemDetailsMoreQuantity.leftViewMode = UITextFieldViewMode.Always
                    itemDetailsMoreQuantity.text = pieceQuantityDict.objectForKey(sizeLabel.text!) as? String
                    
                    pieceSpecsView.addSubview(itemDetailsMoreQuantity)
                    moreQuantityTextFields.append(itemDetailsMoreQuantity)
                }
                
                // shift the cells that are below quantity cell
                itemPriceImage.frame.origin.y += heightIncrease
                itemDetailsPrice.frame.origin.y += heightIncrease
                
                itemSKUImage.frame.origin.y += heightIncrease
                itemDetailsSKU.frame.origin.y += heightIncrease
                
                itemSpecHeightTotal = itemSpecHeightTotal + heightIncrease
                
            }
            
            // update new height for pieceSpecsView
            pieceSpecsView.frame.size.height = itemSpecHeightTotal
            
            itemPriceImage.setNeedsLayout()
            itemDetailsPrice.setNeedsLayout()
            
            itemSKUImage.setNeedsLayout()
            itemDetailsSKU.setNeedsLayout()
            
            itemTableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 3, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    // button callbacks
    func addMoreSizesPressed(sender: UIButton) {
        if snapshotDetailsSizeController == nil {
            snapshotDetailsSizeController = SnapshotDetailsSizeController()
        }
        
        snapshotDetailsSizeController?.pieceSizesArray = pieceSizesArray
        snapshotDetailsSizeController?.delegate = self
        
        self.navigationController?.pushViewController(snapshotDetailsSizeController!, animated: true)
    }
    
    func deleteImage(sender: UIButton) {
        //println(selectedThumbnail)
        
        selectedThumbnail.setImage(UIImage(named: "details-thumbnail-add"), forState: UIControlState.Normal)
        selectedThumbnail.hasThumbnail = false
        
        itemCoverImageView.image = nil
    }
    
    func itemDetailsCategoryPressed(sender: UIButton) {
        let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Choose a category", rows: itemCategories, initialSelection: 0,
            doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                
                if selectedValue as! String == "Dress" {
                    self.itemIsDress = true
                } else {
                    self.itemIsDress = false
                }
                
                self.itemDetailsCategory.text = "\(selectedValue)"
                
            }, cancelBlock: nil, origin: sender)
        
        // custom done button
        let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        doneButton.setTitleTextAttributes([
            NSForegroundColorAttributeName: sprubixColor,
            ], forState: UIControlState.Normal)
        
        picker.setDoneButton(doneButton)
        
        // custom cancel button
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        cancelButton.setTitle("X", forState: UIControlState.Normal)
        cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
        
        picker.showActionSheetPicker()
    }
    
    // Callback Handler: navigation bar back button
    func cancelTapped(sender: UIBarButtonItem) {
        var alert = UIAlertController(title: "Are you sure?", message: "Changes made to the current item will be lost", preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = sprubixColor
        
        // Yes
        alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: UIAlertActionStyle.Default, handler: { action in
            
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        // No
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func addToClosetPressed(sender: UIButton) {
        let validateResult = self.validateInputs()
        let delay: NSTimeInterval = 3
        
        if validateResult.valid {
            // init sprubix piece
            sprubixPiece.images.removeAll()
            
            for thumbnail in thumbnails {
                if thumbnail.hasThumbnail {
                    sprubixPiece.images.append(thumbnail.imageView!.image!)
                }
            }
            
            if isShop {
                if pieceSizesArray != nil && pieceSizesArray.count > 0 {
                    pieceQuantityDict.removeAllObjects()
                    pieceQuantityDict.setObject(itemDetailsQuantity.text, forKey: pieceSizesArray[0] as! String)
                }
                
                for moreQuantityTextField in moreQuantityTextFields {
                    if moreQuantityTextField.leftView != nil {
                        let moreSize = (moreQuantityTextField.leftView as! UILabel).text
                        pieceQuantityDict.setObject(moreQuantityTextField.text, forKey: moreSize!)
                    }
                }
            }
            
            // item details
            sprubixPiece.name = (itemDetailsName != nil) ? itemDetailsName.text : ""
            sprubixPiece.category = (itemDetailsCategory != nil) ? itemDetailsCategory.text : ""
            sprubixPiece.brand = (itemDetailsBrand != nil) ? itemDetailsBrand.text : ""
            sprubixPiece.size = (itemDetailsSize != nil) ? itemDetailsSize.text : ""
            sprubixPiece.quantity = pieceQuantityDict
            sprubixPiece.price = itemDetailsPrice != nil ? itemDetailsPrice.text : ""
            sprubixPiece.sku = itemDetailsSKU != nil ? itemDetailsSKU.text : ""
            sprubixPiece.desc = (descriptionText != nil && descriptionText.text != placeholderText) ? descriptionText.text : ""
            sprubixPiece.isDress = itemIsDress
            
            let userData: NSDictionary! = defaults.dictionaryForKey("userData")

            var sprubixDict: NSMutableDictionary = [
                "num_pieces": 1,
                "created_by": userData["username"] as! String,
                "from": userData["username"] as! String,
                "user_id": userData["id"] as! Int,
            ]
            
            var pieces: NSMutableDictionary = NSMutableDictionary()
            var pieceDict: NSMutableDictionary = NSMutableDictionary()
            pieceDict.setObject(sprubixPiece.images.count, forKey: "num_images")
            pieceDict.setObject(sprubixPiece.name != nil ? sprubixPiece.name : "", forKey: "name")
            pieceDict.setObject(sprubixPiece.category != nil ? sprubixPiece.category : "", forKey: "category")
            pieceDict.setObject(sprubixPiece.type, forKey: "type")
            pieceDict.setObject(sprubixPiece.isDress, forKey: "is_dress")
            pieceDict.setObject(sprubixPiece.brand != nil ? sprubixPiece.brand : "", forKey: "brand")
            pieceDict.setObject(sprubixPiece.price != nil ? sprubixPiece.price : "", forKey: "price")
            pieceDict.setObject(sprubixPiece.sku != nil ? sprubixPiece.sku : "", forKey: "sku")
            pieceDict.setObject(sprubixPiece.desc != nil ? sprubixPiece.desc : "", forKey: "description")
            pieceDict.setObject(sprubixPiece.images[0].scale * sprubixPiece.images[0].size.height, forKey: "height")
            pieceDict.setObject(sprubixPiece.images[0].scale * sprubixPiece.images[0].size.width, forKey: "width")
            pieceDict.setObject(sprubixPiece.size != nil ? sprubixPiece.size : "", forKey: "size")
            pieceDict.setObject(sprubixPiece.quantity != nil ? sprubixPiece.quantity : "", forKey: "quantity")
            
            pieces.setObject(pieceDict, forKey: sprubixPiece.type.lowercaseString)

            sprubixDict.setObject(pieces, forKey: "pieces")
            
            // Mixpanel - Create Outfit Image Upload, Timer
            mixpanel.timeEvent("Create Outfit Image Upload")
            // Mixpanel - End
            
            // upload piece data
            var requestOperation: AFHTTPRequestOperation = manager.POST(SprubixConfig.URL.api + "/upload/piece/create", parameters: sprubixDict, constructingBodyWithBlock: { formData in
                let data: AFMultipartFormData = formData
            
                for var j = 0; j < self.sprubixPiece.images.count; j++ {
                    var pieceImage: UIImage = self.sprubixPiece.images[j]
                    var pieceImageData: NSData = UIImageJPEGRepresentation(pieceImage, 0.5)
                    
                    var pieceImageName = "piece_\(self.sprubixPiece.type.lowercaseString)_\(j)"
                    var pieceImageFileName = pieceImageName + ".jpg"
                    
                    data.appendPartWithFileData(pieceImageData, name: pieceImageName, fileName: pieceImageFileName, mimeType: "image/jpeg")
                }
                
                }, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    // success block
                    var response = responseObject as! NSDictionary
                    var status = response["status"] as! String
                    
                    if status == "200" {
                        println("Upload Success")
                    
                        Delay.delay(0.6) {
                            // go back to main feed
                            self.navigationController!.delegate = nil
                            
                            let transition = CATransition()
                            transition.duration = 0.3
                            transition.type = kCATransitionReveal
                            transition.subtype = kCATransitionFromBottom
                            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                            
                            self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
                            self.navigationController?.popToViewController(self.navigationController?.viewControllers.first! as! UIViewController, animated: false)
                        }
                        
                        // Mixpanel - Create Outfit Image Upload, Success
                        mixpanel.track("Create Outfit Image Upload", properties: [
                            "Method": "Camera",
                            "Type" : "Piece",
                            "Status": "Success"
                        ])
                        mixpanel.people.increment("Pieces Created", by: 1)
                        // Mixpanel - End
                        
                    } else {
                        // error exception
                        TSMessage.showNotificationInViewController(
                            TSMessage.defaultViewController(),
                            title: "Error",
                            subtitle: "Something went wrong.\nPlease try again.",
                            image: UIImage(named: "filter-cross"),
                            type: TSMessageNotificationType.Error,
                            duration: delay,
                            callback: nil,
                            buttonTitle: nil,
                            buttonCallback: nil,
                            atPosition: TSMessageNotificationPosition.Bottom,
                            canBeDismissedByUser: true)
                        
                        // Print reply from server
                        var message = response["message"] as! String
                        var data = response["data"] as! NSDictionary
                        
                        println(message + " " + status)
                        println(data)
                    }
                    
                }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    // failure block
                    println("Upload Fail")
                    
                    // error exception
                    TSMessage.showNotificationInViewController(
                        TSMessage.defaultViewController(),
                        title: "Error",
                        subtitle: "Something went wrong.\nPlease try again.",
                        image: UIImage(named: "filter-cross"),
                        type: TSMessageNotificationType.Error,
                        duration: delay,
                        callback: nil,
                        buttonTitle: nil,
                        buttonCallback: nil,
                        atPosition: TSMessageNotificationPosition.Bottom,
                        canBeDismissedByUser: true)
                    
                    // Mixpanel - Create Outfit Image Upload, Fail
                    mixpanel.track("Create Outfit Image Upload", properties: [
                        "Method": "Camera",
                        "Type" : "Piece",
                        "Status": "Fail"
                    ])
                    // Mixpanel - End
            })

            // upload progress
            requestOperation.setUploadProgressBlock { (bytesWritten: UInt, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void in
                var percentDone: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                
                println("percentage done: \(percentDone)")
            }
            
            // overlay indicator
            var overlayView: MRProgressOverlayView = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
            overlayView.setModeAndProgressWithStateOfOperation(requestOperation)
            
            overlayView.tintColor = sprubixColor
        } else {
            // Validation failed
            TSMessage.showNotificationInViewController(
                self,
                title: "Error",
                subtitle: validateResult.message,
                image: UIImage(named: "filter-cross"),
                type: TSMessageNotificationType.Error,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
        }
    }

    func doneTapped(sender: UIBarButtonItem) {
        
        formatPrice()
        
        let validateResult = self.validateInputs()
        let delay: NSTimeInterval = 3
        
        if validateResult.valid {
            sprubixPiece.images.removeAll()
            
            for thumbnail in thumbnails {
                if thumbnail.hasThumbnail {
                    sprubixPiece.images.append(thumbnail.imageView!.image!)
                }
            }
            
            if isShop {
                if pieceSizesArray != nil && pieceSizesArray.count > 0 {
                    pieceQuantityDict.removeAllObjects()
                    pieceQuantityDict.setObject(itemDetailsQuantity.text, forKey: pieceSizesArray[0] as! String)
                }
                    
                // loop through more moreQuantityTextFields
                for moreQuantityTextField in moreQuantityTextFields {
                    if moreQuantityTextField.leftView != nil {
                        let moreSize = (moreQuantityTextField.leftView as! UILabel).text
                        pieceQuantityDict.setObject(moreQuantityTextField.text, forKey: moreSize!)
                    }
                }
            }
            
            // item details
            sprubixPiece.name = (itemDetailsName != nil) ? itemDetailsName.text : ""
            sprubixPiece.category = (itemDetailsCategory != nil) ? itemDetailsCategory.text : ""
            sprubixPiece.brand = (itemDetailsBrand != nil) ? itemDetailsBrand.text : ""
            sprubixPiece.size = (itemDetailsSize != nil) ? itemDetailsSize.text : ""
            sprubixPiece.quantity = pieceQuantityDict
            sprubixPiece.price = itemDetailsPrice != nil ? itemDetailsPrice.text : ""
            sprubixPiece.sku = itemDetailsSKU != nil ? itemDetailsSKU.text : ""
            sprubixPiece.desc = (descriptionText != nil && descriptionText.text != placeholderText) ? descriptionText.text : ""
            sprubixPiece.isDress = itemIsDress
            
            if fromInventoryView == false {
                delegate?.setSprubixPiece(sprubixPiece, position: pos)
                
                self.navigationController?.popViewControllerAnimated(true)
            } else {
                // update new information to server
                let userData: NSDictionary! = defaults.dictionaryForKey("userData")
                
                var sprubixDict: NSMutableDictionary = [
                    "num_pieces": 1,
                    "created_by": userData["username"] as! String,
                    "from": userData["username"] as! String,
                    "user_id": userData["id"] as! Int,
                ]
                
                var pieces: NSMutableDictionary = NSMutableDictionary()

                var pieceDict: NSMutableDictionary = NSMutableDictionary()
                pieceDict.setObject(sprubixPiece.images.count, forKey: "num_images")
                pieceDict.setObject(sprubixPiece.id, forKey: "id")
                pieceDict.setObject(sprubixPiece.name != nil ? sprubixPiece.name : "", forKey: "name")
                pieceDict.setObject(sprubixPiece.category != nil ? sprubixPiece.category : "", forKey: "category")
                pieceDict.setObject(sprubixPiece.type, forKey: "type")
                pieceDict.setObject(sprubixPiece.isDress, forKey: "is_dress")
                pieceDict.setObject(sprubixPiece.brand != nil ? sprubixPiece.brand : "", forKey: "brand")
                pieceDict.setObject(sprubixPiece.price != nil ? sprubixPiece.price : "", forKey: "price")
                pieceDict.setObject(sprubixPiece.sku != nil ? sprubixPiece.sku : "", forKey: "sku")
                pieceDict.setObject(sprubixPiece.desc != nil ? sprubixPiece.desc : "", forKey: "description")
                pieceDict.setObject(sprubixPiece.images[0].scale * sprubixPiece.images[0].size.height, forKey: "height")
                pieceDict.setObject(sprubixPiece.images[0].scale * sprubixPiece.images[0].size.width, forKey: "width")
                pieceDict.setObject(sprubixPiece.size != nil ? sprubixPiece.size : "", forKey: "size")
                pieceDict.setObject(sprubixPiece.quantity != nil ? sprubixPiece.quantity : "", forKey: "quantity")
                
                pieces.setObject(pieceDict, forKey: sprubixPiece.type.lowercaseString)
                
                sprubixDict.setObject(pieces, forKey: "pieces")
                
                //println(sprubixDict)
                
                // upload piece data
                var requestOperation: AFHTTPRequestOperation = manager.POST(SprubixConfig.URL.api + "/upload/piece/update", parameters: sprubixDict, constructingBodyWithBlock: { formData in
                    let data: AFMultipartFormData = formData
                    
                    for var j = 0; j < self.sprubixPiece.images.count; j++ {
                        var pieceImage: UIImage = self.sprubixPiece.images[j]
                        var pieceImageData: NSData = UIImageJPEGRepresentation(pieceImage, 0.5)
                        
                        var pieceImageName = "piece_\(self.sprubixPiece.type.lowercaseString)_\(j)"
                        var pieceImageFileName = pieceImageName + ".jpg"
                        
                        data.appendPartWithFileData(pieceImageData, name: pieceImageName, fileName: pieceImageFileName, mimeType: "image/jpeg")
                    }
                    
                    }, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        // success block
                        var response = responseObject as! NSDictionary
                        var status = response["status"] as! String
                        
                        if status == "200" {
                            println("Upload Success")
                        
                            Delay.delay(0.6) {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                            
                        } else {
                            // error exception
                            TSMessage.showNotificationInViewController(
                                TSMessage.defaultViewController(),
                                title: "Error",
                                subtitle: "Something went wrong.\nPlease try again.",
                                image: UIImage(named: "filter-cross"),
                                type: TSMessageNotificationType.Error,
                                duration: delay,
                                callback: nil,
                                buttonTitle: nil,
                                buttonCallback: nil,
                                atPosition: TSMessageNotificationPosition.Bottom,
                                canBeDismissedByUser: true)
                            
                            // Print reply from server
                            var message = response["message"] as! String
                            var data = response["data"] as! NSDictionary
                            
                            println(message + " " + status)
                            println(data)
                        }
                        
                    }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        // failure block
                        println("Upload Fail")
                        
                        // error exception
                        TSMessage.showNotificationInViewController(
                            TSMessage.defaultViewController(),
                            title: "Error",
                            subtitle: "Something went wrong.\nPlease try again.",
                            image: UIImage(named: "filter-cross"),
                            type: TSMessageNotificationType.Error,
                            duration: delay,
                            callback: nil,
                            buttonTitle: nil,
                            buttonCallback: nil,
                            atPosition: TSMessageNotificationPosition.Bottom,
                            canBeDismissedByUser: true)
                })
                
                // upload progress
                requestOperation.setUploadProgressBlock { (bytesWritten: UInt, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void in
                    var percentDone: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                    
                    println("percentage done: \(percentDone)")
                }
                
                // overlay indicator
                var overlayView: MRProgressOverlayView = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
                overlayView.setModeAndProgressWithStateOfOperation(requestOperation)
                
                overlayView.tintColor = sprubixColor
            }
        } else {
            // Validation failed
            TSMessage.showNotificationInViewController(
                self,
                title: "Error",
                subtitle: validateResult.message,
                image: UIImage(named: "filter-cross"),
                type: TSMessageNotificationType.Error,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if itemDetailsPrice != nil && textField == itemDetailsPrice {
            // Prevent double decimal point
            if string == "." && contains(itemDetailsPrice.text, ".") {
                return false
            }
        }
        
        return true
    }
    
    // check if category, price and quantity (if shop) is present
    // there must be at least one image
    func validateInputs() -> (valid: Bool, message: String) {
        var valid: Bool = true
        var message: String = ""
        
        // Compulsory for all: 1 image, item category
        var hasOneThumbnail: Bool = false
        
        for thumbnail in thumbnails {
            if thumbnail.hasThumbnail {
                hasOneThumbnail = true
            }
        }
        
        if hasOneThumbnail == false {
            message += "Please add an item photo\n"
            valid = false
        }
        
        if itemDetailsCategory.text == "" {
            message += "Please choose a category\n"
            valid = false
        }
        
        if isShop {
            // if shop, name and brand are required
            if itemDetailsName.text == "" {
                message += "Please enter an item name\n"
                valid = false
            }
            else if count(itemDetailsName.text) > 255 {
                message += "The item name is too long\n"
                valid = false
            }
            
            if itemDetailsBrand.text == "" {
                message += "Please enter the brand name\n"
                valid = false
            }
            else if count(itemDetailsBrand.text) > 255 {
                message += "The brand name is too long\n"
                valid = false
            }
            
            // Shop only: check if category, price and quantity (if shop) is present
            if itemDetailsSize.text == "" {
                message += "Please enter the sizes\n"
                valid = false
            }
            
            // All sizes must have a quantity
            var allHaveQuantity: Bool = true
            
            if itemDetailsQuantity.text == "" {
                allHaveQuantity = false
            }
            
            for moreQuantityTextField in moreQuantityTextFields {
                if moreQuantityTextField.text == "" {
                    allHaveQuantity = false
                }
            }
            
            if allHaveQuantity == false {
                message += "Please enter the quantity for all the sizes\n"
                valid = false
            }
            
            if itemDetailsPrice.text == "" {
                message += "Please enter the item price\n"
                valid = false
            }
            /*else if itemDetailsPrice.text.floatValue < 15 {
                message += "The item price must be at least $15\n"
                valid = false
            }*/
            
            // Sku is optional
            if count(itemDetailsSKU.text) > 255 {
                message += "The SKU code is too long\n"
                valid = false
            }
        }
        else {
            // if non-shop, name and brand are optional
            if count(itemDetailsName.text) > 255 {
                message += "The item name is too long\n"
                valid = false
            }
            
            if count(itemDetailsBrand.text) > 255 {
                message += "The brand name is too long\n"
                valid = false
            }
        }
        
        // If description is placeholder text, remove it
        if descriptionText != nil && descriptionText.text == placeholderText {
            descriptionText.text = ""
        }
        else if descriptionText != nil && count(descriptionText.text) > 255 {
            message += "The description is too long\n"
            valid = false
        }

        return (valid, message)
    }
    
    func resizeImage(image: UIImage, width: CGFloat) -> UIImage {
        var newImageHeight = image.size.height * width / image.size.width
        
        var size: CGSize = CGSizeMake(width, newImageHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0) // avoid image quality degrading
        
        image.drawInRect(CGRectMake(0, 0, width, newImageHeight))
        
        // final image
        let finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    func formatPrice() {
        if contains(itemDetailsPrice.text, ".") {
            let priceArray = itemDetailsPrice.text.componentsSeparatedByString(".")
            var digit = priceArray[0] as String
            var decimal = priceArray[1] as String
            
            // if .XX , make it 0.XX
            if digit == "" {
                digit = "0"
            }
            
            // truncate decimal
            if count(decimal) == 0 {
                decimal = "00"
            } else if count(decimal) == 1 {
                decimal = "\(decimal)0"
            } else {
                decimal = decimal.substringWithRange(Range(start: decimal.startIndex, end: advance(decimal.startIndex, 2)))
            }
            
            itemDetailsPrice.text = "\(digit).\(decimal)"
            
        } else if itemDetailsPrice.text != "" {
            itemDetailsPrice.text = "\(itemDetailsPrice.text).00"
        }
    }
}
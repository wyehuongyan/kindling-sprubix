//
//  CartViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 30/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class CartViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var cartData: NSDictionary = NSDictionary()

    var sellerCartItemDictionary: NSMutableDictionary = NSMutableDictionary()
    var sellers: [NSDictionary] = [NSDictionary]()
    var sellerDeliveryMethods: [String] = [String]()
    var sellerSubtotal: [Float] = [Float]()
    var sellerShippingRate: [Float] = [Float]()
    
    let cartItemCellIdentifier = "CartItemCell"
    let cartItemSectionHeaderIdentifier = "CartItemSectionHeader"
    let cartItemSectionFooterIdentifier = "CartItemSectionFooter"
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var tableFooterView: UIView!
    var grandTotalAmount: UILabel!
    
    @IBOutlet var cartTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        // get rid of line seperator for empty cells
        cartTableView.backgroundColor = sprubixGray
        cartTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // add table footerview
        tableFooterView = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight))
        
        tableFooterView.backgroundColor = UIColor.whiteColor()
        
        let grandTotal = UILabel(frame: CGRectMake(10, 10, screenWidth / 2 - 10, 24))
        
        grandTotal.font = UIFont.boldSystemFontOfSize(17.0)
        grandTotal.textColor = sprubixColor
        grandTotal.text = "Total"
        
        grandTotalAmount = UILabel(frame: CGRectMake(screenWidth / 2, 10, screenWidth / 2 - 10, 24))
        grandTotalAmount.textAlignment = NSTextAlignment.Right
        grandTotalAmount.textColor = sprubixColor
        
        tableFooterView.addSubview(grandTotal)
        tableFooterView.addSubview(grandTotalAmount)
        
        cartTableView.tableFooterView = tableFooterView
        
        retrieveCartItems()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "My Cart"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.exclusiveTouch = true
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("checkout", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 80, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "checkout:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sellers.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let seller = sellers[section] as NSDictionary
        
        return sellerCartItemDictionary.objectForKey(seller)!.count
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionHeaderIdentifier) as! CartItemSectionHeader
        
        let seller = sellers[section] as NSDictionary
        let pieceImagesString = seller["image"] as! String
        let pieceImageURL: NSURL = NSURL(string: pieceImagesString)!
        
        cell.sellerImageView.setImageWithURL(pieceImageURL)
        cell.sellerName.text = seller["username"] as? String
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return navigationHeight
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionFooterIdentifier) as! CartItemSectionFooter
        
        let sellerDeliveryMethod = sellerDeliveryMethods[section] as String
    
        cell.deliveryMethod.setTitle(sellerDeliveryMethod, forState: UIControlState.Normal)
        cell.subtotal.text = String(format: "$%.2f", sellerSubtotal[section])
        cell.shippingRate.text = String(format: "$%.2f", sellerShippingRate[section])
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 86.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cartItemCellIdentifier, forIndexPath: indexPath) as! CartItemCell
        
        let seller = sellers[indexPath.section] as NSDictionary
        let cartItems = sellerCartItemDictionary[seller] as! [NSDictionary]
        let cartItem = cartItems[indexPath.row] as NSDictionary
        
        let piece = cartItem["piece"] as! NSDictionary
        let price = piece["price"] as! String
        let quantity = cartItem["quantity"] as! Int
        let size = cartItem["size"] as? String

        cell.cartItemName.text = piece["name"] as? String
        cell.cartItemPrice.text = "$\(price)"
        cell.cartItemQuantity.text = "Quantity: \(quantity)"
        cell.cartItemSize.text = "Size: \(size!)"
        
        let pieceId = piece["id"] as! Int
        let pieceImagesString = piece["images"] as! NSString
        let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
        
        let thumbnailURLString = pieceImageDict["thumbnail"] as! String
        let pieceImageURL: NSURL = NSURL(string: thumbnailURLString)!
        
        cell.cartItemImageView.setImageWithURL(pieceImageURL)
        
        cell.editCartItemAction = { Void in
            return
        }
        
        cell.deleteCartItemAction = { Void in
            
            var alert = UIAlertController(title: "Confirm delete?", message: "This action cannot be undone", preferredStyle: UIAlertControllerStyle.Alert)
            alert.view.tintColor = sprubixColor
            
            // Yes
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { action in
                
            }))
            
            // No
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    func retrieveCartItems() {
        // REST call to server to create cart item and add to user's cart
        manager.GET(SprubixConfig.URL.api + "/cart",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.cartData = responseObject as! NSDictionary
                
                self.formatCartItemData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func formatCartItemData() {
        
        let cartItemData = cartData["cart_items"] as! [NSDictionary]

        for cartItem in cartItemData {
            let seller = cartItem["seller"] as! NSDictionary
            
            var cartItems: [NSDictionary]? = sellerCartItemDictionary.objectForKey(seller) as? [NSDictionary]
            
            if cartItems == nil {
                cartItems = [NSDictionary]()
            }
            
            cartItems?.append(cartItem)
            
            // formatted into key: seller, value: [cartItem, cartItem]
            sellerCartItemDictionary.setObject(cartItems!, forKey: seller)
        }
        
        var grandTotal: Float = 0
        
        for (seller, cartItems) in sellerCartItemDictionary {
            sellers.append(seller as! NSDictionary)
            
            var highestDeliveryOption: String = ""
            var highestDeliveryOptionCost: Float = 0
            var subtotal: Float = 0
            
            for cartItem in cartItems as! [NSDictionary] {
                // compare delivery costs
                // // always take the higher cost
                let deliveryOption = cartItem["delivery_option"] as! NSDictionary

                let currentDeliveryOptionCost = (deliveryOption["price"] as! NSString).floatValue
                
                if currentDeliveryOptionCost > highestDeliveryOptionCost {
                    highestDeliveryOptionCost = currentDeliveryOptionCost
                    highestDeliveryOption = deliveryOption["name"] as! String
                }
                
                // add up costs of items
                let piece = cartItem["piece"] as! NSDictionary
                subtotal += (piece["price"] as! NSString).floatValue
            }
            
            sellerDeliveryMethods.append(highestDeliveryOption)
            sellerShippingRate.append(highestDeliveryOptionCost)
            sellerSubtotal.append(subtotal)
            
            grandTotal += subtotal + highestDeliveryOptionCost
        }
        
        cartTableView.reloadData()
        
        // set grandTotalAmount and refresh tableFooterView
        grandTotalAmount.text = String(format: "$%.2f", grandTotal)
        tableFooterView.setNeedsLayout()
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func checkout(sender: UIBarButtonItem) {
        println("check out")
    }
}

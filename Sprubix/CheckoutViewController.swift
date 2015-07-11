//
//  CheckoutViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import Braintree
import TSMessages
import SSKeychain

class CheckoutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var delegate: SidePanelViewControllerDelegate?
    
    var sellerCartItemDictionary: NSMutableDictionary!
    var sellers: [NSDictionary] = [NSDictionary]()
    var sellerDeliveryMethods: [String] = [String]()
    var sellerSubtotal: [Float] = [Float]()
    var sellerShippingRate: [Float] = [Float]()
    
    let checkoutItemCellIdentifier = "CheckoutItemCell"
    let checkoutDeliveryPaymentCellIdentifier = "CheckoutDeliveryPaymentCell"
    let cartItemSectionHeaderIdentifier = "CartItemSectionHeader"
    let cartItemSectionFooterIdentifier = "CartItemSectionFooter"
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var orderHeaderView: UIView!
    var orderTotal: String!
    var placeOrderButton: UIButton!
    
    @IBOutlet var checkoutTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        checkoutTableView.backgroundColor = sprubixGray
        checkoutTableView.tableFooterView = UIView(frame: CGRectZero)
        
        orderHeaderView = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight))
        
        orderHeaderView.backgroundColor = UIColor.whiteColor()
        
        // set up order total view
        let grandTotal = UILabel(frame: CGRectMake(10, 10, screenWidth / 2 - 10, 24))
        
        grandTotal.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotal.textColor = sprubixColor
        grandTotal.text = "Order Total"
        
        var grandTotalAmount: UILabel = UILabel(frame: CGRectMake(screenWidth / 2, 10, screenWidth / 2 - 10, 24))
        grandTotalAmount.textAlignment = NSTextAlignment.Right
        grandTotalAmount.textColor = sprubixColor
        grandTotalAmount.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotalAmount.text = orderTotal
        
        orderHeaderView.addSubview(grandTotal)
        orderHeaderView.addSubview(grandTotalAmount)
        
        // set up place order CTA button
        // add to bag CTA button
        placeOrderButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
        placeOrderButton.backgroundColor = sprubixColor
        placeOrderButton.titleLabel?.font = UIFont.boldSystemFontOfSize(18.0)
        placeOrderButton.setTitle("Place Order", forState: UIControlState.Normal)
        placeOrderButton.addTarget(self, action: "placeOrderButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(placeOrderButton)
        
        retrieveBTClientToken()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Checkout"
        
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
    
    func retrieveBTClientToken() {
        // REST call to server
        manager.GET(SprubixConfig.URL.api + "/auth/braintree/token",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                var status = responseObject["status"] as? String
                
                if status != nil {
                    
                    if status == "200" {
                        var token = responseObject["token"] as? String
                        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                        
                        let username = userData!["username"] as! String
                        
                        SSKeychain.setPassword(token, forService: "braintree", account: username)
                        
                        // init braintree
                        braintreeRef = Braintree(clientToken: token)
                        
                        println("Braintree instance initialized")
                        
                    } else {
                        var automatic: NSTimeInterval = 0
                        
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Braintree token retrieval failed.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                    
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sellers.count + 1 // last section is for Delivery Address and Payment Method
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == sellers.count {
            return 2 // 1 for Delivery Address, 1 for Payment Method
        } else {
            let seller = sellers[section] as NSDictionary
        
            return sellerCartItemDictionary.objectForKey(seller)!.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case sellers.count:
            
            let cell = tableView.dequeueReusableCellWithIdentifier(checkoutDeliveryPaymentCellIdentifier, forIndexPath: indexPath) as! CheckoutDeliveryPaymentCell
            
            switch indexPath.row {
            case 0:
                cell.deliveryPaymentImage.image = UIImage(named: "sidemenu-fulfilment")
                cell.deliveryPaymentText.text = "Show Default Delivery Address Here"
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                
                return cell
            case 1:
                cell.deliveryPaymentImage.image = UIImage(named: "sidemenu-orders")
                cell.deliveryPaymentText.text = "Show Default Payment Method Here"
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                
                return cell
            default:
                fatalError("Unknown row in last section of CheckoutViewController")
            }
            
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier(checkoutItemCellIdentifier, forIndexPath: indexPath) as! CheckoutItemCell
            
            let seller = sellers[indexPath.section] as NSDictionary
            let cartItems = sellerCartItemDictionary[seller] as! [NSDictionary]
            let cartItem = cartItems[indexPath.row] as NSDictionary
            
            let piece = cartItem["piece"] as! NSDictionary
            let price = piece["price"] as! String
            let quantity = cartItem["quantity"] as! Int
            let size = cartItem["size"] as? String
            
            cell.checkoutItemName.text = piece["name"] as? String
            cell.checkoutItemPrice.text = "$\(price)"
            cell.checkoutItemQuantity.text = "Quantity: \(quantity)"
            cell.checkoutItemSize.text = "Size: \(size!)"
            
            let pieceId = piece["id"] as! Int
            let pieceImagesString = piece["images"] as! NSString
            let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
            
            let thumbnailURLString = pieceImageDict["thumbnail"] as! String
            let pieceImageURL: NSURL = NSURL(string: thumbnailURLString)!
            
            cell.checkoutItemImageView.setImageWithURL(pieceImageURL)
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == sellers.count {
            return orderHeaderView
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionHeaderIdentifier) as! CartItemSectionHeader
            
            let seller = sellers[section] as NSDictionary
            let pieceImagesString = seller["image"] as! String
            let pieceImageURL: NSURL = NSURL(string: pieceImagesString)!
            let sellerId = seller["id"] as! Int
            
            cell.sellerImageView.setImageWithURL(pieceImageURL)
            cell.sellerName.text = seller["username"] as? String
            
            cell.tappedOnSellerAction = { Void in
                self.delegate?.showUserProfile(seller)
            }
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == sellers.count {
            return nil
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionFooterIdentifier) as! CartItemSectionFooter
            
            let sellerDeliveryMethod = sellerDeliveryMethods[section] as String
            
            cell.deliveryMethod.setTitle(sellerDeliveryMethod, forState: UIControlState.Normal)
            cell.subtotal.text = String(format: "$%.2f", sellerSubtotal[section])
            cell.shippingRate.text = String(format: "$%.2f", sellerShippingRate[section])
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == sellers.count {
            return 0
        } else {
            return 86.0
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return navigationHeight
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func placeOrderButtonPressed(sender: UIButton) {
        println("Place order pressed")
    }
}

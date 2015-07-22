//
//  ShopOrderDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 19/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class ShopOrderDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var shopOrder: NSDictionary!
    var orderNum: String!
    var orderStatuses: [NSDictionary] = [NSDictionary]()
    var customerId: Int?
    
    let orderDetailsUserCellIdentifier = "OrderDetailsUserCell"
    let orderDetailsContactCellIdentifier = "OrderDetailsContactCell"
    let checkoutItemCellIdentifier = "CheckoutItemCell"
    let cartItemSectionFooterIdentifier = "CartItemSectionFooter"
    let orderDetailsStatusCellIdentifier = "OrderDetailsStatusCell"
    
    @IBOutlet var shopOrderDetailsTableView: UITableView!
    
    var orderHeaderView: UIView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        shopOrderDetailsTableView.backgroundColor = sprubixGray
        
        shopOrderDetailsTableView.dataSource = self
        shopOrderDetailsTableView.delegate = self
        
        // get rid of line seperator for empty cells
        shopOrderDetailsTableView.backgroundColor = sprubixGray
        shopOrderDetailsTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // register OrderDetailsUserCell (not storyboard)
        shopOrderDetailsTableView.registerClass(OrderDetailsUserCell.self, forCellReuseIdentifier: orderDetailsUserCellIdentifier)
        
        let totalPrice = shopOrder["total_price"] as! String
        
        initOrderHeader(totalPrice)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    func initOrderHeader(orderTotal: String) {
        // set up order total view
        orderHeaderView = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeaderAndStatusbarHeight))
        
        orderHeaderView.backgroundColor = sprubixGray
        
        let labelContainer = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight))
        labelContainer.backgroundColor = UIColor.whiteColor()
        
        let grandTotal = UILabel(frame: CGRectMake(10, 10, screenWidth / 2 - 10, 24))
        
        grandTotal.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotal.textColor = sprubixColor
        grandTotal.text = "Order Total"
        
        var grandTotalAmount: UILabel = UILabel(frame: CGRectMake(screenWidth / 2, 10, screenWidth / 2 - 10, 24))
        grandTotalAmount.textAlignment = NSTextAlignment.Right
        grandTotalAmount.textColor = sprubixColor
        grandTotalAmount.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotalAmount.text = "$\(orderTotal)"
        
        labelContainer.addSubview(grandTotal)
        labelContainer.addSubview(grandTotalAmount)
        
        orderHeaderView.addSubview(labelContainer)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Order #\(orderNum)"
        
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
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                // OrderDetailsUserCell
                let cell = tableView.dequeueReusableCellWithIdentifier(orderDetailsUserCellIdentifier, forIndexPath: indexPath) as! OrderDetailsUserCell
                
                let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                let shoppableType: String? = userData!["shoppable_type"] as? String
                
                if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
                    // shopper
                    // // should see shop details
                    let shop = shopOrder["user"] as! NSDictionary
                    let sellerImagesString = shop["image"] as! String
                    let sellerImageURL: NSURL = NSURL(string: sellerImagesString)!
                    let sellerCoverString = shop["cover"] as! String
                    let sellerCoverURL: NSURL = NSURL(string: sellerCoverString)!
                    
                    customerId = userData!["id"] as? Int
                    
                    let shopUsername = shop["username"] as! String
                    let shopName = shop["name"] as! String
                    
                    cell.userImageView.setImageWithURL(sellerImageURL)
                    cell.coverImageView.setImageWithURL(sellerCoverURL)
                    cell.username.text = "\(shopName)"
                    cell.address.text = "(@\(shopUsername))"
                    
                    cell.initUserInfo()
                    
                } else {
                    // shop
                    // // should see user details
                    let buyer = shopOrder["buyer"] as! NSDictionary
                    let buyerImagesString = buyer["image"] as! String
                    let buyerImageURL: NSURL = NSURL(string: buyerImagesString)!

                    let buyerCoverString = buyer["cover"] as! String
                    let buyerCoverURL: NSURL = NSURL(string: buyerCoverString)!
                    
                    customerId = buyer["id"] as? Int
                    
                    cell.userImageView.setImageWithURL(buyerImageURL)
                    cell.coverImageView.setImageWithURL(buyerCoverURL)

                    let deliveryAddress = shopOrder["shipping_address"] as! NSDictionary
                    let buyerFirstName = deliveryAddress["first_name"] as! String
                    let buyerLastName = deliveryAddress["last_name"] as! String
                    let buyerName = "\(buyerFirstName) \(buyerLastName)"
                    let buyerUsername = buyer["username"] as! String
                    
                    cell.username.text = "\(buyerName) (@\(buyerUsername))"
                    
                    let address1 = deliveryAddress["address_1"] as! String
                    var address2: String? = deliveryAddress["address_2"] as? String
                    let postalCode = deliveryAddress["postal_code"] as! String
                    let country = deliveryAddress["country"] as! String
                    
                    var deliveryAddressText = address1
                    
                    if address2 != nil {
                        deliveryAddressText += "\n\(address2!)"
                    }
                    
                    deliveryAddressText += "\n\(postalCode)\n\(country)"
                    
                    cell.address.text = deliveryAddressText
                    
                    cell.initUserInfo()
                }
                
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                
                return cell
            case 1:
                // OrderDetailsContactCell
                let cell = tableView.dequeueReusableCellWithIdentifier(orderDetailsContactCellIdentifier, forIndexPath: indexPath) as! OrderDetailsContactCell
                
                let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                let shoppableType: String? = userData!["shoppable_type"] as? String
                
                if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
                    // shopper
                    // // should see shop details
                    let shop = shopOrder["user"] as! NSDictionary
                    let email = shop["email"] as! String
                    
                    var contactNumber = shop["contact_number"] as! String
                    
                    if contactNumber == "" {
                        contactNumber = "Not available"
                    }
                    
                    cell.emailAddress.text = email
                    cell.contactNumber.text = contactNumber
                    
                } else {
                    // shop
                    // // should see user details
                    let buyer = shopOrder["buyer"] as! NSDictionary
                    let email = buyer["email"] as! String
                    
                    let deliveryAddress = shopOrder["shipping_address"] as! NSDictionary
                    let contactNumber = deliveryAddress["contact_number"] as! String
                    
                    cell.emailAddress.text = email
                    cell.contactNumber.text = contactNumber
                }
                
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                
                return cell
            default:
                fatalError("Unknown row returned in ShopOrderDetailsViewController")
            }
        case 1:
            // order items
            let cell = tableView.dequeueReusableCellWithIdentifier(checkoutItemCellIdentifier, forIndexPath: indexPath) as! CheckoutItemCell
            
            let cartItems = shopOrder["cart_items"] as! [NSDictionary]
            let cartItem = cartItems[indexPath.row] as NSDictionary
            
            let piece = cartItem["piece"] as! NSDictionary
            let price = piece["price"] as! NSString
            let quantity = cartItem["quantity"] as! Int
            let size = cartItem["size"] as? String
            
            cell.checkoutItemName.text = piece["name"] as? String
            cell.checkoutItemPrice.text = String(format: "$%.2f", price.floatValue * Float(quantity))
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
        case 2:
            // order status
            let cell = tableView.dequeueReusableCellWithIdentifier(orderDetailsStatusCellIdentifier, forIndexPath: indexPath) as! OrderDetailsStatusCell
            
            let orderStatus = shopOrder["order_status"] as! NSDictionary
            let orderStatusName = orderStatus["name"] as! String
            let orderStatusId = orderStatus["id"] as! Int
            
            var statusImageName = ""
            var statusTintColor = UIColor.lightGrayColor()
            
            cell.orderStatusId = orderStatusId
            cell.setStatusImage()
            cell.status.text = orderStatusName
            
            cell.changeStatusAction = { Void in
                
                if self.orderStatuses.count <= 0 {
                    // REST call to server to retrieve order statuses
                    manager.GET(SprubixConfig.URL.api + "/order/statuses",
                        parameters: nil,
                        success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                            
                            self.orderStatuses = responseObject as! [NSDictionary]
                            
                            self.initOrderStatusActionSheet()
                        },
                        failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                            println("Error: " + error.localizedDescription)
                    })
                } else {
                    self.initOrderStatusActionSheet()
                }
                
                return
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return cell
        default:
            fatalError("Unknown section returned in ShopOrderDetailsViewController")
        }
    }
    
    func initOrderStatusActionSheet() {
        let alertViewController = UIAlertController(title: "Change order status to...", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertViewController.view.tintColor = UIColor.grayColor()
        
        for orderStatus in orderStatuses {
            let orderStatusName = orderStatus["name"] as! String
            let orderStatusId = orderStatus["id"] as! Int
            
            var actionStyle = UIAlertActionStyle.Default
            
            if orderStatusId == 7 || orderStatusId == 8 {
                // cancelled
                actionStyle = UIAlertActionStyle.Destructive
            }
            
            let buttonAction = UIAlertAction(title: orderStatusName, style: actionStyle, handler: {
                action in
                
                // handler
                self.changeOrderStatus(action.title)
            })
            
            alertViewController.addAction(buttonAction)
        }
        
        // add cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {
            action in
            // handler
            self.dismissViewControllerAnimated(true, completion: nil)
            alertViewController.removeFromParentViewController()
        })
        
        alertViewController.addAction(cancelAction)
        
        self.presentViewController(alertViewController, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                // OrderDetailsUserCell
                let customerDetailsViewController = UIStoryboard.customerDetailsViewController()
                
                customerDetailsViewController?.customerId = customerId
                customerDetailsViewController?.shopOrder = shopOrder
                
                self.navigationController?.pushViewController(customerDetailsViewController!, animated: true)
            default:
                // nothing happens
                break
            }
        default:
            // nothing happens
            break
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 2:
            return orderHeaderView
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 2:
            return navigationHeaderAndStatusbarHeight
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionFooterIdentifier) as! CartItemSectionFooter
            
            let sellerDeliveryMethod = shopOrder["delivery_option"] as! NSDictionary
            let sellerDeliveryMethodName = sellerDeliveryMethod["name"] as! String
            let itemsPrice = shopOrder["items_price"] as! String
            let shippingRate = shopOrder["shipping_rate"] as! String
            
            cell.deliveryMethod.setTitle(sellerDeliveryMethodName, forState: UIControlState.Normal)
            cell.subtotal.text = "$\(itemsPrice)"
            cell.shippingRate.text = "$\(shippingRate)"
            
            return cell

        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 86.0
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                // OrderDetailsUserCell
                return 100.0
            case 1:
                // OrderDetailsContactCell
                return 68.0
            default:
                fatalError("Unknown row returned in ShopOrderDetailsViewController")
            }
        case 1:
            // order items
            return 100.0
        case 2:
            // order status
            return 52.0
        default:
            fatalError("Unknown section returned in ShopOrderDetailsViewController")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // user info and contact info
            return 2
        case 1:
            // order items
            return (shopOrder["cart_items"] as! [NSDictionary]).count
        case 2:
            // order status
            return 1
        default:
            fatalError("Unknown section returned in ShopOrderDetailsViewController")
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func changeOrderStatus(orderStatus: String) {
        // REST call to server to update order status
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

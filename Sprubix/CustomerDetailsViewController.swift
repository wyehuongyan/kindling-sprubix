//
//  CustomerDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 21/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class CustomerDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var recentOrders: [NSDictionary] = [NSDictionary]()
    var shopOrder: NSDictionary!
    
    let customerDetailsRecentOrdersCellIdentifier = "CustomerDetailsRecentOrders"
    let orderDetailsUserCellIdentifier = "OrderDetailsUserCell"
    let orderDetailsContactCellIdentifier = "OrderDetailsContactCell"
    let orderCellIdentifier: String = "OrderCell"
    
    var customerId: Int?
    var customerTotalSpending: String!
    
    @IBOutlet var customerDetailsTableView: UITableView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        customerDetailsTableView.backgroundColor = sprubixGray
        
        customerDetailsTableView.dataSource = self
        customerDetailsTableView.delegate = self
        
        // get rid of line seperator for empty cells
        customerDetailsTableView.backgroundColor = sprubixGray
        customerDetailsTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // register OrderDetailsUserCell (not storyboard)
        customerDetailsTableView.registerClass(OrderDetailsUserCell.self, forCellReuseIdentifier: orderDetailsUserCellIdentifier)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        retrieveUserShopOrders()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            newNavItem.title = "Shop"
        } else {
            newNavItem.title = "Customer"
        }
        
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
    
    func retrieveUserShopOrders() {
        // REST call to server to retrieve orders this customer made from this shop
        manager.POST(SprubixConfig.URL.api + "/orders/user/shop",
            parameters: [
                "buyer_id": customerId!
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var userShopOrdersString = responseObject["user_shop_orders"] as! String
                var userShopOrdersData: NSData = userShopOrdersString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var userShopOrders: NSDictionary = NSJSONSerialization.JSONObjectWithData(userShopOrdersData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                self.recentOrders = userShopOrders["data"] as! [NSDictionary]
                self.customerTotalSpending = responseObject["total_spending"] as! String
                
                self.customerDetailsTableView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
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
            // recent orders
            let cell = tableView.dequeueReusableCellWithIdentifier(orderCellIdentifier, forIndexPath: indexPath) as! OrderCell

            let order = recentOrders[indexPath.row] as NSDictionary
            
            let userData: NSDictionary? = defaults.dictionaryForKey("userData")
            let shoppableType: String? = userData!["shoppable_type"] as? String
            
            if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
                // shopper
                let shop = order["user"] as! NSDictionary
                let shopUserName = shop["username"] as! String
                
                cell.username.text = shopUserName
            } else {
                // shop
                let user = order["buyer"] as! NSDictionary
                let username = user["username"] as! String
                
                cell.username.text = username
            }
            
            let totalPrice = order["total_price"] as! String
            let orderNumber = order["uid"] as! String
            let createdAt = order["created_at"] as! String
            let orderStatusId = order["order_status_id"] as! Int
            
            cell.price.text = "$\(totalPrice)"
            cell.orderNumber.text = "#\(orderNumber)"
            cell.dateTime.text = createdAt
            cell.orderStatusId = orderStatusId
            cell.setStatusImage()
   
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        default:
            fatalError("Unknown section returned in CustomerDetailsViewController")
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 1:
            let shopOrder = recentOrders[indexPath.row] as NSDictionary
            
            let shopOrderDetailsViewController = UIStoryboard.shopOrderDetailsViewController()
            shopOrderDetailsViewController!.orderNum = shopOrder["uid"] as! String
            shopOrderDetailsViewController!.shopOrder = shopOrder
            
            self.navigationController?.pushViewController(shopOrderDetailsViewController!, animated: true)
        default:
            break
        }
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0:
            // user info and contact info
            // // total spent
            let totalSpentView = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight))
            totalSpentView.backgroundColor = UIColor.whiteColor()
            
            let grandTotal = UILabel(frame: CGRectMake(10, 10, screenWidth / 2 - 10, 24))
            
            grandTotal.font = UIFont.boldSystemFontOfSize(20.0)
            grandTotal.textColor = sprubixColor
            grandTotal.text = "Total Spent"
            
            var grandTotalAmount: UILabel = UILabel(frame: CGRectMake(screenWidth / 2, 10, screenWidth / 2 - 10, 24))
            grandTotalAmount.textAlignment = NSTextAlignment.Right
            grandTotalAmount.textColor = sprubixColor
            grandTotalAmount.font = UIFont.boldSystemFontOfSize(20.0)
            grandTotalAmount.text = "$\(customerTotalSpending)"
            
            totalSpentView.addSubview(grandTotal)
            totalSpentView.addSubview(grandTotalAmount)
            
            return totalSpentView
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 1:
            // recent orders
            let cell = tableView.dequeueReusableCellWithIdentifier(customerDetailsRecentOrdersCellIdentifier) as! CustomerDetailsRecentOrdersCell
            
            return cell
            
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            // user info and contact info
            return navigationHeight
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            // recent orders
            return navigationHeight
        default:
            return 0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // user info and contact info
            return 2
        case 1:
            // recent orders
            return recentOrders.count
        default:
            fatalError("Unknown section returned in CustomerDetailsViewController")
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
                fatalError("Unknown row returned in CustomerDetailsViewController")
            }
        case 1:
            return 72.0
        default:
            fatalError("Unknown section returned in CustomerDetailsViewController")
        }
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

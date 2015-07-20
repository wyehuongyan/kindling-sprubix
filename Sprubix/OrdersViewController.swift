//
//  OrdersViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 12/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class OrdersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var toolBarView: UIView!
    var button1: UIButton! // active (processing, shipping requested)
    var button2: UIButton! // fulfilled (shipping scheduled, shipping on delivery, shipping delivered)
    var button3: UIButton! // cancelled
    var buttonLine: UIView!
    var currentChoice: UIButton!
    
    // table view
    var orders: [NSDictionary] = [NSDictionary]()
    let orderCellIdentifier: String = "OrderCell"
    @IBOutlet var ordersTableView: UITableView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray

        ordersTableView.dataSource = self
        ordersTableView.delegate = self
        
        // get rid of line seperator for empty cells
        ordersTableView.backgroundColor = sprubixGray
        ordersTableView.tableFooterView = UIView(frame: CGRectZero)
        
        initToolBar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        retrieveUserOrders()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Orders"
        
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
        var buttonWidth = screenWidth / 3
        
        button1 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button1.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: toolbarHeight)
        button1.backgroundColor = UIColor.whiteColor()
        //button1.setImage(UIImage(named: "profile-myoutfits"), forState: UIControlState.Normal)
        button1.setTitle("Active", forState: UIControlState.Normal)
        button1.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button1.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //button1.setImage(UIImage(named: "profile-myoutfits"), forState: UIControlState.Selected)
        button1.tintColor = UIColor.lightGrayColor()
        button1.autoresizesSubviews = true
        button1.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button1.exclusiveTouch = true
        button1.addTarget(self, action: "activeOrdersPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        button2 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button2.frame = CGRect(x: buttonWidth, y: 0, width: buttonWidth, height: toolbarHeight)
        button2.backgroundColor = UIColor.whiteColor()
        //button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Normal)
        button2.setTitle("Fulfilled", forState: UIControlState.Normal)
        button2.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button2.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Selected)
        button2.tintColor = UIColor.lightGrayColor()
        button2.autoresizesSubviews = true
        button2.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button2.exclusiveTouch = true
        button2.addTarget(self, action: "fulfilledOrdersPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        button3 = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button3.frame = CGRect(x: buttonWidth * 2, y: 0, width: buttonWidth, height: toolbarHeight)
        button3.backgroundColor = UIColor.whiteColor()
        //button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Normal)
        button3.setTitle("Cancelled", forState: UIControlState.Normal)
        button3.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button3.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //button2.setImage(UIImage(named: "profile-mycloset"), forState: UIControlState.Selected)
        button3.tintColor = UIColor.lightGrayColor()
        button3.autoresizesSubviews = true
        button3.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        button3.exclusiveTouch = true
        button3.addTarget(self, action: "cancelledOrdersPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        toolBarView.addSubview(button1)
        toolBarView.addSubview(button2)
        toolBarView.addSubview(button3)
        
        // set when button is selected
        buttonLine = UIView(frame: CGRect(x: 0, y: button1.frame.height - 2.0, width: button1.frame.width, height: 2))
        buttonLine.backgroundColor = sprubixColor
        
        // button 1 is initially selected
        button1.addSubview(buttonLine)
        button1.tintColor = sprubixColor
    }
    
    func retrieveUserOrders() {
        // REST call to server to retrieve user orders
        manager.GET(SprubixConfig.URL.api + "/orders",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.orders = responseObject["data"] as! [NSDictionary]
                
                self.ordersTableView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func retrieveShopOrders() {
        
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(orderCellIdentifier, forIndexPath: indexPath) as! OrderCell
        
        let order = orders[indexPath.row] as NSDictionary
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String
        let user = order["user"] as! NSDictionary

        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            let shopOrders = order["shop_orders"] as! [NSDictionary]
            
            cell.username.text = shopOrders.count > 1 ? "\(shopOrders.count) shops" : "\(shopOrders.count) shop"
        } else {
            // shop
            let username = user["username"] as! String
            
            cell.username.text = username
        }
        
        let totalPrice = order["total_price"] as! String
        let orderNumber = order["uid"] as! String
        let createdAt = order["created_at"] as! String

        cell.price.text = "$\(totalPrice)"
        cell.orderNumber.text = "#\(orderNumber)"
        cell.dateTime.text = createdAt
        
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let order = orders[indexPath.row] as NSDictionary
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            // // show all shop orders under this user order
            let shopOrdersViewController = UIStoryboard.shopOrdersViewController()
            shopOrdersViewController!.shopOrders = order["shop_orders"] as! [NSDictionary]
            
            self.navigationController?.pushViewController(shopOrdersViewController!, animated: true)
        } else {
            // shop
        }
    }

    // tool bar button callbacks
    func activeOrdersPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
        }
    }
    
    func fulfilledOrdersPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
        }
    }
    
    func cancelledOrdersPressed(sender: UIButton) {
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
        button3.tintColor = UIColor.lightGrayColor()
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

//
//  OrdersViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 12/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import DZNEmptyDataSet

class OrdersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet var toolBarView: UIView!
    var button1: UIButton! // active (processing, shipping requested)
    var button2: UIButton! // fulfilled (shipping scheduled, shipping on delivery, shipping delivered)
    var button3: UIButton! // cancelled
    var buttonLine: UIView!
    var currentChoice: UIButton!
    
    var refreshControl: UIRefreshControl!
    var activityView: UIActivityIndicatorView!
    
    // table view
    var orders: [NSDictionary] = [NSDictionary]()
    let orderCellIdentifier: String = "OrderCell"
    @IBOutlet var ordersTableView: UITableView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    // formatted orders
    var createdAtDates: [String] = [String]()
    var dateOrdersDict: NSMutableDictionary = NSMutableDictionary()
    
    var activeStatuses = [1, 2, 6]
    var fulfilledStatuses = [3, 4]
    var cancelledStatuses = [5, 7]
    
    var currentOrderStatus: NSArray!
    var prevOrderStatus: NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray

        ordersTableView.dataSource = self
        ordersTableView.delegate = self
        
        // get rid of line seperator for empty cells
        ordersTableView.backgroundColor = sprubixGray
        ordersTableView.tableFooterView = UIView(frame: CGRectZero)
        
        currentOrderStatus = activeStatuses
        
        initToolBar()
        
        // empty dataset
        ordersTableView.emptyDataSetSource = self
        ordersTableView.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        
        retrieveOrders()
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
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: screenHeight / 3 - activityViewWidth / 2, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = sprubixColor
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        ordersTableView.insertSubview(refreshControl, atIndex: 0)
        refreshControl.endRefreshing()
    }
    
    func refresh(sender: AnyObject) {
        retrieveOrders()
    }
    
    func retrieveOrders() {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            retrieveUserOrders()
        } else {
            // shop
            retrieveShopOrders()
        }
    }
    
    func retrieveUserOrders() {
        if orders.count <= 0 {
            activityView.startAnimating()
        }
        
        // REST call to server to retrieve user orders
        manager.POST(SprubixConfig.URL.api + "/orders/user",
            parameters: [
                "order_status_ids": currentOrderStatus
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.orders = responseObject["data"] as! [NSDictionary]
                
                self.formatOrders()
                self.ordersTableView.reloadData()
                
                self.activityView.stopAnimating()
                self.refreshControl.endRefreshing()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                self.activityView.stopAnimating()
                self.refreshControl.endRefreshing()
        })
    }
    
    func retrieveShopOrders() {
        if orders.count <= 0 {
            activityView.startAnimating()
        }
        
        // REST call to server to retrieve shop orders
        manager.POST(SprubixConfig.URL.api + "/orders/shop",
            parameters: [
                "order_status_ids": currentOrderStatus
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.orders = responseObject["data"] as! [NSDictionary]
                
                self.formatOrders()
                self.ordersTableView.reloadData()
                
                self.activityView.stopAnimating()
                self.refreshControl.endRefreshing()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                self.activityView.stopAnimating()
                self.refreshControl.endRefreshing()
        })
    }
    
    func formatOrders() {
        // arrange into (createdAtDate, [order]) dictionary
        // createdAtDates are recorded in [createdAtDate] array in desc order
        
        createdAtDates.removeAll()
        dateOrdersDict.removeAllObjects()
        
        for order in orders {
            let createdAtDatesDict = order["created_at_custom_format"] as! NSDictionary
            
            let createdAtHumanDate = createdAtDatesDict["created_at_date"] as! String
            
            // check if exists in dict
            var ordersForDate: [NSDictionary]? = dateOrdersDict.objectForKey(createdAtHumanDate) as? [NSDictionary]
            
            if ordersForDate == nil {
                // create new array
                ordersForDate = [NSDictionary]()
                createdAtDates.append(createdAtHumanDate)
            }
            
            ordersForDate?.append(order)
            
            // add date into createdAtDates array
            dateOrdersDict.setObject(ordersForDate!, forKey: createdAtHumanDate)
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(orderCellIdentifier, forIndexPath: indexPath) as! OrderCell
        
        let createdAtDate = createdAtDates[indexPath.section] as String
        let dateOrders = dateOrdersDict[createdAtDate] as! [NSDictionary]
        
        let order = dateOrders[indexPath.row] as NSDictionary
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String

        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            let shopOrders = order["shop_orders"] as! [NSDictionary]
            
            cell.username.text = shopOrders.count > 1 ? "\(shopOrders.count) shops" : "\(shopOrders.count) shop"
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
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return createdAtDates.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let createdAtDate = createdAtDates[section] as String
        
        return (dateOrdersDict[createdAtDate] as! [NSDictionary]).count
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let createdAtDateLabelContainer = UIView(frame: CGRectMake(0, 0, screenWidth, 25))
        createdAtDateLabelContainer.backgroundColor = sprubixLightGray
        
        let createdAtDateLabel = UILabel(frame: CGRectMake(10, 0, screenWidth - 10, 25))
        
        let createdAtDate = createdAtDates[section] as String
        
        createdAtDateLabel.backgroundColor = sprubixLightGray
        createdAtDateLabel.text = createdAtDate
        createdAtDateLabel.textColor = UIColor.darkGrayColor()
        createdAtDateLabel.font = UIFont.systemFontOfSize(14.0)
        
        createdAtDateLabelContainer.addSubview(createdAtDateLabel)
        
        return createdAtDateLabelContainer
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let createdAtDate = createdAtDates[indexPath.section] as String
        let dateOrders = dateOrdersDict[createdAtDate] as! [NSDictionary]
        
        let order = dateOrders[indexPath.row] as NSDictionary
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            // // show all shop orders under this user order
            let shopOrdersViewController = UIStoryboard.shopOrdersViewController()

            var shopOrderIds = [Int]()
            
            for shopOrder in order["shop_orders"] as! [NSDictionary] {
                let shopOrderId = shopOrder["id"] as! Int
                
                shopOrderIds.append(shopOrderId)
            }
            
            shopOrdersViewController!.shopOrderIds = shopOrderIds
            
            self.navigationController?.pushViewController(shopOrdersViewController!, animated: true)
        } else {
            // shop
            // go straight to shop order details
            let shopOrder = orders[indexPath.row] as NSDictionary
            
            let shopOrderDetailsViewController = UIStoryboard.shopOrderDetailsViewController()
            shopOrderDetailsViewController!.orderNum = shopOrder["uid"] as! String
            shopOrderDetailsViewController!.shopOrder = shopOrder.mutableCopy() as! NSMutableDictionary
            
            self.navigationController?.pushViewController(shopOrderDetailsViewController!, animated: true)
        }
    }

    // tool bar button callbacks
    func activeOrdersPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            prevOrderStatus = currentOrderStatus
            currentOrderStatus = activeStatuses
            
            orders.removeAll()
            retrieveOrders()
            
            // Mixpanel - Viewed Orders, Active
            mixpanel.track("Viewed Orders", properties: [
                "Source": "Orders View",
                "Tab": "Active"
            ])
            // Mixpanel - End
        }
    }
    
    func fulfilledOrdersPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            prevOrderStatus = currentOrderStatus
            currentOrderStatus = fulfilledStatuses

            orders.removeAll()
            retrieveOrders()
            
            // Mixpanel - Viewed Orders, Fulfilled
            mixpanel.track("Viewed Orders", properties: [
                "Source": "Orders View",
                "Tab": "Fulfilled"
            ])
            // Mixpanel - End
        }
    }
    
    func cancelledOrdersPressed(sender: UIButton) {
        if sender != currentChoice {
            deselectAllButtons()
            
            currentChoice = sender
            sender.addSubview(buttonLine)
            sender.tintColor = sprubixColor
            
            prevOrderStatus = currentOrderStatus
            currentOrderStatus = cancelledStatuses
            
            orders.removeAll()
            retrieveOrders()
            
            // Mixpanel - Viewed Orders, Cancelled
            mixpanel.track("Viewed Orders", properties: [
                "Source": "Orders View",
                "Tab": "Cancelled"
            ])
            // Mixpanel - End
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
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String = ""
        let shoppable_type: String = (defaults.objectForKey("userData")!.objectForKey("shoppable_type") as! String).componentsSeparatedByString("\\").last!
        
        switch shoppable_type {
        case "Shopper":
            if currentOrderStatus == activeStatuses {
                text = "\nItems awaiting seller's actions"
            }
            else if currentOrderStatus == fulfilledStatuses {
                text = "\nItems that are on the way to you"
            }
            else if currentOrderStatus == cancelledStatuses {
                text = "\nItems that were cancelled"
            }
            
        case "Shop":
            if currentOrderStatus == activeStatuses {
                text = "\nItems awaiting your actions"
            }
            else if currentOrderStatus == fulfilledStatuses {
                text = "\nItems on the way to your customers"
            }
            else if currentOrderStatus == cancelledStatuses {
                text = "\nItems that were cancelled"
            }
        
        default:
            break
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
        let shoppable_type: String = (defaults.objectForKey("userData")!.objectForKey("shoppable_type") as! String).componentsSeparatedByString("\\").last!
        
        switch shoppable_type {
        case "Shopper":
            if currentOrderStatus == activeStatuses {
                text = "When you checked out an item, you'll see it here."
            }
            else if currentOrderStatus == fulfilledStatuses {
                text = "When the seller sent out the item, you'll see it here."
            }
            else if currentOrderStatus == cancelledStatuses {
                text = "When an item is cancelled, you'll see it here."
            }
            
        case "Shop":
            if currentOrderStatus == activeStatuses {
                text = "When you have items to be fulfilled, you'll see it here."
            }
            else if currentOrderStatus == fulfilledStatuses {
                text = "When you sent out an item, you'll see it here."
            }
            else if currentOrderStatus == cancelledStatuses {
                text = "When an item is cancelled, you'll see it here."
            }
        
        default:
            break
        }   
        
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
        var image: UIImage!
        
        if currentOrderStatus == activeStatuses {
            image = UIImage(named: "emptyset-orders-active")
        }
        else if currentOrderStatus == fulfilledStatuses {
            image = UIImage(named: "emptyset-orders-fulfilled")
        }
        else if currentOrderStatus == cancelledStatuses {
            image = UIImage(named: "emptyset-orders-cancelled")
        }
        
        return image
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
}

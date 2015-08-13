//
//  ShopOrdersViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 19/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class ShopOrdersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var shopOrders: [NSDictionary] = [NSDictionary]()
    let orderCellIdentifier: String = "OrderCell"
    @IBOutlet var shopOrdersTableView: UITableView!
    
    var activityView: UIActivityIndicatorView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var shopOrderIds: [Int] = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        shopOrdersTableView.dataSource = self
        shopOrdersTableView.delegate = self
        
        // get rid of line seperator for empty cells
        shopOrdersTableView.backgroundColor = sprubixGray
        shopOrdersTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: screenHeight / 3 - activityViewWidth / 2, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        retrieveUserShopOrders()
    }
    
    func retrieveUserShopOrders() {
        if shopOrders.count <= 0 {
            activityView.startAnimating()
        }
        
        // REST call to server to retrieve shop orders
        manager.POST(SprubixConfig.URL.api + "/orders/shop",
            parameters: [
                "shop_order_ids": shopOrderIds
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                self.shopOrders = responseObject["data"] as! [NSDictionary]
                self.shopOrdersTableView.reloadData()
                
                self.activityView.stopAnimating()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                self.activityView.stopAnimating()
        })
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Ordered From"
        
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
        let cell = tableView.dequeueReusableCellWithIdentifier(orderCellIdentifier, forIndexPath: indexPath) as! OrderCell
        
        let shopOrder = shopOrders[indexPath.row] as NSDictionary
        let shop = shopOrder["user"] as! NSDictionary
        let shopUsername = shop["username"] as! String
        let orderNumber = shopOrder["uid"] as! String
        let createdAt = shopOrder["created_at"] as! String
        let totalPrice = shopOrder["total_price"] as! String
        let orderStatusId = shopOrder["order_status_id"] as! Int
        
        cell.username.text = shopUsername
        cell.price.text = "$\(totalPrice)"
        cell.orderNumber.text = "#\(orderNumber)"
        cell.dateTime.text = createdAt
        cell.orderStatusId = orderStatusId
        cell.setStatusImage()
        
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shopOrders.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let shopOrder = shopOrders[indexPath.row] as NSDictionary
        
        let shopOrderDetailsViewController = UIStoryboard.shopOrderDetailsViewController()
        shopOrderDetailsViewController!.orderNum = shopOrder["uid"] as! String
        shopOrderDetailsViewController!.shopOrder = shopOrder.mutableCopy() as! NSMutableDictionary
        
        self.navigationController?.pushViewController(shopOrderDetailsViewController!, animated: true)
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

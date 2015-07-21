//
//  CustomerDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 21/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CustomerDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var recentOrders: [NSDictionary] = [NSDictionary]()
    
    let orderDetailsUserCellIdentifier = "OrderDetailsUserCell"
    let orderDetailsContactCellIdentifier = "OrderDetailsContactCell"
    let orderCellIdentifier: String = "OrderCell"
    
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
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Customer"
        
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
                
                return cell
            case 1:
                // OrderDetailsContactCell
                let cell = tableView.dequeueReusableCellWithIdentifier(orderDetailsContactCellIdentifier, forIndexPath: indexPath) as! OrderDetailsContactCell
                
                return cell
            default:
                fatalError("Unknown row returned in ShopOrderDetailsViewController")
            }
        case 1:
            // recent orders
            let cell = tableView.dequeueReusableCellWithIdentifier(orderCellIdentifier, forIndexPath: indexPath) as! OrderCell

            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        default:
            fatalError("Unknown section returned in CustomerDetailsViewController")
        }
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

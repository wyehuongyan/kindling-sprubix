//
//  DeliveryAddressesViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 5/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import DZNEmptyDataSet
import TSMessages

class DeliveryAddressesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    let deliveryAddressCellIdentifier: String = "DeliveryAddressCell"
    @IBOutlet var deliveryAddressesTableView: UITableView!
    
    var deliveryAddresses: [NSDictionary] = [NSDictionary]()
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        deliveryAddressesTableView.dataSource = self
        deliveryAddressesTableView.delegate = self
        deliveryAddressesTableView.backgroundColor = sprubixGray
        
        // empty dataset
        deliveryAddressesTableView.emptyDataSetSource = self
        deliveryAddressesTableView.emptyDataSetDelegate = self
        
        // get rid of line seperator for empty cells
        deliveryAddressesTableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        retrieveDeliveryAddresses()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Delivery Addresses"
        
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
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("add", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "addDeliveryAddressTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func retrieveDeliveryAddresses() {
        // REST call to server to retrieve user shipping address
        manager.GET(SprubixConfig.URL.api + "/shipping/addresses",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.deliveryAddresses = responseObject as! [NSDictionary]
                self.deliveryAddressesTableView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
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

    // UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(deliveryAddressCellIdentifier, forIndexPath: indexPath) as! DeliveryAddressCell
        
        switch indexPath.section {
        case 0:
            // current
            switch indexPath.row {
            case 0:
                let deliveryAddress = deliveryAddresses[indexPath.row] as NSDictionary
                
                let deliveryAddressId = deliveryAddress["id"] as! Int
                let address1 = deliveryAddress["address_1"] as! String
                var address2: String? = deliveryAddress["address_2"] as? String
                let postalCode = deliveryAddress["postal_code"] as! String
                let country = deliveryAddress["country"] as! String
                
                var deliveryAddressText = address1
                
                if address2 != nil {
                    deliveryAddressText += "\n\(address2!)"
                }
                
                deliveryAddressText += "\n\(postalCode)\n\(country)"
                
                cell.deliveryAddress.text = deliveryAddressText
                cell.editDeliveryAction = { Void in
                    
                    let deliveryAddressesDetailsViewController = DeliveryAddressesDetailsViewController()
                    deliveryAddressesDetailsViewController.shippingAddressesCount = self.deliveryAddresses.count
                    deliveryAddressesDetailsViewController.deliveryAddress = deliveryAddress
                    
                    self.navigationController?.pushViewController(deliveryAddressesDetailsViewController, animated: true)
                    
                    return
                }
                
                cell.deleteDeliveryAction = { Void in
                    
                    var alert = UIAlertController(title: "Confirm delete?", message: "This action cannot be undone", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.view.tintColor = sprubixColor
                    
                    // Yes
                    alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { action in

                        // REST to server to delete delivery address
                        self.deleteDeliveryAddress(deliveryAddressId)
                    }))
                    
                    // No
                    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    return
                }
                
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                
                return cell
            default:
                fatalError("Unknown row returned for section 0")
            }
        case 1:
            // others
            let deliveryAddress = deliveryAddresses[indexPath.row + 1] as NSDictionary
            
            let deliveryAddressId = deliveryAddress["id"] as! Int
            let address1 = deliveryAddress["address_1"] as! String
            var address2: String? = deliveryAddress["address_2"] as? String
            let postalCode = deliveryAddress["postal_code"] as! String
            let country = deliveryAddress["country"] as! String
            
            var deliveryAddressText = address1
            
            if address2 != nil {
                deliveryAddressText += "\n\(address2!)"
            }
            
            deliveryAddressText += "\n\(postalCode)\n\(country)"
            
            cell.deliveryAddress.text = deliveryAddressText
            cell.editDeliveryAction = { Void in
                
                let deliveryAddressesDetailsViewController = DeliveryAddressesDetailsViewController()
                deliveryAddressesDetailsViewController.shippingAddressesCount = self.deliveryAddresses.count
                deliveryAddressesDetailsViewController.deliveryAddress = deliveryAddress
                
                self.navigationController?.pushViewController(deliveryAddressesDetailsViewController, animated: true)
                
                return
            }
            
            cell.deleteDeliveryAction = { Void in
                var alert = UIAlertController(title: "Confirm delete?", message: "This action cannot be undone", preferredStyle: UIAlertControllerStyle.Alert)
                alert.view.tintColor = sprubixColor
                
                // Yes
                alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { action in

                    // REST to server to delete delivery address
                    self.deleteDeliveryAddress(deliveryAddressId)
                }))
                
                // No
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
                
                return
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return cell
        default:
            fatalError("Unknown section returned")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if deliveryAddresses.count > 1 {
            switch section {
            case 0:
                return 1
            case 1:
                return deliveryAddresses.count - 1
            default:
                return 0
            }
        } else {
            return deliveryAddresses.count
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return deliveryAddresses.count > 1 ? 2 : 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if deliveryAddresses.count > 0 {
            switch section {
            case 0:
                return "Current Address"
            case 1:
                return nil
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }
    
    func deleteDeliveryAddress(deliveryAddressId: Int) {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            // REST call to server to delete user shipping address
            manager.DELETE(SprubixConfig.URL.api + "/shipping/address/\(deliveryAddressId)",
                parameters: [
                    "owner_id": userId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    var status = responseObject["status"] as! String
                    var automatic: NSTimeInterval = 0
                    
                    if status == "200" {
                        // success
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Delivery address deleted", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                        self.retrieveDeliveryAddresses()
                    } else {
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    // nav bar button callbacks
    func addDeliveryAddressTapped(sender: UIBarButtonItem) {
        let deliveryAddressesDetailsViewController = DeliveryAddressesDetailsViewController()
        deliveryAddressesDetailsViewController.shippingAddressesCount = deliveryAddresses.count
        
        self.navigationController?.pushViewController(deliveryAddressesDetailsViewController, animated: true)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

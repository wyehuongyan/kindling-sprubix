//
//  DeliveryOptionsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 24/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import AFNetworking
import TSMessages

class DeliveryOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var options: [NSDictionary] = [NSDictionary]()
    let deliveryOptionCellIdentifier: String = "DeliveryOptionCell"
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    @IBOutlet var deliveryOptionsTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        // get rid of line seperator for empty cells
        deliveryOptionsTable.backgroundColor = sprubixGray
        deliveryOptionsTable.tableFooterView = UIView(frame: CGRectZero)
        
        // empty dataset
        deliveryOptionsTable.emptyDataSetSource = self
        deliveryOptionsTable.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        retrieveDeliveryOptions()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Delivery Options"
        
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
        nextButton.addTarget(self, action: "addDeliveryOptionTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func retrieveDeliveryOptions() {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            manager.POST(SprubixConfig.URL.api + "/delivery/options",
                parameters: [
                    "user_id": userId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    self.options = responseObject["data"] as! [NSDictionary]
                    
                    self.deliveryOptionsTable.reloadData()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "\nWays to deliver items to your customers"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "When you add a delivery option, you'll see it here."
        
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
        return UIImage(named: "emptyset-delivery-options")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(deliveryOptionCellIdentifier, forIndexPath: indexPath) as! DeliveryOptionCell
        
        let option = options[indexPath.row] as NSDictionary
        
        var price = option["price"] as! String
        var estimatedTime = option["estimated_time"] as! Int
        var name = option["name"] as! String
        var title = "\(name) (\(estimatedTime) day)"
        
        if estimatedTime > 1 {
            title = "\(name) (\(estimatedTime) days)"
        }
        
        cell.deliveryOptionName.text = title
        cell.deliveryOptionPrice.text = "$\(price)"
        
        cell.editDeliveryAction = { Void in
            
            let deliveryOptionsDetailsViewController = DeliveryOptionsDetailsViewController()
            
            deliveryOptionsDetailsViewController.deliveryOption = option
            
            self.navigationController?.pushViewController(deliveryOptionsDetailsViewController, animated: true)
            
            return
        }
        
        cell.deleteDeliveryAction = { Void in

            var alert = UIAlertController(title: "Confirm delete?", message: "This action cannot be undone", preferredStyle: UIAlertControllerStyle.Alert)
            alert.view.tintColor = sprubixColor
            
            // Yes
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { action in
                
                self.deleteDeliveryOption(option)
            }))
            
            // No
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    private func deleteDeliveryOption(option: NSDictionary) {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            let deliveryOptionId = option["id"] as! Int
            
            manager.DELETE(SprubixConfig.URL.api + "/delivery/option/\(deliveryOptionId)",
                parameters: [
                    "owner_id": userId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    // refresh table
                    self.retrieveDeliveryOptions()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    // nav bar button callbacks
    func addDeliveryOptionTapped(sender: UIBarButtonItem) {
        // check if user is verified
        manager.GET(SprubixConfig.URL.api + "/user/verified",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                var response = responseObject as! NSDictionary
                var verified: Bool? = response["verified"] as? Bool
                
                if verified != nil && verified! {
                    let deliveryOptionsDetailsViewController = DeliveryOptionsDetailsViewController()
                    
                    self.navigationController?.pushViewController(deliveryOptionsDetailsViewController, animated: true)
                } else {
                    TSMessage.showNotificationInViewController(
                        TSMessage.defaultViewController(),
                        title: "Please Verify Your Email",
                        subtitle: "This is to ensure order information is sent to a valid email address.",
                        image: nil,
                        type: TSMessageNotificationType.Warning,
                        duration: 3,
                        callback: nil,
                        buttonTitle: nil,
                        buttonCallback: nil,
                        atPosition: TSMessageNotificationPosition.Bottom,
                        canBeDismissedByUser: true)
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

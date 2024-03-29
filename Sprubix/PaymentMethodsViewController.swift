//
//  PaymentMethodsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import AFNetworking
import TSMessages
import MRProgress

class PaymentMethodsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet var paymentMethodTableView: UITableView!
    let paymentMethodCellIdentifier: String = "PaymentMethodCell"
    
    var paymentMethods: [NSDictionary] = [NSDictionary]()
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    // loading overlay
    var overlay: MRProgressOverlayView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        paymentMethodTableView.backgroundColor = sprubixGray
        
        // empty dataset
        paymentMethodTableView.emptyDataSetSource = self
        paymentMethodTableView.emptyDataSetDelegate = self
        
        // get rid of line seperator for empty cells
        paymentMethodTableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
     
        initNavBar()
        retrievePaymentMethods()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Payment Methods"
        
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
        nextButton.addTarget(self, action: "addPaymentMethodTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func retrievePaymentMethods() {
        // REST call to server to retrieve user payment methods
        manager.GET(SprubixConfig.URL.api + "/billing/payments",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.paymentMethods = responseObject as! [NSDictionary]
                
                self.paymentMethodTableView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(paymentMethodCellIdentifier, forIndexPath: indexPath) as! PaymentMethodCell
        
        switch indexPath.section {
        case 0:
            // current
            switch indexPath.row {
            case 0:
                let paymentMethod = paymentMethods[indexPath.row] as NSDictionary
                
                let paymentMethodId = paymentMethod["id"] as! Int
                let imageString = paymentMethod["image"] as! String
                let redactedCartNum = paymentMethod["redacted_card_num"] as! Int
                let cardType = paymentMethod["card_type"] as! String
                
                cell.paymentMethodImage.setImageWithURL(NSURL(string: imageString))
                
                cell.paymentMethodName.text = "\(cardType) ending with ••• \(redactedCartNum)"
                
                cell.deletePaymentMethodAction = { Void in
                    var alert = UIAlertController(title: "Confirm delete?", message: "This action cannot be undone", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.view.tintColor = sprubixColor
                    
                    // Yes
                    alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { action in
                        
                        // REST to server to delete delivery address
                        self.deletePaymentMethod(paymentMethodId)
                    }))
                    
                    // No
                    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    return
                }
                
                cell.makeDefaultButton.enabled = false
                cell.makeDefaultButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
                
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                
                return cell
            default:
                fatalError("Unknown row returned for section 0")
            }
        case 1:
            // others
            let paymentMethod = paymentMethods[indexPath.row + 1] as NSDictionary
            
            let paymentMethodId = paymentMethod["id"] as! Int
            let imageString = paymentMethod["image"] as! String
            let redactedCartNum = paymentMethod["redacted_card_num"] as! Int
            let cardType = paymentMethod["card_type"] as! String
            
            cell.paymentMethodImage.setImageWithURL(NSURL(string: imageString))
            
            cell.paymentMethodName.text = "\(cardType) ending with ••• \(redactedCartNum)"
            
            cell.deletePaymentMethodAction = { Void in
                var alert = UIAlertController(title: "Confirm delete?", message: "This action cannot be undone", preferredStyle: UIAlertControllerStyle.Alert)
                alert.view.tintColor = sprubixColor
                
                // Yes
                alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { action in
                    
                    // REST to server to delete delivery address
                    self.deletePaymentMethod(paymentMethodId)
                }))
                
                // No
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
                
                return
            }
            
            cell.makeDefaultPaymentMethodAction = { Void in
                
                self.updatePaymentMethod(paymentMethodId)
                
                return
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return cell
        default:
            fatalError("Unknown section returned")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if paymentMethods.count > 1 {
            switch section {
            case 0:
                return 1
            case 1:
                return paymentMethods.count - 1
            default:
                return 0
            }
        } else {
            return paymentMethods.count
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return paymentMethods.count > 1 ? 2 : 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if paymentMethods.count > 0 {
            switch section {
            case 0:
                return "Default Payment Method"
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
        return 68.0
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "\nYour payment methods"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "When you add a payment method, you'll see it here."
        
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
        return UIImage(named: "emptyset-payment-methods")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
    
    func deletePaymentMethod(paymentMethodId: Int) {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            // init overlay
            self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Deleting...", mode: MRProgressOverlayViewMode.Indeterminate, animated: true)
            
            self.overlay.tintColor = sprubixColor
            
            // REST call to server to delete user shipping address
            manager.DELETE(SprubixConfig.URL.api + "/billing/payment/\(paymentMethodId)",
                parameters: [
                    "owner_id": userId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    var status = responseObject["status"] as! String
                    var automatic: NSTimeInterval = 0
                    
                    self.overlay.dismiss(true)
                    
                    if status == "200" {
                        // success
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Payment method deleted", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                        self.retrievePaymentMethods()
                    } else {
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    self.overlay.dismiss(true)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    func updatePaymentMethod(paymentMethodId: Int) {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        let makeDefault: Bool = true
        
        if userId != nil {
            // REST call to server to update user shipping address
            manager.POST(SprubixConfig.URL.api + "/billing/payment/edit/\(paymentMethodId)",
                parameters: [
                    "owner_id": userId!,
                    "is_default": makeDefault
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    var status = responseObject["status"] as! String
                    var automatic: NSTimeInterval = 0
                    
                    if status == "200" {
                        // success
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Payment method updated", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                        self.retrievePaymentMethods()
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
    func addPaymentMethodTapped(sender: UIBarButtonItem) {
        let paymentMethodsDetailsViewController = PaymentMethodsDetailsViewController()
        
        paymentMethodsDetailsViewController.paymentMethodsCount = paymentMethods.count
        
        self.navigationController?.pushViewController(paymentMethodsDetailsViewController, animated: true)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

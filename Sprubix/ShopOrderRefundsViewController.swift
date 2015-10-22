//
//  ShopOrderRefundsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 6/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import AFNetworking

class ShopOrderRefundsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, ShopOrderRefundProtocol {
    
    let shopOrderRefundCellIdentifier = "ShopOrderRefundCell"
    
    var refunds: [NSDictionary] = [NSDictionary]()
    var currentPage: Int = 0
    var lastPage: Int?
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var newRefundRequestable: Bool = false
    var checkRefundRequestable: Bool = true
    var fromShopOrderDetails: Bool = false
    var shopOrderId: Int!
    var shopOrder: NSMutableDictionary!
    
    @IBOutlet var refundsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        // get rid of line seperator for empty cells
        refundsTableView.backgroundColor = sprubixGray
        refundsTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // empty dataset
        refundsTableView.emptyDataSetSource = self
        refundsTableView.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        retrieveRefunds()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        refundsTableView.addInfiniteScrollingWithActionHandler({
            self.retrieveRefunds()
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
        newNavItem.title = "Refunds"
        
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
    
    func retrieveRefunds() {
        if fromShopOrderDetails != true {
            // GET page=2, page=3 and so on
            let nextPage = currentPage + 1
            
            if currentPage < lastPage || lastPage == nil {
                // REST call to server to update order status
                manager.GET(SprubixConfig.URL.api + "/user/refunds?page=\(nextPage)",
                    parameters: nil,
                    success: { (operation: AFHTTPRequestOperation!, responseObject:
                        AnyObject!) in
                        
                        var refunds = responseObject["data"] as! [NSDictionary]
                        self.currentPage = responseObject["current_page"] as! Int
                        self.lastPage = responseObject["last_page"] as? Int
                        
                        if self.refundsTableView.infiniteScrollingView != nil {
                            self.refundsTableView.infiniteScrollingView.stopAnimating()
                        }
                        
                        for refund in refunds {
                            self.refunds.append(refund)
                            
                            self.refundsTableView.layoutIfNeeded()
                            self.refundsTableView.beginUpdates()
                            
                            var nsPath = NSIndexPath(forRow: self.refunds.count - 1, inSection: 0)
                            self.refundsTableView.insertRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.Fade)
                            
                            self.refundsTableView.endUpdates()
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        if self.refundsTableView.infiniteScrollingView != nil {
                            self.refundsTableView.infiniteScrollingView.stopAnimating()
                        }
                })
            } else {
                if self.refundsTableView.infiniteScrollingView != nil {
                    self.refundsTableView.infiniteScrollingView.stopAnimating()
                }
            }
        } else {
            manager.POST(SprubixConfig.URL.api + "/order/shop/refunds",
                parameters: [
                    "shop_order_id": shopOrderId
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    if self.refundsTableView.infiniteScrollingView != nil {
                        self.refundsTableView.infiniteScrollingView.stopAnimating()
                    }
                    
                    var shopOrderRefunds = responseObject["data"] as! [NSDictionary]
                    
                    self.refunds = shopOrderRefunds
                    self.refundsTableView.reloadData()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    if self.refundsTableView.infiniteScrollingView != nil {
                        self.refundsTableView.infiniteScrollingView.stopAnimating()
                    }
            })
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let refund: NSDictionary = refunds[indexPath.row] as NSDictionary
        
        var shopOrderRefundDetailsViewController = UIStoryboard.shopOrderRefundDetailsViewController()
        
        shopOrderRefundDetailsViewController?.shopOrder = refund["shop_order"] as! NSMutableDictionary
        shopOrderRefundDetailsViewController?.existingRefund = refund
        shopOrderRefundDetailsViewController?.fromRefundView = true
        
        self.navigationController?.pushViewController(shopOrderRefundDetailsViewController!, animated: true)
        
        currentPage = 0
        lastPage = nil
        refunds.removeAll()
        refundsTableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return refunds.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(shopOrderRefundCellIdentifier, forIndexPath: indexPath) as! ShopOrderRefundCell
        
        let refund: NSDictionary = refunds[indexPath.row] as NSDictionary
        
        let refundUID = refund["uid"] as! String
        let refundCreatedAt = refund["created_at"] as! String
        let refundAmount = refund["refund_amount"] as! String
        let refundStatusId = refund["refund_status_id"] as! Int
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            let seller = refund["user"] as! NSDictionary
            let sellerUsername = seller["username"] as! String
            
            cell.username.text = sellerUsername
        } else {
            // shop
            let buyer = refund["buyer"] as! NSDictionary
            let buyerUsername = buyer["username"] as! String
            
            cell.username.text = buyerUsername
        }
        
        cell.orderNumber.text = "#\(refundUID)"
        cell.dateTime.text = refundCreatedAt
        cell.price.text = "$\(refundAmount)"
        
        cell.refundStatusId = refundStatusId
        cell.setStatusImage()
        
        if checkRefundRequestable && refundStatusId != 1 && refundStatusId != 2 {
            newRefundRequestable = true
        } else {
            newRefundRequestable = false
            checkRefundRequestable = false
        }
        
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if fromShopOrderDetails && newRefundRequestable {
            let footerViewContainer = UIView(frame: CGRectMake(0, 0, screenWidth, 72.0))
            
            footerViewContainer.backgroundColor = sprubixGray
            
            let requestForNewRefundButton = UIButton(frame: CGRectMake(0, 20.0, screenWidth, 52.0))
            
            let userData: NSDictionary? = defaults.dictionaryForKey("userData")
            let shoppableType: String? = userData!["shoppable_type"] as? String
            var titleText = ""
            
            if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
                // shopper
                // Request for Refund
                titleText = "Request for Refund"
                
            } else {
                // shop
                // Refund
                titleText = "Refund"
            }
            
            requestForNewRefundButton.setTitle(titleText, forState: UIControlState.Normal)
            requestForNewRefundButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
            requestForNewRefundButton.backgroundColor = UIColor.whiteColor()
            requestForNewRefundButton.addTarget(self, action: "requestForNewRefundPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            footerViewContainer.addSubview(requestForNewRefundButton)
            
            return footerViewContainer
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if fromShopOrderDetails && newRefundRequestable {
            return 72.0
        } else {
            return 0.0
        }
    }
    
    // button callbacks
    func requestForNewRefundPressed(sender: UIButton) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String
        var popupMessage = ""
        var titleText = ""
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            // Request for Refund
            popupMessage = "You have requested for a refund on item(s) from this order."
            
        } else {
            // shop
            // Refund
            popupMessage = "Setting this status will create a new refund ticket for this order."
        }
        
        var alert = UIAlertController(title: "Are you sure?", message: popupMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = sprubixColor
        
        // Yes
        alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: UIAlertActionStyle.Default, handler: { action in
            
            // show RefundRequestViewController and select items to refund
            let shopOrderRefundDetailsViewController = UIStoryboard.shopOrderRefundDetailsViewController()
            shopOrderRefundDetailsViewController?.shopOrder = self.shopOrder
            shopOrderRefundDetailsViewController?.delegate = self
            
            self.navigationController?.pushViewController(shopOrderRefundDetailsViewController!, animated: true)
        }))
        
        // No
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // ShopOrderRefundProtocol
    func setRequestable(newRefundRequestable: Bool) {
        self.newRefundRequestable = newRefundRequestable
        
        if self.newRefundRequestable == false {
            checkRefundRequestable = false
        }
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "\nItems on request for refund"
        
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
                text = "When you make a request for refund, you'll see it here."
            
        case "Shop":
                text = "When your customers make a request for refund, you'll see it here."
            
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
        return UIImage(named: "emptyset-refunds")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
}

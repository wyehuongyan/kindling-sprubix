//
//  RefundsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 6/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import AFNetworking

class RefundsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    let refundCellIdentifier = "RefundCell"
    
    var refunds: [NSDictionary] = [NSDictionary]()
    var currentPage: Int = 0
    var lastPage: Int?
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
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
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        refunds.removeAll()
        refundsTableView.reloadData()
        currentPage = 0
        lastPage = nil
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
                    
                    self.refundsTableView.infiniteScrollingView.stopAnimating()
                    
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
                    self.refundsTableView.infiniteScrollingView.stopAnimating()
            })
        } else {
            refundsTableView.infiniteScrollingView.stopAnimating()
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let refund: NSDictionary = refunds[indexPath.row] as NSDictionary
        
        var refundDetailsViewController = UIStoryboard.refundDetailsViewController()
        refundDetailsViewController?.shopOrder = refund["shop_order"] as! NSMutableDictionary
        refundDetailsViewController?.existingRefund = refund
        refundDetailsViewController?.fromRefundView = true
        
        self.navigationController?.pushViewController(refundDetailsViewController!, animated: true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return refunds.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(refundCellIdentifier, forIndexPath: indexPath) as! RefundCell
        
        let refund: NSDictionary = refunds[indexPath.row] as NSDictionary
        
        let refundUID = refund["uid"] as! String
        let refundCreatedAt = refund["created_at"] as! String
        let refundAmount = refund["refund_amount"] as! String
        let refundStatusId = refund["refund_status_id"] as! Int
        let seller = refund["user"] as! NSDictionary
        let sellerUsername = seller["username"] as! String
        
        cell.username.text = sellerUsername
        cell.orderNumber.text = "#\(refundUID)"
        cell.dateTime.text = refundCreatedAt
        cell.price.text = "$\(refundAmount)"
        
        cell.refundStatusId = refundStatusId
        cell.setStatusImage()
        
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
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
        return UIImage(named: "emptyset-refunds")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
}

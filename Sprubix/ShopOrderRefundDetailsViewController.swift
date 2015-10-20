//
//  ShopOrderRefundRefundDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import ActionSheetPicker_3_0
import AFNetworking
import TSMessages
import MRProgress

protocol ShopOrderRefundProtocol {
    func setRequestable(newRefundRequestable: Bool)
}

protocol ShopOrderUpdateProtocol {
    func updateShopOrder(shopOrder: NSMutableDictionary)
}

class ShopOrderRefundDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    var delegate: ShopOrderRefundProtocol?
    var updateDelegate: ShopOrderUpdateProtocol?
    
    var shopOrder: NSMutableDictionary!
    var existingRefund: NSDictionary?
    var fromRefundView: Bool = false
    
    let shopOrderRefundDetailsItemCellIdentifier = "ShopOrderRefundDetailsItemCell"
    let shopOrderRefundDetailsFooterCellIdentifier = "ShopOrderRefundDetailsFooterCell"
    let shopOrderRefundDetailsStatusCellIdentifier = "ShopOrderRefundDetailsStatusCell"
    let reasonPlaceholderText = "Reason for refund (optional)"
    
    // keyboard
    var tableTapGestureRecognizer: UITapGestureRecognizer!
    var makeKeyboardVisible = true
    var oldFrameRect: CGRect!
    var refundButton: UIButton!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var refundReason: String = ""
    var refundTitle: String = "Refund"
    
    var orderItems: [NSDictionary] = [NSDictionary]()
    var returnDict: NSMutableDictionary = NSMutableDictionary()
    var finalRefundAmount: String!
    var finalRefundPoints: Float!
    
    // loading overlay
    var overlay: MRProgressOverlayView!
    
    @IBOutlet var refundDetailsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        orderItems = shopOrder["cart_items"] as! [NSDictionary]
        
        initTableView()
        initRefundButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil)
        
        if existingRefund != nil {
            // set refund amount text field
            self.finalRefundAmount = existingRefund!["refund_amount"] as! String
            
            // set refund status
            let refundStatus = existingRefund!["refund_status"] as! NSDictionary
            
            let refundStatusName = refundStatus["name"] as! String
            
        }
        
        initNavBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    func initTableView() {
        // register method when tapped to hide keyboard
        tableTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tableTapped:")
        tableTapGestureRecognizer.enabled = false
        self.view.addGestureRecognizer(tableTapGestureRecognizer)
        
        oldFrameRect = CGRectMake(0, navigationHeight, screenWidth, refundDetailsTableView.frame.height)
        
        // get rid of line seperator for empty cells
        refundDetailsTableView.backgroundColor = sprubixGray
        refundDetailsTableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    func initRefundButton() {
        refundButton = UIButton(frame: CGRect(x: 0, y: screenHeight, width: screenWidth, height: navigationHeight))
        
        refundButton.backgroundColor = sprubixColor
        refundButton.titleLabel?.font = UIFont.boldSystemFontOfSize(18.0)
        
        if existingRefund != nil {
            var refundStatusId = existingRefund!["refund_status_id"] as! Int
            
            if refundStatusId == 1 {
                // 1 = requested for refund
                refundTitle = "Approve Refund"
                
                refundButton.addTarget(self, action: "approveRefundButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            } else {
                refundTitle = "Refund"
                
                refundButton.addTarget(self, action: "refundButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            }
        } else {
            refundTitle = "Refund"
            
            refundButton.addTarget(self, action: "refundButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        }
        
        refundButton.setTitle(refundTitle, forState: UIControlState.Normal)
        
        
        view.addSubview(refundButton)
    }
    
    func hideRefundButton() {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.9 , initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {

                self.refundButton.enabled = false
                self.refundButton.frame.origin.y = screenHeight
            
                // adjust table height
                self.refundDetailsTableView.frame.size.height = screenHeight - navigationHeight
            
            }, completion: { finished in
        })
    }
    
    func showRefundButton(refundAmount: String, refundPoints: String) {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.9 , initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            
                self.finalRefundAmount = refundAmount
                self.refundButton.setTitle("\(self.refundTitle) $\(refundAmount) + \(refundPoints)", forState: UIControlState.Normal)
                self.refundButton.enabled = true
                self.refundButton.frame.origin.y = screenHeight - navigationHeight
            
                // adjust table height
                self.refundDetailsTableView.frame.size.height = screenHeight - 2 * navigationHeight
            
            }, completion: { finished in
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
        
        var uid = shopOrder["uid"] as! String
        newNavItem.title = "Refund #\(uid)"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.exclusiveTouch = true
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        if fromRefundView {
            var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            nextButton.setTitle("view order", forState: UIControlState.Normal)
            nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
            nextButton.frame = CGRect(x: 0, y: 0, width: 90, height: 20)
            nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            nextButton.addTarget(self, action: "shopOrderTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            
            var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
            newNavItem.rightBarButtonItem = nextBarButtonItem
        }
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // order items
            let cell = tableView.dequeueReusableCellWithIdentifier(shopOrderRefundDetailsItemCellIdentifier, forIndexPath: indexPath) as! ShopOrderRefundDetailsItemCell
            
            let cartItems = shopOrder["cart_items"] as! [NSDictionary]
            let cartItem = cartItems[indexPath.row] as NSDictionary
            
            let piece = cartItem["piece"] as! NSDictionary
            let cartItemId = cartItem["id"] as! Int
            let payablePrice = cartItem["total_payable_price"] as! NSString
            let quantity = cartItem["quantity"] as! Int
            let returnedAmount = cartItem["returned"] as! Int
            let returnAmount = cartItem["return"] as! Int
            let size = cartItem["size"] as? String
            
            cell.name.text = piece["name"] as? String
            cell.price.text = String(format: "$%.2f", payablePrice.floatValue * Float(quantity))
            cell.size.text = "Size: \(size!)"
            
            var returnDictAmount = returnDict.objectForKey("\(cartItemId)") as? Int
            
            if returnDictAmount == nil {
                // key does not exist, add it to dict
                returnDict.setObject(returnAmount, forKey: "\(cartItemId)")
                
                returnDictAmount = returnDict.objectForKey("\(cartItemId)") as? Int
            }
            
            cell.returnInfo.text = "Ordered: \(quantity), Returned: \(returnedAmount), Return: \(returnDictAmount!)"
            
            // if there's nothing more to return, disable the cell
            if (quantity - returnedAmount <= 0) {
                // already requested
                cell.edit.alpha = 0.0
                cell.userInteractionEnabled = false
            }
            
            let pieceImagesString = piece["images"] as! NSString
            let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
            
            let thumbnailURLString = pieceImageDict["thumbnail"] as! String
            let pieceImageURL: NSURL = NSURL(string: thumbnailURLString)!
            
            cell.itemImageView.setImageWithURL(pieceImageURL)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            if existingRefund != nil {
                cell.edit.alpha = 0.0
                cell.userInteractionEnabled = false
            }
            
            return cell
            
        case 1:
            // refund details footer
            let cell = tableView.dequeueReusableCellWithIdentifier(shopOrderRefundDetailsFooterCellIdentifier, forIndexPath: indexPath) as! ShopOrderRefundDetailsFooterCell
            
            let totalPrice = shopOrder["total_price"] as! String
            let totalRefundedAmount = shopOrder["refunded_amount"] as! String
            let totalRefundableAmount = shopOrder["refundable_amount"] as! String
            let shippingRate = shopOrder["shipping_rate"] as! String
            
            cell.shippingRate.text = "$\(shippingRate)"
            cell.totalAmountRefundable.text = "$\(totalRefundableAmount)"
            cell.refundReason.delegate = self
            
            if existingRefund != nil {
                let existingRefundReason = existingRefund!["refund_reason"] as! String
                
                cell.refundReason.text = existingRefundReason != "" ? existingRefundReason : reasonPlaceholderText
                cell.refundReason.userInteractionEnabled = false
            }
            
            cell.refundPoints.enabled = false
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            let userData: NSDictionary? = defaults.dictionaryForKey("userData")
            let shoppableType: String? = userData!["shoppable_type"] as? String
            
            if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
                // shopper
                cell.refundAmount.enabled = false
            }
            
            let cartItems = shopOrder["cart_items"] as! [NSDictionary]
            var totalReturnRefundAmount: Float = 0
            var totalReturnRefundPoints: Float = 0
            
            for cartItem in cartItems {
                // loop through each cartItem 
                // // retrieve price of piece
                let cartItemId = cartItem["id"] as! Int
                let payablePrice = cartItem["total_payable_price"] as! NSString
                let quantity = cartItem["quantity"] as! Int
                let pointsApplied = cartItem["points_applied"] as! String
                let returnedAmount = cartItem["returned"] as! Int
                let returnableAmount = quantity - returnedAmount
                let pointsPerItem = ceil(pointsApplied.floatValue / Float(returnableAmount))
                
                var returnDictAmount = returnDict.objectForKey("\(cartItemId)") as? Int
                var returnRefundAmount: Float = 0
                var returnRefundPoints: Float = 0
                
                if returnDictAmount != nil {
                    returnRefundAmount = Float(returnDictAmount!) * payablePrice.floatValue
                    
                    returnRefundPoints = Float(returnDictAmount!) * pointsPerItem
                }
                
                totalReturnRefundAmount += returnRefundAmount
                totalReturnRefundPoints += returnRefundPoints
            }
            
            finalRefundAmount = "\(totalReturnRefundAmount)"
            finalRefundPoints = totalReturnRefundPoints
            
            // // if shop, can always see the button
            // // if shopper, and status == request for refund, cant see button
            if finalRefundAmount.floatValue > 0 {
                cell.refundAmount.text = String(format: "%.2f", totalReturnRefundAmount)
                cell.refundPoints.text = String(format: "%.0f pts", totalReturnRefundPoints)
                    
                if existingRefund != nil {
                    let refundStatus = existingRefund!["refund_status"] as! NSDictionary
                    
                    let refundStatusId = refundStatus["id"] as! Int
            
                    if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
                        // already has existing refund
                        hideRefundButton()
                    } else {
                        // shops only get to see the button
                        // if there's a request
                        if refundStatusId == 1 {
                            showRefundButton(cell.refundAmount.text, refundPoints: cell.refundPoints.text)
                        } else {
                            hideRefundButton()
                        }
                    }
                } else {
                    // there's no existing refund
                    // // shopper may ask for refund and shop may refund
                    showRefundButton(cell.refundAmount.text, refundPoints: cell.refundPoints.text)
                }
                
            } else {
                cell.refundAmount.text = ""
                cell.refundPoints.text = ""
                
                hideRefundButton()
            }
            
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier(shopOrderRefundDetailsStatusCellIdentifier, forIndexPath: indexPath) as! ShopOrderRefundDetailsStatusCell
            
            if existingRefund != nil {
                let refundStatus = existingRefund!["refund_status"] as! NSDictionary
                
                let refundStatusName = refundStatus["name"] as! String
                let refundStatusId = refundStatus["id"] as! Int
                
                cell.status.text = refundStatusName
                cell.refundStatusId = refundStatusId
                
                cell.setStatusImage()
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return cell
        default:
            fatalError("Unknown section returned at RefundDetailsViewController")
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            let cartItems = shopOrder["cart_items"] as! [NSDictionary]
            let cartItem = cartItems[indexPath.row] as NSDictionary
            
            let cartItemId = cartItem["id"] as! Int
            let quantity = cartItem["quantity"] as! Int
            let returnedAmount = cartItem["returned"] as! Int
            
            var returnableAmount = quantity - returnedAmount
            var returnableArray = [Int]()
            var returnDictAmount = returnDict.objectForKey("\(cartItemId)") as? Int
            var initialSelection = 0
            
            if returnableAmount > 0 {
                returnableArray.append(0)
                
                for var i = 0; i < returnableAmount; i++ {
                    returnableArray.append(i + 1)
                    
                    if (i + 1) == returnDictAmount {
                        initialSelection = i + 1
                    }
                }
            }
            
            // show actionsheet picker
            let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Quantity to Return", rows: returnableArray, initialSelection: initialSelection,
                doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                    
                    self.returnDict.setObject(selectedValue as! Int, forKey: "\(cartItemId)")
                    
                    self.refundDetailsTableView.reloadData()
                    
                }, cancelBlock: nil, origin: view)
            
            // custom done button
            let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
            
            doneButton.setTitleTextAttributes([
                NSForegroundColorAttributeName: sprubixColor,
                ], forState: UIControlState.Normal)
            
            picker.setDoneButton(doneButton)
            
            // custom cancel button
            var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            
            cancelButton.setTitle("X", forState: UIControlState.Normal)
            cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
            cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            
            picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
            
            picker.showActionSheetPicker()
        case 1:
            // do nothing
            break
        case 2:
            // do nothing
            break
        default:
            fatalError("Unknown section returned at RefundDetailsViewController")
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 100.0
        case 1:
            return 200.0
        case 2:
            return 52.0
        default:
            fatalError("Unknown section returned at RefundDetailsViewController")
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 2:
            var tempHeaderView = UIView(frame: CGRectMake(0, 0, screenWidth, 20.0))
            
            tempHeaderView.backgroundColor = sprubixGray
            
            return tempHeaderView
        default:
            return nil
        }

    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 2:
            return 20.0
        default:
            return 0.0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if existingRefund != nil  {
            return 3
        }
        
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return orderItems.count
        case 1:
            return 1
        case 2:
            return 1
        default:
            fatalError("Unknown section returned at RefundDetailsViewController")
        }
    }
    
    /**
    * Handler for keyboard change event
    */
    func keyboardWillChange(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        if makeKeyboardVisible {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                if self.orderItems.count > 1 {
                    self.refundDetailsTableView.frame.origin.y = self.oldFrameRect.origin.y - keyboardFrame.height
                }
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                        self.tableTapGestureRecognizer.enabled = true
                    }
            })
        } else {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.refundDetailsTableView.frame.origin.y = self.oldFrameRect.origin.y
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                        self.makeKeyboardVisible = true
                        self.tableTapGestureRecognizer.enabled = false
                    }
            })
        }
    }
    
    // Called when the user click on the view (outside the UITextField).
    func tableTapped(gesture: UITapGestureRecognizer) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }
    
    // UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView.text == reasonPlaceholderText {
            textView.text = ""
            textView.textColor = UIColor.darkGrayColor()
        }
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = reasonPlaceholderText
            textView.textColor = UIColor.lightGrayColor()
        }
        
        refundReason = textView.text
    }
    
    // button callbacks
    func approveRefundButtonPressed(sender: UIButton) {
        if existingRefund != nil {
            
            // alert view confirmation
            var formattedFinalRefundPoints = String(format: "%.0f", finalRefundPoints)
            var refundMessage = "This action cannot be undone. \n\nApprove Refund $\(finalRefundAmount) + \(formattedFinalRefundPoints) pts"
            var alert = UIAlertController(title: "Are you sure?", message: refundMessage, preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.view.tintColor = sprubixColor
            
            // Yes
            alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: UIAlertActionStyle.Default, handler: { action in
                
                // init overlay
                self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Processing...", mode: MRProgressOverlayViewMode.Indeterminate, animated: true)
                
                self.overlay.tintColor = sprubixColor
                
                let shopOrderRefundId = self.existingRefund!["id"] as! Int
                
                // REST call to server to update shopOrderRefund
                manager.POST(SprubixConfig.URL.api + "/refund/\(shopOrderRefundId)/approve",
                    parameters: [
                        "refund_amount": self.finalRefundAmount,
                        "refund_points": self.finalRefundPoints,
                        "return_cart_items": self.returnDict
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        var status = responseObject["status"] as! String
                        var automatic: NSTimeInterval = 0
                        self.overlay.dismiss(true)
                        
                        if status == "200" {
                            // success
                            TSMessage.showNotificationInViewController(TSMessage.defaultViewController(), title: "Success!", subtitle: "Refund Approved.", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                            
                            self.existingRefund = responseObject["shop_order_refund"] as? NSDictionary
                            self.refundDetailsTableView.reloadData()
                            
                            let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                            let shoppableType: String? = userData!["shoppable_type"] as? String
                            if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
                                // if is a shopper who just made a request
                                self.delegate?.setRequestable(false)
                            }
                            
                        } else if status == "500" {
                            // error exception
                            TSMessage.showNotificationInViewController(TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                            
                            println(responseObject)
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        self.overlay.dismiss(true)
                        var automatic: NSTimeInterval = 0
                        
                        // error exception
                        TSMessage.showNotificationInViewController(TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                })
            }))
            
            // No
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func refundButtonPressed(sender: UIButton) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let shoppableType: String? = userData!["shoppable_type"] as? String

        var formattedFinalRefundPoints = String(format: "%.0f", finalRefundPoints)
        var requestForRefund: Bool = false
        var refundMessage: String = "This action cannot be undone. \n\nRefund $\(finalRefundAmount) + \(formattedFinalRefundPoints) pts"
        var responseMessage: String = "Items refunded."
        
        if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
            // shopper
            requestForRefund = true
            refundMessage = "This action cannot be undone. \n\nRequest for Refund $\(finalRefundAmount) + \(formattedFinalRefundPoints) pts"
            
            responseMessage = "Request for refund has been sent."
        }
        
        var alert = UIAlertController(title: "Are you sure?", message: refundMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = sprubixColor
        
        // Yes
        alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: UIAlertActionStyle.Default, handler: { action in
            
            // init overlay
            self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Processing...", mode: MRProgressOverlayViewMode.Indeterminate, animated: true)
            
            self.overlay.tintColor = sprubixColor
            
            // refund confirmed
            let shopOrderId = self.shopOrder["id"] as! Int
            
            // REST call to server to create shop order refund
            manager.requestSerializer = AFJSONRequestSerializer()
            manager.responseSerializer = AFJSONResponseSerializer()
            manager.POST(SprubixConfig.URL.api + "/refund/create",
                parameters: [
                    "shop_order_id": shopOrderId,
                    "refund_amount": self.finalRefundAmount,
                    "refund_reason": self.refundReason != self.reasonPlaceholderText ? self.refundReason : "",
                    "refund_points": self.finalRefundPoints,
                    "return_cart_items": self.returnDict,
                    "request_for_refund": requestForRefund
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var status = responseObject["status"] as! String
                    var automatic: NSTimeInterval = 0
                    
                    self.overlay.dismiss(true)
                    
                    if status == "200" {
                        // success
                        TSMessage.showNotificationInViewController(TSMessage.defaultViewController(), title: "Success!", subtitle: responseMessage, image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                        self.existingRefund = responseObject["shop_order_refund"] as? NSDictionary
                        
                        self.refundDetailsTableView.reloadData()
                        self.delegate?.setRequestable(false)
                        
                    } else if status == "500" {
                        // error exception
                        TSMessage.showNotificationInViewController(TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                        println(responseObject)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    self.overlay.dismiss(true)
                    var automatic: NSTimeInterval = 0
                    
                    // error exception
                    TSMessage.showNotificationInViewController(TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
            })
        }))
        
        // No
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // nav bar button callbacks
    func shopOrderTapped(sender: UIBarButtonItem) {
        // REST call to server to retrieve shop orders
        manager.POST(SprubixConfig.URL.api + "/orders/shop",
            parameters: [
                "shop_order_ids": [shopOrder["id"] as! Int]
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var shopOrder = (responseObject["data"] as! [NSDictionary])[0].mutableCopy() as! NSMutableDictionary
                
                // go to shop order details view
                let shopOrderDetailsViewController = UIStoryboard.shopOrderDetailsViewController()
                shopOrderDetailsViewController!.orderNum = shopOrder["uid"] as! String
                shopOrderDetailsViewController!.shopOrder = shopOrder
                
                self.navigationController?.pushViewController(shopOrderDetailsViewController!, animated: true)
                
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func backTapped(sender: UIBarButtonItem) {
        if fromRefundView {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            // from shop order details view
            // reload shop order
            
            // REST call to server to retrieve shop orders
            manager.POST(SprubixConfig.URL.api + "/orders/shop",
                parameters: [
                    "shop_order_ids": [shopOrder["id"] as! Int]
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var shopOrder = (responseObject["data"] as! [NSDictionary])[0].mutableCopy() as! NSMutableDictionary
                    
                    self.updateDelegate?.updateShopOrder(shopOrder)
                    
                    self.navigationController?.popViewControllerAnimated(true)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
}

extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}

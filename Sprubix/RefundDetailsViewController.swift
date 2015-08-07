//
//  RefundDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import ActionSheetPicker_3_0

class RefundDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    var shopOrder: NSMutableDictionary!
    
    let refundDetailsItemCellIdentifier = "RefundDetailsItemCell"
    let refundDetailsFooterCellIdentifier = "RefundDetailsFooterCell"
    let reasonPlaceholderText = "Reason for refund (optional)"
    
    // keyboard
    var tableTapGestureRecognizer: UITapGestureRecognizer!
    var makeKeyboardVisible = true
    var oldFrameRect: CGRect!
    var refundButton: UIButton!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var titleText: String!
    
    var orderItems: [NSDictionary] = [NSDictionary]()
    var returnDict: NSMutableDictionary = NSMutableDictionary()
    var finalRefundAmount: String!
    
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
        
        initNavBar()
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
        refundButton.setTitle("Refund", forState: UIControlState.Normal)
        refundButton.addTarget(self, action: "refundButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(refundButton)
    }
    
    func hideRefundButton() {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.9 , initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {

                self.refundButton.enabled = false
                self.refundButton.frame.origin.y = screenHeight
            
            }, completion: { finished in
        })
    }
    
    func showRefundButton(refundAmount: String) {
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.9 , initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            
                self.finalRefundAmount = refundAmount
                self.refundButton.setTitle("Refund $\(refundAmount)", forState: UIControlState.Normal)
                self.refundButton.enabled = true
                self.refundButton.frame.origin.y = screenHeight - navigationHeight
            
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
        newNavItem.title = titleText
        
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
            // order items
            let cell = tableView.dequeueReusableCellWithIdentifier(refundDetailsItemCellIdentifier, forIndexPath: indexPath) as! RefundDetailsItemCell
            
            let cartItems = shopOrder["cart_items"] as! [NSDictionary]
            let cartItem = cartItems[indexPath.row] as NSDictionary
            
            let piece = cartItem["piece"] as! NSDictionary
            let cartItemId = cartItem["id"] as! Int
            let price = piece["price"] as! NSString
            let quantity = cartItem["quantity"] as! Int
            let returnedAmount = cartItem["returned"] as! Int
            let returnAmount = cartItem["return"] as! Int
            let size = cartItem["size"] as? String
            
            cell.name.text = piece["name"] as? String
            cell.price.text = String(format: "$%.2f", price.floatValue * Float(quantity))
            cell.size.text = "Size: \(size!)"
            
            var returnDictAmount = returnDict.objectForKey(cartItemId) as? Int
            
            if returnDictAmount == nil {
                // key does not exist, add it to dict
                returnDict.setObject(returnAmount, forKey: cartItemId)
                
                returnDictAmount = returnDict.objectForKey(cartItemId) as? Int
            }
            
            cell.returnInfo.text = "Ordered: \(quantity), Returned: \(returnedAmount), Return: \(returnDictAmount!)"
            
            let pieceImagesString = piece["images"] as! NSString
            let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
            
            let thumbnailURLString = pieceImageDict["thumbnail"] as! String
            let pieceImageURL: NSURL = NSURL(string: thumbnailURLString)!
            
            cell.itemImageView.setImageWithURL(pieceImageURL)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return cell
            
        case 1:
            // refund details footer
            let cell = tableView.dequeueReusableCellWithIdentifier(refundDetailsFooterCellIdentifier, forIndexPath: indexPath) as! RefundDetailsFooterCell
            
            let totalAmountRefundable = shopOrder["total_price"] as! String
            let shippingRate = shopOrder["shipping_rate"] as! String
            
            cell.shippingRate.text = "$\(shippingRate)"
            cell.totalAmountRefundable.text = "$\(totalAmountRefundable)"
            cell.refundReason.delegate = self
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            let userData: NSDictionary? = defaults.dictionaryForKey("userData")
            let shoppableType: String? = userData!["shoppable_type"] as? String
            
            if shoppableType?.lowercaseString.rangeOfString("shopper") != nil {
                // shopper
                cell.refundAmount.enabled = false
            }
            
            let cartItems = shopOrder["cart_items"] as! [NSDictionary]
            var totalReturnRefundAmount: Float = 0
            
            for cartItem in cartItems {
                // loop through each cartItem 
                // // retrieve price of piece
                let piece = cartItem["piece"] as! NSDictionary
                let cartItemId = cartItem["id"] as! Int
                let price = piece["price"] as! NSString
                
                var returnDictAmount = returnDict.objectForKey(cartItemId) as? Int
                var returnRefundAmount: Float = 0
                
                if returnDictAmount != nil {
                    returnRefundAmount = Float(returnDictAmount!) * price.floatValue
                }
                
                totalReturnRefundAmount += returnRefundAmount
            }
            
            if totalReturnRefundAmount > 0 {
                cell.refundAmount.text = String(format: "%.2f", totalReturnRefundAmount)
                
                showRefundButton(cell.refundAmount.text)
            } else {
                cell.refundAmount.text = ""
                
                hideRefundButton()
            }
            
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
            var returnDictAmount = returnDict.objectForKey(cartItemId) as? Int
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
                    
                    self.returnDict.setObject(selectedValue as! Int, forKey: cartItemId)
                    
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
        default:
            fatalError("Unknown section returned at RefundDetailsViewController")
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return orderItems.count
        case 1:
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
        }
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = reasonPlaceholderText
        }
    }
    
    // button callbacks
    func refundButtonPressed(sender: UIButton) {
        var alert = UIAlertController(title: "Are you sure?", message: "This action cannot be undone. \n\nRefund $\(finalRefundAmount)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = sprubixColor
        
        // Yes
        alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: UIAlertActionStyle.Default, handler: { action in
            
            // refund confirmed
            println("refund confirmed")
        }))
        
        // No
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }

}

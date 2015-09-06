//
//  CheckoutViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import Braintree
import TSMessages
import SSKeychain
import MRProgress

class CheckoutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    var delegate: SidePanelViewControllerDelegate?
    
    var sellerCartItemDictionary: NSMutableDictionary!
    var sellers: [NSDictionary] = [NSDictionary]()
    var sellerDeliveryMethods: [String] = [String]()
    var sellerDeliveryMethodIds: [Int] = [Int]()
    var sellerSubtotal: [Float] = [Float]()
    var sellerShippingRate: [Float] = [Float]()
    
    let checkoutItemPointsCellIdentifier = "CheckoutItemPointsCell"
    let checkoutDeliveryPaymentCellIdentifier = "CheckoutDeliveryPaymentCell"
    let cartItemSectionHeaderIdentifier = "CartItemSectionHeader"
    let cartItemSectionFooterIdentifier = "CartItemSectionFooter"
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var orderHeaderView: UIView!
    var itemTotal: Float?
    var orderTotal: Float!
    var pointsTotal: Float!
    var placeOrderButton: UIButton!

    var grandTotalAmount: UILabel!
    var discountAmount: UILabel!
    var payAmount: UILabel!

    var discount: Float = 0
    var totalDiscount: Float = 0
    var totalPointsEntered: Float = 0
    var pointsRemaining: Float?
    var userPoints: NSDictionary?
    
    var itemPayablePrices: NSMutableDictionary = NSMutableDictionary()
    var itemDiscounts: NSMutableDictionary = NSMutableDictionary()
    var itemPointsApplied: NSMutableDictionary = NSMutableDictionary()
    
    var sellerOrderTotalDiscounts: NSMutableDictionary = NSMutableDictionary()
    
    var itemCells: [CheckoutItemPointsCell] = [CheckoutItemPointsCell]()
    
    // default delivery address and payment method
    var defaultDeliveryAddress: NSDictionary = NSDictionary()
    var defaultPaymentMethod: NSDictionary = NSDictionary()
    
    var overlay: MRProgressOverlayView!
    
    @IBOutlet var checkoutTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        checkoutTableView.backgroundColor = sprubixGray
        checkoutTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // set up place order CTA button
        // add to bag CTA button
        placeOrderButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
        placeOrderButton.backgroundColor = sprubixColor
        placeOrderButton.titleLabel?.font = UIFont.boldSystemFontOfSize(18.0)
        placeOrderButton.setTitle("Place Order", forState: UIControlState.Normal)
        placeOrderButton.addTarget(self, action: "placeOrderButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(placeOrderButton)
        
        retrieveBTClientToken()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        initOrderHeader()
        retrieveUserPoints()
        retrieveUserDeliveryAddress()
        retrieveUserPaymentMethod()
        
        self.checkoutTableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        for itemCell in itemCells {
            itemCell.usePointsTextField.text = ""
            itemCell.discount.text = "-$0.00"
            
            itemCell.usePointsTextField.setNeedsDisplay()
            itemCell.discount.setNeedsDisplay()
        }
    }
    
    func initOrderHeader() {
        // set up order total view
        orderHeaderView = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeaderAndStatusbarHeight))
        
        orderHeaderView.backgroundColor = sprubixGray
        
        let labelContainer = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight + 64))
        labelContainer.backgroundColor = UIColor.whiteColor()
        
        let grandTotal = UILabel(frame: CGRectMake(10, 10, screenWidth / 2 - 10, 24))
        
        grandTotal.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotal.textColor = UIColor.blackColor()
        grandTotal.text = "Order Total"
        
        grandTotalAmount = UILabel(frame: CGRectMake(screenWidth / 2, 10, screenWidth / 2 - 10, 24))
        grandTotalAmount.textAlignment = NSTextAlignment.Right
        grandTotalAmount.textColor = UIColor.blackColor()
        grandTotalAmount.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotalAmount.text = String(format: "$%.2f", orderTotal)
        
        labelContainer.addSubview(grandTotal)
        labelContainer.addSubview(grandTotalAmount)
        
        let usePointsLabel = UILabel(frame: CGRectMake(10, 42, screenWidth / 2 - 10, 24.0))
        
        usePointsLabel.textColor = UIColor.blackColor()
        usePointsLabel.text = "Discount"
        usePointsLabel.font = UIFont.boldSystemFontOfSize(20.0)
        
        discountAmount = UILabel(frame: CGRectMake(screenWidth / 2, 42, screenWidth / 2 - 10, 24))
        discountAmount.textAlignment = NSTextAlignment.Right
        discountAmount.textColor = UIColor.blackColor()
        discountAmount.font = UIFont.boldSystemFontOfSize(20.0)
        discountAmount.text = "-$0.00"
        
        labelContainer.addSubview(usePointsLabel)
        labelContainer.addSubview(discountAmount)
        
        let payLabel = UILabel(frame: CGRectMake(10, 74, screenWidth / 2 - 10, 24.0))
        
        payLabel.textColor = sprubixColor
        payLabel.text = "Pay"
        payLabel.font = UIFont.boldSystemFontOfSize(20.0)
        
        payAmount = UILabel(frame: CGRectMake(screenWidth / 2, 74, screenWidth / 2 - 10, 24))
        
        payAmount = UILabel(frame: CGRectMake(screenWidth / 2, 74, screenWidth / 2 - 10, 24))
        payAmount.textAlignment = NSTextAlignment.Right
        payAmount.textColor = sprubixColor
        payAmount.font = UIFont.boldSystemFontOfSize(20.0)
        payAmount.text = String(format: "$%.2f", orderTotal - totalDiscount)
        
        labelContainer.addSubview(payLabel)
        labelContainer.addSubview(payAmount)
        
        orderHeaderView.addSubview(labelContainer)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Checkout"
        
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
    
    func retrieveUserPoints() {
        // REST call to retrieve latest points
        manager.GET(SprubixConfig.URL.api + "/user/points",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                self.userPoints = responseObject as? NSDictionary

                let points = self.userPoints!["amount"] as! Int
                self.pointsRemaining = Float(points)
                
                self.itemCells.removeAll()
                self.checkoutTableView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func retrieveBTClientToken() {
        // REST call to server
        manager.GET(SprubixConfig.URL.api + "/auth/braintree/token",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                var status = responseObject["status"] as? String
                
                if status != nil {
                    
                    if status == "200" {
                        var token = responseObject["token"] as? String
                        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                        
                        let username = userData!["username"] as! String
                        
                        SSKeychain.setPassword(token, forService: "braintree", account: username)
                        
                        // init braintree
                        braintreeRef = Braintree(clientToken: token)
                        
                        println("Braintree instance initialized")
                        
                    } else {
                        var automatic: NSTimeInterval = 0
                        
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Braintree token retrieval failed.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                    
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sellers.count + 1 // last section is for Delivery Address and Payment Method
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == sellers.count {
            return 2 // 1 for Delivery Address, 1 for Payment Method
        } else {
            let seller = sellers[section] as NSDictionary
        
            return sellerCartItemDictionary.objectForKey(seller)!.count
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case sellers.count:
            switch indexPath.row {
            case 0:
                // default delivery address
                
                // show DeliveryAddressesViewController
                let deliveryAddressesViewController = UIStoryboard.deliveryAddressesViewController()
                
                self.navigationController?.pushViewController(deliveryAddressesViewController!, animated: true)
            case 1:
                // default payment method
                
                // show PaymentMethodViewController
                let paymentMethodsViewController = UIStoryboard.paymentMethodsViewController()
                
                self.navigationController?.pushViewController(paymentMethodsViewController!, animated: true)
            default:
                fatalError("Unknown row in default section selected")
            }
        default:
            println("Normal row selected")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case sellers.count:
            
            let cell = tableView.dequeueReusableCellWithIdentifier(checkoutDeliveryPaymentCellIdentifier, forIndexPath: indexPath) as! CheckoutDeliveryPaymentCell
            
            switch indexPath.row {
            case 0:
                // default delivery address
                let address1 = defaultDeliveryAddress["address_1"] as? String
                var address2: String? = defaultDeliveryAddress["address_2"] as? String
                let postalCode = defaultDeliveryAddress["postal_code"] as? String
                let country = defaultDeliveryAddress["country"] as? String
                
                if address1 != nil {
                    var deliveryAddressText = address1!
                    
                    if address2 != nil {
                        deliveryAddressText += "\n\(address2!)"
                    }
                    
                    deliveryAddressText += "\n\(postalCode!)\n\(country!)"
                    cell.deliveryPaymentText.text = deliveryAddressText
                } else {
                    cell.deliveryPaymentText.text = "Add a new Delivery Address"
                }
                
                cell.deliveryPaymentImage.image = UIImage(named: "sidemenu-fulfilment")
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                
                return cell
            case 1:
                // default payment method
                let redactedCartNum = defaultPaymentMethod["redacted_card_num"] as? Int
                let imageString = defaultPaymentMethod["image"] as? String
                let cardType = defaultPaymentMethod["card_type"] as? String
                
                if redactedCartNum != nil {
                    cell.deliveryPaymentText.text = "\(cardType!) ending with ••• \(redactedCartNum!)"
                } else {
                    cell.deliveryPaymentText.text = "Add a new Payment Method"
                }
                
                if imageString != nil {
                    cell.deliveryPaymentImage.setImageWithURL(NSURL(string: imageString!))
                } else {
                    cell.deliveryPaymentImage.image = UIImage(named: "sidemenu-orders")
                }
                
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                
                return cell
            default:
                fatalError("Unknown row in last section of CheckoutViewController")
            }
            
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier(checkoutItemPointsCellIdentifier, forIndexPath: indexPath) as! CheckoutItemPointsCell
            
            let seller = sellers[indexPath.section] as NSDictionary
            let cartItems = sellerCartItemDictionary[seller] as! [NSDictionary]
            let cartItem = cartItems[indexPath.row] as NSDictionary
            
            let piece = cartItem["piece"] as! NSDictionary
            let price = piece["price"] as! NSString
            let quantity = cartItem["quantity"] as! Int
            let size = cartItem["size"] as? String
            
            cell.checkoutItemName.text = piece["name"] as? String
            cell.checkoutItemPrice.text = String(format: "$%.2f", price.floatValue * Float(quantity))
            cell.itemPrice = price.floatValue * Float(quantity)
            cell.itemId = cartItem["id"] as! Int
            cell.seller = seller
            cell.checkoutItemQuantity.text = "Quantity: \(quantity)"
            cell.checkoutItemSize.text = "Size: \(size!)"
            
            let pieceId = piece["id"] as! Int
            let pieceImagesString = piece["images"] as! NSString
            let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
            
            let thumbnailURLString = pieceImageDict["thumbnail"] as! String
            let pieceImageURL: NSURL = NSURL(string: thumbnailURLString)!
            
            cell.checkoutItemImageView.setImageWithURL(pieceImageURL)
            
            // points
            if pointsRemaining != nil {
                cell.usePointsTextField.placeholder = String(format: "Use Points: %.0f", pointsRemaining!)
                cell.usePointsTextField.delegate = self
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            itemCells.append(cell)
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == sellers.count {
            return orderHeaderView
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionHeaderIdentifier) as! CartItemSectionHeader
            
            let seller = sellers[section] as NSDictionary
            let pieceImagesString = seller["image"] as! String
            let pieceImageURL: NSURL = NSURL(string: pieceImagesString)!
            let sellerId = seller["id"] as! Int
            
            cell.sellerImageView.setImageWithURL(pieceImageURL)
            cell.sellerName.text = seller["username"] as? String
            
            cell.tappedOnSellerAction = { Void in
                self.delegate?.showUserProfile(seller)
            }
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == sellers.count {
            return nil
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionFooterIdentifier) as! CartItemSectionFooter
            
            let sellerDeliveryMethod = sellerDeliveryMethods[section] as String
            
            cell.deliveryMethod.setTitle(sellerDeliveryMethod, forState: UIControlState.Normal)
            
            cell.subtotal.text = String(format: "$%.2f", (sellerSubtotal[section]))
            cell.shippingRate.text = String(format: "$%.2f", sellerShippingRate[section])
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == sellers.count {
            return 0
        } else {
            return 86.0
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == sellers.count {
            return navigationHeaderAndStatusbarHeight + 64
        } else {
            return navigationHeight
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == sellers.count {
            switch indexPath.row {
            case 0:
                // default delivery address height
                return 80.0
            case 1:
                // default payment method height
                return 68.0
            default:
                fatalError("Unknown row returned for heightForRowAtIndexPath in CheckOutViewController")
            }
        } else {
            return 140.0
        }
    }
    
    func retrieveUserDeliveryAddress() {
        // REST call to server to retrieve user shipping address
        manager.GET(SprubixConfig.URL.api + "/shipping/address",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.defaultDeliveryAddress = responseObject as! NSDictionary
                
                var nsIndexPath = NSIndexPath(forRow: 0, inSection: self.sellers.count)
                self.checkoutTableView.reloadRowsAtIndexPaths([nsIndexPath], withRowAnimation: UITableViewRowAnimation.None)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func retrieveUserPaymentMethod() {
        // REST call to server to retrieve user payment method
        manager.GET(SprubixConfig.URL.api + "/billing/payment",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.defaultPaymentMethod = responseObject as! NSDictionary
                
                var nsIndexPath = NSIndexPath(forRow: 1, inSection: self.sellers.count)
                self.checkoutTableView.reloadRowsAtIndexPaths([nsIndexPath], withRowAnimation: UITableViewRowAnimation.None)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // UITextFieldDelegate
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if userPoints != nil {
            let points = self.userPoints!["amount"] as! Int
            discount = 0
            
            // show alert view
            let formattedPointsRemaining = String(format: "%.0f", pointsRemaining!)
            var alert = UIAlertController(title: "Current Points: \(formattedPointsRemaining)", message: "(up to 30% of the cost of this item type)", preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
                textField.placeholder = "No. of points to use"
                textField.keyboardType = UIKeyboardType.NumberPad
                
                // listen to textfield events
                NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("discountWillChange:"), name: UITextFieldTextDidChangeNotification, object: nil)
            }
            
            alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.Default, handler: { action in
                
                let checkoutItemPointsCell = (textField.superview)?.superview as! CheckoutItemPointsCell
                
                let itemPrice = checkoutItemPointsCell.itemPrice
                
                self.pointsRemaining! += (textField.text).floatValue
                
                // calculate discount
                // // limit within 30% of item price or 1000 points, or num of remaining points
                if self.discount > min((0.3 * itemPrice), self.pointsRemaining! / 100) {
                    self.discount = min((0.3 * itemPrice), self.pointsRemaining! / 100)
                }
                
                let pointsEntered = self.discount * 100
                
                // set points applied
                if self.discount > 0 {
                    textField.text = String(format: "%.0f", pointsEntered)
                    
                    self.pointsRemaining! -= pointsEntered
                    
                } else {
                    if pointsEntered > 0 {
                        textField.text = String(format: "%.0f", pointsEntered)
                    } else {
                        textField.text = ""
                    }
                }
                
                checkoutItemPointsCell.discount.text = String(format: "-$%.2f", self.discount)
                
                checkoutItemPointsCell.discount.setNeedsDisplay()
                
                // dictionary setting
                //// set item cash payable price, key is cart item id
                let itemPayablePrice: Float = checkoutItemPointsCell.itemPrice - self.discount
                
                self.itemPayablePrices.setObject(itemPayablePrice, forKey: "\(checkoutItemPointsCell.itemId)")
                self.itemDiscounts.setObject(self.discount, forKey: "\(checkoutItemPointsCell.itemId)")
                self.itemPointsApplied.setObject(self.discount * 100, forKey: "\(checkoutItemPointsCell.itemId)")
                
                //// set sellerOrderDiscounts
                var sellerOrderTotalDiscount: NSMutableDictionary? = self.sellerOrderTotalDiscounts.objectForKey(checkoutItemPointsCell.seller) as? NSMutableDictionary
                
                if sellerOrderTotalDiscount == nil {
                    sellerOrderTotalDiscount = NSMutableDictionary()
                }
                
                sellerOrderTotalDiscount?.setObject(self.discount, forKey: "\(checkoutItemPointsCell.itemId)")
                
                ////// set value into the dict
                self.sellerOrderTotalDiscounts.setObject(sellerOrderTotalDiscount!, forKey: checkoutItemPointsCell.seller)
                
                ////// refresh the other cells
                for itemCell in self.itemCells {
                    if itemCell != checkoutItemPointsCell {
                        itemCell.usePointsTextField.placeholder = String(format: "Use Points: %.0f", self.pointsRemaining!)
                        itemCell.usePointsTextField.setNeedsDisplay()
                        itemCell.discount.setNeedsDisplay()
                    }
                }
                
                // final cost
                self.totalPointsEntered = (Float(points) - self.pointsRemaining!)
                self.totalDiscount =  self.totalPointsEntered / 100
                self.discountAmount.text = String(format: "-$%.2f", self.totalDiscount)
                self.payAmount.text = String(format: "$%.2f", self.orderTotal - self.totalDiscount)
                
                NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: nil)
            }))
            
            // No
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
                
                NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: nil)
                
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        return false
    }
    
    func discountWillChange(notification: NSNotification) {
        if userPoints != nil {
            let points = userPoints!["amount"] as! Int
            let discountTextField = notification.object as! UITextField
            let pointsApplied = discountTextField.text.floatValue
            
            discount = pointsApplied / 100
        }
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func placeOrderButtonPressed(sender: UIButton) {
        
        if defaultDeliveryAddress.count > 0 && defaultPaymentMethod.count > 0 {
            // init overlay
            overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Processing...", mode: MRProgressOverlayViewMode.Indeterminate, animated: true)
            
            overlay.tintColor = sprubixColor
            
            // Mixpanel - Placed Order, Timer
            mixpanel.timeEvent("Placed Order")
            // Mixpanel - End
            
            // check stock again in case last item has been bought
            verifyStock { (insufficient) -> Void in
                if insufficient != nil {
                    self.overlay.dismiss(true)
                    
                    // stock insufficient
                    var message = ""
                    
                    for var i = 1; i <= insufficient!.count; i++ {
                        let insufficientItem = insufficient![i - 1]
                        
                        var itemName = insufficientItem["cart_item_name"] as! String
                        var orderedSize = insufficientItem["size_ordered"] as! String
                        var orderedQuantity = insufficientItem["quantity_ordered"] as! Int
                        var remainingQuantity = insufficientItem["quantity_left"] as! String
                        
                        var itemMessage = "\n\(i). \(itemName)\n(Size: \(orderedSize), Ordered: \(orderedQuantity), Left: \(remainingQuantity))"
                        
                        message += itemMessage
                    }
                    
                    // popup: these items are out of stock
                    var alert = UIAlertController(title: "Insufficient stock", message: "Sorry, someone else bought these items before you did! \n\(message)", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.view.tintColor = sprubixColor
                    
                    // // choice: go back to cart to edit
                    alert.addAction(UIAlertAction(title: "Edit My Cart", style: UIAlertActionStyle.Cancel, handler: { action in
                        
                        // pop twice
                        self.navigationController!.popToViewController(self.navigationController?.childViewControllers[self.navigationController!.childViewControllers.count - 3] as! UIViewController, animated: true)
                    }))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                } else {
                    // perform BrainTree transaction
                    self.createTransaction({ (responseObject) -> Void in
                        
                        var status = responseObject["status"] as! String
                        
                        if status == "200" {
                            var btStatus = responseObject["BT_status"] as! String
                            
                            if btStatus == "authorized" || btStatus == "submitted_for_settlement" {
                                // // if transaction OK, create new order
                                let transactionId = responseObject["BT_transaction_id"] as! String
                                self.createOrder(transactionId)
                                
                                // Mixpanel - Placed Order, Success
                                mixpanel.track("Placed Order", properties: [
                                    "Status": "Success"
                                ])
                                // Mixpanel - People, Revenue
                                mixpanel.people.trackCharge(self.orderTotal)
                                // Mixpanel - End
                            }
                            
                        } else if status == "500" {
                            println(responseObject["exception"] as! String)
                            
                            // Mixpanel - Placed Order, Fail
                            mixpanel.track("Placed Order", properties: [
                                "Status": "Fail"
                            ])
                            // Mixpanel - End
                            
                            self.overlay.dismiss(true)
                        }
                    })
                }
            }
        } else {
            let alert = UIAlertController(title: "Oops!", message: "Please fill in delivery address and payment method.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.view.tintColor = sprubixColor
            
            // Ok
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func verifyStock(completionHandler: ((insufficient : [NSDictionary]?) -> Void)) {
        manager.GET(SprubixConfig.URL.api + "/cart/verify",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var insufficientStocks = responseObject["insufficient_stocks"] as? [NSDictionary]
                
                completionHandler(insufficient: insufficientStocks)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    private func createTransaction(completionHandler: ((responseObject: NSDictionary) -> Void)) {
        manager.POST(SprubixConfig.URL.api + "/billing/transaction/create",
            parameters: [
                "discount": totalDiscount,
                "amount": orderTotal - totalDiscount,
                "total": orderTotal
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                completionHandler(responseObject: responseObject as! NSDictionary)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })

    }
    
    private func createOrder(transactionId: String) {
        let orderInfo: NSMutableDictionary = NSMutableDictionary()
        var sellersOrderInfo: [NSMutableDictionary] = [NSMutableDictionary]()
        
        var totalItemPrice: Float = 0
        var totalShippingRate: Float = 0
        
        // format order info
        for var i = 0; i < sellers.count; i++ {
            let sellerOrderInfo: NSMutableDictionary = NSMutableDictionary()
            
            let seller = sellers[i] as NSDictionary
            let sellerId = seller["id"] as! Int
            
            let subtotal = sellerSubtotal[i] as Float
            let shippingRate = sellerShippingRate[i] as Float
            let totalPrice = subtotal + shippingRate
            let deliveryOptionId = sellerDeliveryMethodIds[i] as Int
            
            totalItemPrice += subtotal
            totalShippingRate += shippingRate
            
            // set seller order info
            sellerOrderInfo.setObject(sellerId, forKey: "seller_id")
            sellerOrderInfo.setObject(subtotal, forKey: "items_price")
            sellerOrderInfo.setObject(shippingRate, forKey: "shipping_rate")
            sellerOrderInfo.setObject(totalPrice, forKey: "total_price")
            sellerOrderInfo.setObject(deliveryOptionId, forKey: "delivery_option_id")
            
            // calculate discounts, points and payable price
            var itemDiscounts: NSMutableDictionary? = sellerOrderTotalDiscounts.objectForKey(seller) as? NSMutableDictionary
            var sellerOrderTotalDiscount: Float = 0
            
            if itemDiscounts != nil {
                // loop through each (key) item and add up the values
                var discountsArray = itemDiscounts?.allValues as! [Float]
                
                for discount in discountsArray {
                    sellerOrderTotalDiscount += discount
                }
            }
            
            let totalPayablePrice = totalPrice - sellerOrderTotalDiscount
            let sellerOrderPointsApplied = sellerOrderTotalDiscount * 100
            
            sellerOrderInfo.setObject(totalPayablePrice, forKey: "total_payable_price")
            sellerOrderInfo.setObject(sellerOrderTotalDiscount, forKey: "total_discount")
            sellerOrderInfo.setObject(sellerOrderPointsApplied, forKey: "points_applied")
            
            sellersOrderInfo.append(sellerOrderInfo)
        }
        
        orderInfo.setObject(sellersOrderInfo, forKey: "sellers")
        
        orderInfo.setObject(itemPayablePrices, forKey: "item_payable_prices")
        orderInfo.setObject(itemDiscounts, forKey: "item_discounts")
        orderInfo.setObject(itemPointsApplied, forKey: "item_points_applied")
        
        orderInfo.setObject(transactionId, forKey: "braintree_transaction_id")
        orderInfo.setObject(totalItemPrice, forKey: "total_items_price")
        orderInfo.setObject(orderTotal - totalDiscount, forKey: "total_payable_price")
        orderInfo.setObject(totalDiscount, forKey: "total_discount")
        orderInfo.setObject(totalPointsEntered, forKey: "points_applied")
        orderInfo.setObject(totalShippingRate, forKey: "total_shipping_rate")
        orderInfo.setObject(orderTotal, forKey: "total_price")
        orderInfo.setObject(pointsTotal, forKey: "total_points")
        
        let defaultDeliveryAddressId = defaultDeliveryAddress["id"] as! Int
        let defaultPaymentMethodId = defaultPaymentMethod["id"] as! Int

        orderInfo.setObject(defaultDeliveryAddressId, forKey: "delivery_address_id")
        orderInfo.setObject(defaultPaymentMethodId, forKey: "payment_method_id")
        
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.POST(SprubixConfig.URL.api + "/order/create",
            parameters: orderInfo,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                self.overlay.dismiss(true)
                
                var status = responseObject["status"] as! String
                
                if status == "200" {
                    var userOrderId = responseObject["user_order_id"] as! Int
                    
                    // bring user to CheckoutOrderViewController
                    let checkoutOrderViewController = CheckoutOrderViewController()
                    
                    checkoutOrderViewController.userOrderId = userOrderId
                    
                    self.navigationController?.pushViewController(checkoutOrderViewController, animated: true)
                
                } else if status == "500" {
                    println(responseObject)
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                self.overlay.dismiss(true)
        })
    }
}

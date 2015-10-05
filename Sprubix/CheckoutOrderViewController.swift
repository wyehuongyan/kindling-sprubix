//
//  CheckoutOrderViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 12/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class CheckoutOrderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var userOrderId: Int!
    var userOrder: NSDictionary!
    var contributionArray: [NSDictionary]!
    
    var checkoutOrderTableView: UITableView!
    
    // rows
    var numItemsCell: UITableViewCell = UITableViewCell()
    var shippingAddressCell: UITableViewCell = UITableViewCell()
    var backToMainCell: UITableViewCell = UITableViewCell()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        checkoutOrderTableView = UITableView(frame: CGRectMake(0, navigationHeight, screenWidth, screenHeight))
        
        checkoutOrderTableView.backgroundColor = sprubixGray
        checkoutOrderTableView.dataSource = self
        checkoutOrderTableView.delegate = self
        
        // get rid of line seperator for empty cells
        checkoutOrderTableView.tableFooterView = UIView(frame: CGRectZero)
        
        view.addSubview(checkoutOrderTableView)
        
        retrieveUserOrder()
        sendContributorNotifications()
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
        newNavItem.title = "Confirmation"
        
        // 4. create a custom back button
        var doneButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        doneButton.setTitle("close", forState: UIControlState.Normal)
        doneButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        doneButton.frame = CGRect(x: -10, y: 0, width: 50, height: 20)
        doneButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        doneButton.addTarget(self, action: "doneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        doneButton.exclusiveTouch = true
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var doneBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: doneButton)
        doneBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.rightBarButtonItem = doneBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func sendContributorNotifications() {
        println(contributionArray)
        
        for contribution in contributionArray {
            let contributor = contribution["contributor"] as! NSDictionary
            let pointsAwarded = contribution["awarded_points"] as! Float
            let outfit = contribution["outfit"] as! NSDictionary
            
            let outfitId = outfit["id"] as! Int
            let itemIdentifier = "outfit_\(outfitId)"
            
            var outfitImagesString = outfit["images"] as! NSString
            var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
            
            let thumbnailURLString = outfitImageDict["thumbnail"] as! String
            let receiverUsername = contributor["username"] as! String
            
            println("sending notification to \(receiverUsername)...")
            
            sendNotification(itemIdentifier, thumbnailURLString: thumbnailURLString, receiverUsername: receiverUsername, poutfitType: "outfit", pointsAwarded: pointsAwarded)
        }
    }
    
    func retrieveUserOrder() {
        // REST call to server to retrieve user order
        manager.POST(SprubixConfig.URL.api + "/order/user",
            parameters: [
                "user_order_id": userOrderId,
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.userOrder = responseObject as! NSDictionary
                
                var shopOrders = self.userOrder["shop_orders"] as! [NSDictionary]
                
                for shopOrder in shopOrders {
                    // send firebase notification
                    self.sendNotification(shopOrder)
                }
                
                self.checkoutOrderTableView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                // picture and no. of items sent
                let thankView = UIView(frame: CGRectMake(0, 0, screenWidth, 0.7 * screenWidth))
                
                thankView.backgroundColor = sprubixLightGray
                
                let thankMessageWidth = screenWidth
                let thankMessageHeight: CGFloat = 25.0
                let thankMessageLabel1 = UILabel(frame: CGRectMake(0, 20.0, screenWidth, thankMessageHeight))
                
                let userData: NSDictionary! = defaults.dictionaryForKey("userData")
                let username = userData["username"] as! String
                
                thankMessageLabel1.textAlignment = NSTextAlignment.Center
                thankMessageLabel1.textColor = UIColor.darkGrayColor()
                thankMessageLabel1.font = UIFont.boldSystemFontOfSize(20.0)
                thankMessageLabel1.text = "Thank you, \(username)!"
                
                let thankMessageLabel2 = UILabel(frame: CGRectMake(0, thankMessageLabel1.frame.origin.y + thankMessageHeight, screenWidth, navigationHeight))
                
                thankMessageLabel2.textAlignment = NSTextAlignment.Center
                thankMessageLabel2.textColor = UIColor.darkGrayColor()
                thankMessageLabel2.font = UIFont.systemFontOfSize(16.0)
                thankMessageLabel2.text = "Your order has been placed."
                
                let vanImageHeight = (0.7 * screenWidth) - 20.0 - (2 * thankMessageHeight)
                let vanImageView = UIImageView(frame: CGRectMake(0, thankMessageLabel2.frame.origin.y + thankMessageHeight, screenWidth, vanImageHeight))
                
                vanImageView.image = UIImage(named: "order-placed")
                vanImageView.contentMode = UIViewContentMode.ScaleAspectFit
                
                thankView.addSubview(thankMessageLabel1)
                thankView.addSubview(thankMessageLabel2)
                thankView.addSubview(vanImageView)
                
                // num items
                let numItemsLabel = UILabel(frame: CGRectMake(15.0, 0.7 * screenWidth, screenWidth, navigationHeight))
                numItemsLabel.text = "Items shipping to:"
                numItemsLabel.font = UIFont.boldSystemFontOfSize(numItemsLabel.font.pointSize)
                numItemsLabel.textColor = UIColor.darkGrayColor()
                
                numItemsCell.addSubview(thankView)
                numItemsCell.addSubview(numItemsLabel)
                numItemsCell.selectionStyle = UITableViewCellSelectionStyle.None
                
                return numItemsCell
            case 1:
                // delivery address
                if userOrder != nil {
                    var deliveryAddress: NSDictionary? = userOrder["shipping_address"] as? NSDictionary
                    
                    if deliveryAddress != nil {
                        let address1 = deliveryAddress!["address_1"] as! String
                        var address2: String? = deliveryAddress!["address_2"] as? String
                        let postalCode = deliveryAddress!["postal_code"] as! String
                        let country = deliveryAddress!["country"] as! String
                        let city = deliveryAddress!["city"] as! String
                        let state = deliveryAddress!["state"] as! String
                        
                        var deliveryAddressText = address1
                        
                        if address2 != nil {
                            deliveryAddressText += "\n\(address2!)"
                        }
                        
                        deliveryAddressText += "\n\(postalCode)\n\(city)\n\(state)\n\(country)"
                        
                        shippingAddressCell.textLabel?.font = UIFont.systemFontOfSize(14.0)
                        shippingAddressCell.textLabel?.textColor = UIColor.darkGrayColor()
                        shippingAddressCell.textLabel?.text = deliveryAddressText
                        shippingAddressCell.textLabel?.numberOfLines = 0
                        shippingAddressCell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
                    }
                }
                
                shippingAddressCell.selectionStyle = UITableViewCellSelectionStyle.None
                
                return shippingAddressCell
            default:
                fatalError("Error: Unknown row returned in CheckoutOrderViewController")
            }
        case 1:
            // only one row in section 2
            backToMainCell.textLabel?.text = "Back to Main"
            backToMainCell.textLabel?.textColor = sprubixColor
            backToMainCell.textLabel?.textAlignment = NSTextAlignment.Center
            
            return backToMainCell
        default:
            fatalError("Error: Unknown section returned in CheckoutOrderViewController")
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0.0
        case 1:
            return statusbarHeight
        default:
            fatalError("Error: Unknown section returned in CheckoutOrderViewController")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                return 0.7 * screenWidth + navigationHeight
            case 1:
                return 120.0
            default:
                fatalError("Error: Unknown row returned in CheckoutOrderViewController")
            }
        case 1:
            return navigationHeight
        default:
            fatalError("Error: Unknown section returned in CheckoutOrderViewController")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        default:
            fatalError("Error: Unknown section returned in CheckoutOrderViewController")
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            break
        case 1:
            // go back to main feed
            self.navigationController?.popToRootViewControllerAnimated(true)

        default:
            fatalError("Error: Unknown section returned in CheckoutOrderViewController")
        }
    }
    
    private func sendNotification(shopOrder: NSDictionary) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            // firebase collections: users and notifications
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            
            let senderUsername = userData!["username"] as! String
            let senderImage = userData!["image"] as! String
            
            let createdAt = timestamp
            let shoppableType: String? = userData!["shoppable_type"] as? String
            
            var receiverUsername: String!
            
            // receiver should be shop
            var shop = shopOrder["user"] as! NSDictionary
            receiverUsername = shop["username"] as! String
        
            var shopOrderId = shopOrder["id"] as! Int
            var shopOrderUid = shopOrder["uid"] as! String
            var shopOrderStatus = shopOrder["order_status"] as! NSDictionary
            var orderStatusTitle = shopOrderStatus["name"] as! String
            var orderStatusId = shopOrderStatus["id"] as! Int
            
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            
            // push new notifications
            let notificationRef = notificationsRef.childByAutoId()
            
            let notification = [
                "order_alert": [
                    "shop_order": [
                        "id": shopOrderId,
                        "uid": shopOrderUid,
                    ],
                    "status": orderStatusTitle,
                    "status_id": orderStatusId
                ],
                "created_at": createdAt,
                "sender": [
                    "username": senderUsername, // yourself
                    "image": senderImage
                ],
                "receiver": receiverUsername,
                "type": "order_alert",
                "unread": true
            ]
            
            notificationRef.setValue(notification, withCompletionBlock: {
                
                (error:NSError?, ref:Firebase!) in
                
                if (error != nil) {
                    println("Error: Notification could not be added.")
                } else {
                    // update target user notifications
                    let receiverUserNotificationRef = receiverUserNotificationsRef.childByAppendingPath(notificationRef.key)
                    
                    receiverUserNotificationRef.updateChildValues([
                        "created_at": createdAt,
                        "unread": true
                        ], withCompletionBlock: {
                            
                            (error:NSError?, ref:Firebase!) in
                            
                            if (error != nil) {
                                println("Error: Notification Key could not be added to Users.")
                            }
                    })
                    
                    // send APNS
                    let recipientId = shop["id"] as! Int
                    let senderId = userData!["id"] as! Int
                    
                    if recipientId != senderId {
                        let pushMessage = "\(senderUsername) bought something from you!"
                        
                        APNS.sendPushNotification(pushMessage, recipientId: recipientId)
                    }
                }
            })
        }
    }
    
    private func sendNotification(itemIdentifier: String, thumbnailURLString: String, receiverUsername: String, poutfitType: String, pointsAwarded: Float) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            // firebase collections: users and notifications
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            
            let senderUsername = userData!["username"] as! String
            let senderImage = userData!["image"] as! String
            
            if senderUsername != receiverUsername {
                
                let createdAt = timestamp
                let shoppableType: String? = userData!["shoppable_type"] as? String
                
                let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
                
                // push new notifications
                let notificationRef = notificationsRef.childByAutoId()
                
                let notification = [
                    "poutfit": [
                        "key": itemIdentifier,
                        "image": thumbnailURLString
                    ],
                    "created_at": createdAt,
                    "sender": [
                        "username": senderUsername, // yourself
                        "image": senderImage
                    ],
                    "receiver": receiverUsername,
                    "awarded_points": pointsAwarded,
                    "type": "points_received",
                    "unread": true
                ]
                
                notificationRef.setValue(notification, withCompletionBlock: {
                    
                    (error:NSError?, ref:Firebase!) in
                    
                    if (error != nil) {
                        println("Error: Notification could not be added.")
                    } else {
                        // update target user notifications
                        let receiverUserNotificationRef = receiverUserNotificationsRef.childByAppendingPath(notificationRef.key)
                        
                        receiverUserNotificationRef.updateChildValues([
                            "created_at": createdAt,
                            "unread": true
                            ], withCompletionBlock: {
                                
                                (error:NSError?, ref:Firebase!) in
                                
                                if (error != nil) {
                                    println("Error: Notification Key could not be added to Users.")
                                }
                        })
                    }
                })
            }
        }
    }
    
    // nav bar button callbacks
    func doneTapped(sender: UIBarButtonItem) {
        // go back to main feed
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}

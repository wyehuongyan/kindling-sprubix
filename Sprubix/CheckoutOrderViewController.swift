//
//  CheckoutOrderViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 12/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import MRProgress
import AFNetworking

class CheckoutOrderViewController: UIViewController {

    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var userOrderId: Int!
    var userOrder: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // MRCheckmarkIconView
        let checkmarkIconWidth = screenWidth / 2
        let checkmarkIcon = MRCheckmarkIconView(frame: CGRectMake(screenWidth / 4, checkmarkIconWidth / 2, checkmarkIconWidth, checkmarkIconWidth))
        
        view.addSubview(checkmarkIcon)
        
        retrieveUserOrder()
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
        newNavItem.title = "Thank You"
        
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
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
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
    
    // nav bar button callbacks
    func doneTapped(sender: UIBarButtonItem) {
        // go back to main feed
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}

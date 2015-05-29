//
//  NotificationViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 27/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class NotificationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var notificationTableView: UITableView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    let notificationCellIdentifier = "NotificationCell"
    var notifications: [NSDictionary] = [NSDictionary]()
    var notificationKeyPositions: [String] = [String]()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // firebase user notifications
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            let username = userData!["username"] as! String
            
            let userNotificationRef = firebaseRef.childByAppendingPath("users/\(username)/notifications")
            
            // Firebase Listener: child added
            userNotificationRef.queryOrderedByChild("created_at").queryLimitedToLast(50).observeEventType(.ChildAdded, withBlock: {
                snapshot in
                
                //println("key: \(snapshot.key)")
                //println(snapshot.value.objectForKey("created_at"))
                //println(snapshot.value.objectForKey("unread"))
                
                SidePanelOption.alerts.counter[SidePanelOption.Option.Notifications.toString()] = SidePanelOption.alerts.counter[SidePanelOption.Option.Notifications.toString()]! + 1
                
                // update mainBadge
                if SidePanelOption.alerts.total > 0 {
                    mainBadge.alpha = 1.0
                }
                
                mainBadge.text = "\(SidePanelOption.alerts.total!)"
                
                // retrieve notifications data
                let notificationsRef = firebaseRef.childByAppendingPath("notifications/\(snapshot.key)")
                
                notificationsRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                    // do some stuff once
                    
                    if (snapshot.value as? NSNull) != nil {
                        // does not exist
                    } else {
                        let notificationDict = snapshot.value as! NSDictionary
                        
                        // snapshot queryOrderedByChild is returned in ascending order
                        self.notifications.insert(notificationDict, atIndex: 0)
                        self.notificationKeyPositions.insert(snapshot.key as String, atIndex: 0)
                        
                        // reload table
                        if self.notificationTableView != nil {
                            self.notificationTableView.reloadData()
                        }
                    }
                })
            })
            
            // Firebase Listener: child removed
            userNotificationRef.observeEventType(.ChildRemoved, withBlock: {
                snapshot in
                println("\(snapshot.key) was removed from user notifications.")
                
                let unread = snapshot.value.objectForKey("unread") as! Bool
                
                // only update badge count if its unread
                if(unread == true) {
                    SidePanelOption.alerts.counter[SidePanelOption.Option.Notifications.toString()] = SidePanelOption.alerts.counter[SidePanelOption.Option.Notifications.toString()]! - 1
                    
                    // update mainBadge
                    if SidePanelOption.alerts.total <= 0 {
                        mainBadge.alpha = 0
                    }
                    
                    mainBadge.text = "\(SidePanelOption.alerts.total!)"
                }
                
                // remove from self.notifications
                let pos: Int? = find(self.notificationKeyPositions, snapshot.key as String)
                
                if pos != nil && pos < self.notifications.count {
                    self.notifications.removeAtIndex(pos!)
                    self.notificationKeyPositions.removeAtIndex(pos!)
                }
                
                // reload table
                if self.notificationTableView != nil {
                    self.notificationTableView.reloadData()
                }
            })
            
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()

        notificationTableView.delegate = self
        notificationTableView.dataSource = self
        notificationTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        
        notificationTableView.reloadData()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Notifications"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(notificationCellIdentifier, forIndexPath: indexPath) as! NotificationCell
        
        let notification = notifications[indexPath.row] as NSDictionary
        
        let sender = notification["sender"] as! NSDictionary
        let senderUsername = sender["username"] as! String
        let senderImageURL = NSURL(string: sender["image"] as! String)
        
        let poutfit = notification["poutfit"] as! NSDictionary
        let poutfitImageURL = NSURL(string: poutfit["image"] as! String)
        
        let type = notification["type"] as! String
        let createdAt = notification["created_at"] as! String
        let duration = calculateDuration(createdAt)
        
        var notificationMessage = ""
        
        switch type {
        case "like":
            notificationMessage = "\(senderUsername) liked your item. \(duration) "
        case "comment":
            notificationMessage = "\(senderUsername) left a comment on your item. \(duration)"
        default:
            fatalError("Error: Unknown notification type")
        }
        
        cell.notificationLabel.text = notificationMessage
        cell.userImageView.setImageWithURL(senderImageURL)
        cell.itemImageView.setImageWithURL(poutfitImageURL)
        cell.userInteractionEnabled = false
        
        return cell
    }
    
    func calculateDuration(createdAt: String) -> String {
        let createdAtDate = NSDate(timeIntervalSince1970: createdAt.doubleValue)
        let duration = abs(createdAtDate.timeIntervalSinceDate(NSDate()))
        
        let weeks: Int = Int(duration) / (60 * 60 * 24 * 7)
        let days: Int = Int(duration) / (60 * 60 * 24)
        let hours: Int = Int(duration) / (60 * 60) - (days * 24)
        let minutes: Int = (Int(duration) / 60) - (days * 24 * 60) - (hours * 60)
        let seconds: Int = Int(round(duration)) % 60
        
        //return "Days: \(days), Hours: \(hours), Minutes: \(minutes), Seconds: \(seconds)"
        
        var result = weeks > 0 ? "\(weeks)w" : days > 0 ? "\(days)d" : hours > 0 ? "\(hours)h" : minutes > 0 ? "\(minutes)m" : seconds > 0 ? "\(seconds)s" : "error"
        
        return result
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

extension String {
    var doubleValue: Double {
        return (self as NSString).doubleValue
    }
}

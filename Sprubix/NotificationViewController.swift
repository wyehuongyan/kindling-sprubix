//
//  NotificationViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 27/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import STTweetLabel
import AFNetworking

class NotificationViewController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UITableViewDataSource, UITableViewDelegate {

    var delegate: SidePanelViewControllerDelegate?
    
    @IBOutlet var notificationTableView: UITableView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    let notificationCellIdentifier = "NotificationCell"
    var notifications: [NSDictionary] = [NSDictionary]()
    var notificationKeyPositions: [String] = [String]()
    
    // firebase
    var childAddedHandle: UInt?
    var childRemovedHandle: UInt?
    var userNotificationsRef: Firebase!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        println("sprubix notifications initialized!")
        
        // firebase user notifications
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            let username = userData!["username"] as! String
            
            userNotificationsRef = firebaseRef.childByAppendingPath("users/\(username)/notifications")
            
            // Firebase Listener: child added
            childAddedHandle = userNotificationsRef.queryOrderedByChild("created_at").queryLimitedToLast(50).observeEventType(.ChildAdded, withBlock: {
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
                
                // retrieve notification data
                let notificationRef = firebaseRef.childByAppendingPath("notifications/\(snapshot.key)")
                
                notificationRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                    // do some stuff once
                    
                    if (snapshot.value as? NSNull) != nil {
                        // does not exist
                    } else {
                        let notificationDict = snapshot.value as! NSDictionary
                        
                        // snapshot queryOrderedByChild is returned in ascending order
                        self.notifications.insert(notificationDict, atIndex: 0)
                        self.notificationKeyPositions.insert(snapshot.key as String, atIndex: 0)
                        self.insertRowAtTop(notificationDict)
                        
                        // reload table
//                        if self.notificationTableView != nil {
//                            self.notificationTableView.reloadData() // change it to insertRow
//                        }
                    }
                })
            })
            
            // Firebase Listener: child removed
            childRemovedHandle = userNotificationsRef.observeEventType(.ChildRemoved, withBlock: {
                snapshot in
                println("\(snapshot.key) was removed from user notifications.")
                
                let unread = snapshot.value.objectForKey("unread") as? Bool
                
                // only update badge count if its unread
                if unread == true {
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
                    self.deleteRow(pos!)
                }
                
//                // reload table
//                if self.notificationTableView != nil {
//                    self.notificationTableView.reloadData() // change it to deleteRow
//                }
            })
            
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        initNavBar()
        
        notificationTableView.delegate = self
        notificationTableView.dataSource = self
        notificationTableView.rowHeight = UITableViewAutomaticDimension
        
        // get rid of line seperator for empty cells
        notificationTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // empty dataset
        notificationTableView.emptyDataSetSource = self
        notificationTableView.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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
        newNavItem.title = "Activity"
        
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
    
    func insertRowAtTop(newNotification: NSDictionary) {
        if self.notificationTableView != nil {
            notificationTableView.layoutIfNeeded()
            
            notificationTableView.beginUpdates()
            
            var nsPath = NSIndexPath(forRow: 0, inSection: 0)
            notificationTableView.insertRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.Fade)
            
            notificationTableView.endUpdates()
        }
    }
    
    func deleteRow(rowIndex: Int) {
        if self.notificationTableView != nil {
            notificationTableView.layoutIfNeeded()
            
            notificationTableView.beginUpdates()
            
            var nsPath = NSIndexPath(forRow: rowIndex, inSection: 0)
            notificationTableView.deleteRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.Fade)
            
            notificationTableView.endUpdates()
        }
    }
    
    func removeFirebaseListeners() {
        if childAddedHandle != nil {
            userNotificationsRef.removeObserverWithHandle(childAddedHandle!)
            println("Removed: notification added listener")
        }
        
        if childRemovedHandle != nil {
            userNotificationsRef.removeObserverWithHandle(childRemovedHandle!)
            println("Removed: notification removed listener")
        }
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "\nActivity related to you"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "When someone comments, likes, or creates an outfit\n from the items you own, you'll see it here."
        
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
        return UIImage(named: "emptyset-notifications")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return UIColor.whiteColor()
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61
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
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        var notificationMessage: String?
        
        switch type {
        case "like":
            notificationMessage = "@\(senderUsername) liked your item. \(duration)"
        case "comment":
            let comment = notification["comment"] as! NSDictionary
            let commentBody = comment["body"] as! String
            
            notificationMessage = "@\(senderUsername) left a comment on your item: \(commentBody) \(duration)"
        case "mention":
            let comment = notification["comment"] as! NSDictionary
            let commentBody = comment["body"] as! String
            
            notificationMessage = "@\(senderUsername) mentioned you in a comment: \(commentBody) \(duration)"
        default:
            fatalError("Error: Unknown notification type")
        }
        
        if notificationMessage != nil {
            cell.notificationLabel.text = notificationMessage
            cell.notificationLabel.setAttributes([
                NSForegroundColorAttributeName: sprubixColor
                ], hotWord: STTweetHotWord.Handle)
            
            cell.notificationLabel.detectionBlock = { (hotWord: STTweetHotWord, string: String!, prot: String!, range: NSRange) in
            
                let hotWords: NSArray = ["Handle", "Hashtag", "Link"]
                let hotWordType: String = hotWords[hotWord.hashValue] as! String
                
                println("hotWord type: \(hotWordType)")
                println("string: \(string)")
                
                switch hotWordType {
                case "Handle":
                    let username = string.stringByReplacingOccurrencesOfString("@", withString: "")
                    
                    // REST call to server to retrieve user details
                    manager.POST(SprubixConfig.URL.api + "/users",
                        parameters: [
                            "username": username
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                            
                            var data = responseObject["data"] as? NSArray
                            
                            if data?.count > 0 {
                                var user = data![0] as! NSDictionary
                                self.delegate?.showUserProfile(user)
                                
                                // Mixpanel - Viewed User Profile
                                mixpanel.track("Viewed User Profile", properties: [
                                    "Source": "Notification View",
                                    "Tab": "Outfit",
                                    "Target User ID": user.objectForKey("id") as! Int
                                ])
                                // Mixpanel - End
                            } else {
                                println("Error: User Profile cannot load user: \(username)")
                            }
                        },
                        failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                            println("Error: " + error.localizedDescription)
                    })
                case "HashTag":
                    // do a search on this hashtag
                    println("search hashtag")
                case "Link":
                    // webview to this link
                    println("webview to link")
                default:
                    fatalError("Error: Invalid STTweetHotWord type.")
                }
            }
        }
        
        // user image view
        cell.userImageView.setImageWithURL(senderImageURL)
        cell.senderUsername = senderUsername
        
        let goToUserProfileGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "goToUserProfile:")
        goToUserProfileGestureRecognizer.cancelsTouchesInView = true
        
        cell.userImageView.addGestureRecognizer(goToUserProfileGestureRecognizer)
        cell.userImageView.userInteractionEnabled = true
        
        // item image view
        cell.itemImageView.setImageWithURL(poutfitImageURL)
        
        let poutfitKey = poutfit["key"] as! String
        var poutfitData = split(poutfitKey) {$0 == "_"}
        var itemType = poutfitData[0]
        var itemId = poutfitData[1].toInt()
        
        cell.itemType = itemType
        cell.itemId = itemId
        
        let goToItemTypeDetailsGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "goToItemTypeDetails:")
        goToItemTypeDetailsGestureRecognizer.cancelsTouchesInView = true
        
        cell.itemImageView.addGestureRecognizer(goToItemTypeDetailsGestureRecognizer)
        cell.itemImageView.userInteractionEnabled = true
        
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
    
    func detailsViewControllerLayout () -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        
        let itemSize = CGSizeMake(screenWidth, screenHeight)
        
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        return flowLayout
    }
    
    // gesture recognizer callbacks
    func goToUserProfile(gesture: UITapGestureRecognizer) {
        let parentView = gesture.view?.superview
        
        if parentView != nil {
            var notificationCell = parentView?.superview as! NotificationCell
            
            // REST call to server to retrieve user details
            manager.POST(SprubixConfig.URL.api + "/users",
                parameters: [
                    "username": notificationCell.senderUsername!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var data = responseObject["data"] as? NSArray
                    
                    if data?.count > 0 {
                        var user = data![0] as! NSDictionary
                        self.delegate?.showUserProfile(user)
                        
                        // Mixpanel - Viewed User Profile
                        mixpanel.track("Viewed User Profile", properties: [
                            "Source": "Notification View",
                            "Tab": "Outfit",
                            "Target User ID": user.objectForKey("id") as! Int
                        ])
                        // Mixpanel - End
                    } else {
                        println("Error: User Profile cannot load user: \(notificationCell.senderUsername!)")
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
    
    func goToItemTypeDetails(gesture: UITapGestureRecognizer) {
        let parentView = gesture.view?.superview
        
        if parentView != nil {
            var notificationCell = parentView?.superview as! NotificationCell
            
            var itemType = notificationCell.itemType
            var itemId = notificationCell.itemId
            
            switch itemType! {
            case "outfit":
                // REST call to server to retrieve outfit
                manager.POST(SprubixConfig.URL.api + "/outfits",
                    parameters: [
                        "id": itemId!
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        var outfit = (responseObject["data"] as! NSArray)[0] as! NSDictionary
                        
                        let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: self.detailsViewControllerLayout(), currentIndexPath: NSIndexPath(forRow: 0, inSection: 0))
                        
                        outfitDetailsViewController.outfits = [outfit]
                        
                        // push outfitDetailsViewController onto navigation stack
                        let transition = CATransition()
                        transition.duration = 0.3
                        transition.type = kCATransitionMoveIn
                        transition.subtype = kCATransitionFromTop
                        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                        
                        self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
                        self.navigationController!.pushViewController(outfitDetailsViewController, animated: false)
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
                
            case "piece":
                // REST call to server to retrieve piece
                manager.POST(SprubixConfig.URL.api + "/pieces",
                    parameters: [
                        "id": itemId!
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        var piece = (responseObject["data"] as! NSArray)[0] as! NSDictionary
                        
                        let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: self.detailsViewControllerLayout(), currentIndexPath: NSIndexPath(forRow: 0, inSection: 0))
                        
                        pieceDetailsViewController.pieces = [piece]
                        pieceDetailsViewController.user = piece["user"] as! NSDictionary
                        
                        // push outfitDetailsViewController onto navigation stack
                        let transition = CATransition()
                        transition.duration = 0.3
                        transition.type = kCATransitionMoveIn
                        transition.subtype = kCATransitionFromTop
                        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                        
                        self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
                        self.navigationController!.pushViewController(pieceDetailsViewController, animated: false)
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            default:
                fatalError("Error: Invalid notification cell item type.")
            }
        }
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

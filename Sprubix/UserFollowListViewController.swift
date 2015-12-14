//
//  UserFollowListViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import AFNetworking

protocol UserFollowInteractionProtocol {
    func showProfile(user: NSDictionary)
    func followUser(user: NSDictionary, sender: UIButton)
    func unfollowUser(user: NSDictionary, sender: UIButton)
}

class UserFollowListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UserFollowInteractionProtocol, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    let userFollowListIdentifier: String = "UserFollowListCell"
    let userFollowListUNIdentifier: String = "UserFollowListUNCell"
    
    var following: Bool!
    var followListUsers: [NSDictionary] = [NSDictionary]()
    var user: NSDictionary!
    
    var currentPage: Int = 0
    var lastPage: Int?
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    @IBOutlet weak var followListTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // get rid of line seperator for empty cells
        followListTable.tableFooterView = UIView(frame: CGRectZero)
        
        // empty dataset
        followListTable.emptyDataSetSource = self
        followListTable.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        retrieveFollowList()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        followListTable.addInfiniteScrollingWithActionHandler({
            self.retrieveFollowList()
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
        newNavItem.title = following != true ? "Followers" : "Following"
        
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
    
    func retrieveFollowList() {
        if following != nil && following == true {
            // retrieve following
            retrieveFollowing()
        } else {
            // retrieve followers
            retrieveFollowers()
        }
    }
    
    private func retrieveFollowing() {
        // GET page=2, page=3 and so on
        let nextPage = currentPage + 1
        let userId = user["id"] as! Int
        
        // REST call to server to retrieve following
        manager.GET(SprubixConfig.URL.api + "/user/\(userId)/following?page=\(nextPage)",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                var followingUsers = responseObject["data"] as! [NSDictionary]
                self.currentPage = responseObject["current_page"] as! Int
                self.lastPage = responseObject["last_page"] as? Int
                
                if self.followListTable.infiniteScrollingView != nil {
                    self.followListTable.infiniteScrollingView.stopAnimating()
                }
                
                for followingUser in followingUsers {
                    self.followListUsers.append(followingUser)
                    
                    self.followListTable.layoutIfNeeded()
                    self.followListTable.beginUpdates()
                    
                    var nsPath = NSIndexPath(forRow: self.followListUsers.count - 1, inSection: 0)
                    self.followListTable.insertRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    
                    self.followListTable.endUpdates()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                if self.followListTable.infiniteScrollingView != nil {
                    self.followListTable.infiniteScrollingView.stopAnimating()
                }
        })
    }
    
    private func retrieveFollowers() {
        // GET page=2, page=3 and so on
        let nextPage = currentPage + 1
        let userId = user["id"] as! Int
        
        // REST call to server to retrieve followers
        manager.GET(SprubixConfig.URL.api + "/user/\(userId)/followers?page=\(nextPage)",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                var followers = responseObject["data"] as! [NSDictionary]
                self.currentPage = responseObject["current_page"] as! Int
                self.lastPage = responseObject["last_page"] as? Int
                
                if self.followListTable.infiniteScrollingView != nil {
                    self.followListTable.infiniteScrollingView.stopAnimating()
                }
                
                for follower in followers {
                    self.followListUsers.append(follower)
                    
                    self.followListTable.layoutIfNeeded()
                    self.followListTable.beginUpdates()
                    
                    var nsPath = NSIndexPath(forRow: self.followListUsers.count - 1, inSection: 0)
                    self.followListTable.insertRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    
                    self.followListTable.endUpdates()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                if self.followListTable.infiniteScrollingView != nil {
                    self.followListTable.infiniteScrollingView.stopAnimating()
                }
        })
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followListUsers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let user: NSDictionary = followListUsers[indexPath.row]
        
        let name = user["name"] as! String
        let username = user["username"] as! String
        let userImageURL = NSURL(string: user["image"] as! String)
        let userId = user["id"] as! Int
        let shoppableType: String? = user["shoppable_type"] as? String
        let currentUserId:Int? = defaults.objectForKey("userId") as? Int
        
        var cell: UITableViewCell!
        
        if name != "" {
            // use UserFollowListCell
            cell = tableView.dequeueReusableCellWithIdentifier(userFollowListIdentifier, forIndexPath: indexPath) as! UserFollowListCell
            
            (cell as! UserFollowListCell).user = user
            (cell as! UserFollowListCell).realname.text = name
            (cell as! UserFollowListCell).username.text = username
            (cell as! UserFollowListCell).userImageView.image = nil
            (cell as! UserFollowListCell).userImageView.setImageWithURL(userImageURL)
            
            if shoppableType?.lowercaseString.rangeOfString("shopper") == nil {
                if !user["verified_at"]!.isKindOfClass(NSNull) {
                    (cell as! UserFollowListCell).verifiedIcon.alpha = 1.0
                } else {
                    (cell as! UserFollowListCell).verifiedIcon.alpha = 0.0
                }
            } else {
                (cell as! UserFollowListCell).verifiedIcon.alpha = 0.0
            }
            
            (cell as! UserFollowListCell).followed = user["followed"] as! Bool
            (cell as! UserFollowListCell).initFollowButton()
            
            // users should not be able to unfollow themselves
            if currentUserId != nil && currentUserId! == userId {
                // myself
                (cell as! UserFollowListCell).followButton.alpha = 0.0
            } else {
                (cell as! UserFollowListCell).followButton.alpha = 1.0
            }
            
            (cell as! UserFollowListCell).delegate = self
            
        } else {
            // use UserFollowListUNCell
            cell = tableView.dequeueReusableCellWithIdentifier(userFollowListUNIdentifier, forIndexPath: indexPath) as! UserFollowListUNCell
            
            (cell as! UserFollowListUNCell).user = user
            (cell as! UserFollowListUNCell).username.text = username
            (cell as! UserFollowListUNCell).userImageView.image = nil
            (cell as! UserFollowListUNCell).userImageView.setImageWithURL(userImageURL)
            
            if shoppableType?.lowercaseString.rangeOfString("shopper") == nil {
                if !user["verified_at"]!.isKindOfClass(NSNull) {
                    (cell as! UserFollowListCell).verifiedIcon.alpha = 1.0
                } else {
                    (cell as! UserFollowListCell).verifiedIcon.alpha = 0.0
                }
            } else {
                (cell as! UserFollowListCell).verifiedIcon.alpha = 0.0
            }
            
            (cell as! UserFollowListUNCell).followed = user["followed"] as! Bool
            (cell as! UserFollowListUNCell).initFollowButton()
            
            // users should not be able to unfollow themselves
            if currentUserId != nil && currentUserId! == userId {
                // myself
                (cell as! UserFollowListCell).followButton.alpha = 0.0
            } else {
                (cell as! UserFollowListCell).followButton.alpha = 1.0
            }
            
            (cell as! UserFollowListUNCell).delegate = self
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    // UserFollowInteractionProtocol
    func followUser(user: NSDictionary, sender: UIButton) {
        manager.POST(SprubixConfig.URL.api + "/user/follow",
            parameters: [
                "follow_user_id": user["id"] as! Int
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var status = responseObject["status"] as! String
                
                if status == "200" {
                    //println("followed")
                    // send notification to followed user
                    let receiverUsername = user["username"] as! String
                    let recipientId = user["id"] as! Int
                    
                    self.sendNotification(receiverUsername, recipientId: recipientId)
                    
                } else if status == "500" {
                    //println("error in following user")
                    
                    sender.backgroundColor = UIColor.whiteColor()
                    sender.imageView?.tintColor = sprubixColor
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                sender.backgroundColor = UIColor.whiteColor()
                sender.imageView?.tintColor = sprubixColor
        })
    }
    
    func unfollowUser(user: NSDictionary, sender: UIButton) {
        manager.POST(SprubixConfig.URL.api + "/user/unfollow",
            parameters: [
                "unfollow_user_id": user["id"] as! Int
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var status = responseObject["status"] as! String
                
                if status == "200" {
                    //println("unfollowed")
                    
                } else if status == "500" {
                    //println("error in unfollowing user")
                    
                    sender.backgroundColor = sprubixColor
                    sender.imageView?.tintColor = UIColor.whiteColor()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                sender.backgroundColor = sprubixColor
                sender.imageView?.tintColor = UIColor.whiteColor()
        })
    }
    
    func showProfile(user: NSDictionary) {
        containerViewController.showUserProfile(user)
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String!
        
        if following != nil && following == true {
            // following
            text = "Following list"
        } else {
            // follower
            text = "Follower list"
        }
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String!
        
        if following != nil && following == true {
            // following
            text = "When the user follows other people, you'll see them here."
        } else {
            // follower
            text = "When the user is being followed by other people, you'll see them here."
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
        return UIImage(named: "emptyset-follow")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return UIColor.whiteColor()
    }
    
    // send firebase notification for follow
    private func sendNotification(receiverUsername: String, recipientId: Int) {
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
                    "created_at": createdAt,
                    "sender": [
                        "username": senderUsername, // yourself
                        "image": senderImage
                    ],
                    "receiver": receiverUsername,
                    "type": "follow",
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
                                } else {
                                    let pushMessage = "@\(senderUsername) started following you."
                                    
                                    APNS.sendPushNotification(pushMessage, recipientId: recipientId)
                                }
                        })
                    }
                })
            }
        }
    }
}

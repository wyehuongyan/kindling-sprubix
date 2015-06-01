//
//  CommentsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 29/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CommentsViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var poutfitIdentifier: String!
    var poutfitImageURL: String!
    var receiverUsername: String!
    var prevViewIsOutfit: Bool = false
    
    var makeKeyboardVisible = true
    var showKeyboard = false
    var dismissKeyboardTap: UITapGestureRecognizer!
    var placeholderText: String = "Add a comment..."
    
    // firebase
    var childAddedHandle: UInt?
    var poutfitsCommentsRef: Firebase!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    let commentCellIdentifier: String = "CommentCell"
    var comments: [NSDictionary] = [NSDictionary]()
    
    @IBOutlet var sendCommentButton: UIButton!
    @IBAction func sendComment(sender: AnyObject) {
        // firebase stuffs here
        
        // create comment
        // // add to comments
        // // add to poutfit
        // // add to notifications
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            let commentsRef = firebaseRef.childByAppendingPath("comments")
            let poutfitCommentsRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)/comments")
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            
            let senderUsername = userData!["username"] as! String
            let senderImage = userData!["image"] as! String
            let createdAt = timestamp
            
            // add a new comment
            let commentRef = commentsRef.childByAutoId()
            
            let comment = [
                "author": [
                    "username": senderUsername,
                    "image": senderImage
                ],
                "created_at": timestamp,
                "poutfit": poutfitIdentifier,
                "body": commentTextView.text
            ]
            
            commentRef.setValue(comment, withCompletionBlock: {
                (error:NSError?, ref:Firebase!) in
                
                if (error != nil) {
                    println("Error: Comment could not be added.")
                } else {
                    // comment added successfully
                    
                    // update poutfitCommentsRef
                    let poutfitCommentRef = poutfitCommentsRef.childByAppendingPath(commentRef.key)
                    
                    poutfitCommentRef.updateChildValues([
                        "created_at": createdAt
                        ])
                    
                    // push new notifications
                    let notificationRef = notificationsRef.childByAutoId()
                    
                    let notification = [
                        "poutfit": [
                            "key": self.poutfitIdentifier,
                            "image": self.poutfitImageURL
                        ],
                        "created_at": createdAt,
                        "sender": [
                            "username": senderUsername, // yourself
                            "image": senderImage
                        ],
                        "receiver": self.receiverUsername, // person who posted the outfit
                        "type": "comment",
                        "comment": [
                            "key": commentRef.key,
                            "body": self.commentTextView.text
                        ],
                        "unread": true
                    ]
                    
                    self.commentTextView.text = ""
                    self.sendCommentButton.enabled = false
                    
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
                            
                            // update comments with notification key
                            commentRef.updateChildValues([
                                "notification": notificationRef.key
                                ], withCompletionBlock: {
                                    
                                    (error:NSError?, ref:Firebase!) in
                                    
                                    if (error != nil) {
                                        println("Error: Notification Key could not be added to Likes.")
                                    } else {
                                        println("Comment sent successfully!")
                                    }
                            })
                        }
                    })
                }
            })
            
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    @IBOutlet var commentTextView: UITextView!
    @IBOutlet var commentView: UIView!
    @IBOutlet var commentsTableView: UITableView!
    
    // constraints
    @IBOutlet var commentsTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var commentViewBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()

        sendCommentButton.enabled = false
        
        commentTextView.delegate = self
        commentTextView.tintColor = sprubixColor
        commentTextView.textContainerInset = UIEdgeInsetsMake(3, 3, 0, 0);
        
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.rowHeight = UITableViewAutomaticDimension
        
        // gesture recognizer on tableview to dismiss keyboard on tap
        dismissKeyboardTap = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        
        dismissKeyboardTap.numberOfTapsRequired = 1
        dismissKeyboardTap.cancelsTouchesInView = false
        dismissKeyboardTap.enabled = false // only enabled when keyboard present
        
        commentsTableView.addGestureRecognizer(dismissKeyboardTap)
        
        // firebase observer handle: comments for poutfits collection (with poutfitIdentifier), event: child_add
        poutfitsCommentsRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)/comments")
        
        // Firebase Listener: child added
        childAddedHandle = poutfitsCommentsRef.queryOrderedByChild("created_at").queryLimitedToLast(50).observeEventType(.ChildAdded, withBlock: {
            snapshot in
            
            //println("key: \(snapshot.key)")
            //println(snapshot.value.objectForKey("created_at"))
            
            // retrieve comment data
            let commentRef = firebaseRef.childByAppendingPath("comments/\(snapshot.key)")
            
            commentRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                // do some stuff once
                
                if (snapshot.value as? NSNull) != nil {
                    // does not exist
                } else {
                    let commentDict = snapshot.value as! NSDictionary
                    
                    self.insertRowAtBottom(commentDict)
                }
            })
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil);

        initNavBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if showKeyboard == true {
            commentTextView.becomeFirstResponder()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if prevViewIsOutfit == true {
            self.navigationController?.delegate = transitionDelegateHolder
        }
        
        // delete firebase observer handle
        if childAddedHandle != nil {
            poutfitsCommentsRef.removeObserverWithHandle(childAddedHandle!)
        }
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Comments"
        
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
    
    func insertRowAtBottom(newComment: NSDictionary) {
        commentsTableView.beginUpdates()
        comments.append(newComment)
        var nsPath = NSIndexPath(forRow: comments.count - 1, inSection: 0)
        commentsTableView.insertRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.Fade)
        commentsTableView.endUpdates()
        
        // scroll to bottom
        commentsTableView.scrollToRowAtIndexPath(nsPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(commentCellIdentifier, forIndexPath: indexPath) as! CommentCell
        
        let comment = comments[indexPath.row]
        let author = comment["author"] as! NSDictionary
        let authorImageURL = NSURL(string: author["image"] as! String)
        let createAt = comment["created_at"] as! String
        let duration = calculateDuration(createAt)
        
        cell.userNameLabel.text = author["username"] as? String
        cell.userImageView.setImageWithURL(authorImageURL)
        cell.userComment.text = comment["body"] as? String
        cell.timeAgo.text = duration
        
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
    
    /**
    * Handler for keyboard change event
    */
    func keyboardWillChange(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        if makeKeyboardVisible {
            commentsTableViewBottomConstraint.constant = keyboardFrame.height + self.commentView.frame.size.height
            commentViewBottomConstraint.constant = keyboardFrame.height
            
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
              
                if self.comments.count > 0 {
                    // scroll to bottom
                    var nsPath = NSIndexPath(forRow: self.comments.count - 1, inSection: 0)
                    self.commentsTableView.scrollToRowAtIndexPath(nsPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                }
                
                }, completion: { finished in
                    if finished {
                        // enable scrollview gesture recognizer
                        self.dismissKeyboardTap.enabled = true
                    }
            })
            
        } else {
            
            commentsTableViewBottomConstraint.constant -= keyboardFrame.height
            commentViewBottomConstraint.constant -= keyboardFrame.height
            dismissKeyboardTap.enabled = false
            
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: { finished in
                    if finished {
                        self.makeKeyboardVisible = true
                    }
            })
        }
    }
    
    // gesture recognizer callbacks
    func dismissKeyboard(gesture: UITapGestureRecognizer) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }
    
    // UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView.text == placeholderText {
            commentTextView.text = ""
            commentTextView.textColor = UIColor.darkGrayColor()
        }
        
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        if textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" {
            
            sendCommentButton.enabled = false
        } else {
            sendCommentButton.enabled = true
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" {
            commentTextView.text = placeholderText
            commentTextView.textColor = UIColor.lightGrayColor()
            commentTextView.resignFirstResponder()
            
            sendCommentButton.enabled = false
        } else {
            sendCommentButton.enabled = true
        }
    }

    // button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

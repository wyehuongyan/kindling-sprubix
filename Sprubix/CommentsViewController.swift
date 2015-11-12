//
//  CommentsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 29/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import STTweetLabel

enum CommentTableState {
    case Comments
    case Handles
    case Hashtags
}

class CommentsViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: SidePanelViewControllerDelegate?
    
    var poutfitIdentifier: String!
    var poutfitImageURL: String!
    var receiverUsername: String!
    var receiverId: Int!
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
    var following: [NSDictionary] = [NSDictionary]()
    
    var currentCommentTableState: CommentTableState = .Comments
    var currentlyTypedHandle: String!
    
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
            let poutfitRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)")
            let poutfitCommentsRef = poutfitRef.childByAppendingPath("comments")
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            
            let senderUsername = userData!["username"] as! String
            let senderImage = userData!["image"] as! String
            let createdAt = timestamp
            let commentBody = commentTextView.text
            
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
                    
                    // update poutfitRef num of comments
                    let poutfitCommentCountRef = poutfitRef.childByAppendingPath("num_comments")
                    
                    poutfitCommentCountRef.runTransactionBlock({
                        (currentData:FMutableData!) in
                        
                        var value = currentData.value as? Int
                        
                        if value == nil {
                            value = 0
                        }
                        
                        currentData.value = value! + 1
                        
                        return FTransactionResult.successWithValue(currentData)
                    })
                    
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
                            "body": commentBody
                        ],
                        "unread": true
                    ]
                    
                    // check if commentTextView contains mentions
                    // // for each mention, create a new notification for the receiver
                    let handleMatches = self.matchesForRegexInText("((?:^|\\s)(?:@){1}[0-9a-zA-Z_]{1,15})", text: self.commentTextView.text)
                    
                    var trimmedHandleMatches = [String]()
                    for handleMatch in handleMatches {
                        trimmedHandleMatches.append(handleMatch.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
                    }
                    
                    var orderedSet: NSOrderedSet = NSOrderedSet(array: trimmedHandleMatches)
                    var trimmedHandleMatchesWithoutDuplicates: NSArray = orderedSet.array
                    
                    for handleMatch in trimmedHandleMatchesWithoutDuplicates {
                        var match = handleMatch.stringByReplacingOccurrencesOfString("@", withString: "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        
                        // REST call to followingUser to check if you are following this person
                        // // if true, notify him/her through firebase
                        manager.POST(SprubixConfig.URL.api + "/user/followed",
                            parameters: [
                                "username": match
                            ],
                            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                                
                                let status = responseObject["status"] as! String
                                
                                if status.toInt() == 200 {
                                    var alreadyFollowed = responseObject["already_followed"] as? Bool
                                    
                                    if alreadyFollowed != nil && alreadyFollowed == true {
                                        // firebase notification
                                        println("Verified: \(match)")
                                        
                                        let mentionedUser = responseObject["followed_user"] as! NSDictionary
                                        
                                        let mentionedUserName = mentionedUser["username"] as! String
                                        
                                        // create a new notification for this mention
                                        // // mention is a subclass of comments
                                        let mentionNotificationRef = notificationsRef.childByAutoId()
                                        
                                        let mentionNotification = [
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
                                            "mention": mentionedUserName, // person who was mentioned
                                            "type": "mention",
                                            "comment": [
                                                "key": commentRef.key,
                                                "body": commentBody
                                            ],
                                            "unread": true
                                        ]
                                        
                                        mentionNotificationRef.setValue(mentionNotification, withCompletionBlock: {
                                            (error:NSError?, ref:Firebase!) in
                                            
                                            if (error != nil) {
                                                println("Error: Mention Notification could not be added.")
                                            } else {
                                                // update mentioned user notifications
                                                let mentionedUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(mentionedUserName)/notifications")
                                                let mentionedUserNotificationRef = mentionedUserNotificationsRef.childByAppendingPath(mentionNotificationRef.key)
                                                
                                                mentionedUserNotificationRef.updateChildValues([
                                                    "created_at": createdAt
                                                    ], withCompletionBlock: {
                                                        
                                                        (error:NSError?, ref:Firebase!) in
                                                        
                                                        if (error != nil) {
                                                            println("Error: Mention Notification Key could not be added to Users.")
                                                        }
                                                })
                                                
                                                // update comments with mentioned notification key
                                                let commentMentionNotificationRef = commentRef.childByAppendingPath("mention_notifications/\(mentionNotificationRef.key)")
                                                
                                                commentMentionNotificationRef.updateChildValues([
                                                    "created_at": createdAt,
                                                    "unread": true
                                                    ], withCompletionBlock: {
                                                        
                                                        (error:NSError?, ref:Firebase!) in
                                                        
                                                        if (error != nil) {
                                                            println("Error: Mention Notification Key could not be added to Comment.")
                                                        } else {
                                                            println("Comment Mention Notification added successfully!")
                                                        }
                                                })
                                                
                                                // send APNS
                                                let recipientId = mentionedUser["id"] as! Int
                                                let senderId = userData!["id"] as! Int
                                                
                                                if recipientId != senderId {
                                                    let pushMessage = "\(senderUsername) mentioned you in a comment: \(commentBody)"
                                                    
                                                    APNS.sendPushNotification(pushMessage, recipientId: recipientId)
                                                }
                                            }
                                        })
                                        
                                    }
                                } else {
                                    println(responseObject["message"])
                                }
                            },
                            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                                println("Error: " + error.localizedDescription)
                        })
                    }
                    
                    // clear the textview and disable the button
                    self.commentTextView.text = ""
                    self.sendCommentButton.enabled = false
                    
                    notificationRef.setValue(notification, withCompletionBlock: {
                        (error:NSError?, ref:Firebase!) in
                        
                        if (error != nil) {
                            println("Error: Notification could not be added.")
                        } else {
                            // update target user notifications
                            let receiverUserNotificationRef = receiverUserNotificationsRef.childByAppendingPath(notificationRef.key)
                            
                            if senderUsername != self.receiverUsername {
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
                            
                            // update comments with notification key
                            commentRef.updateChildValues([
                                "notification": notificationRef.key
                                ], withCompletionBlock: {
                                    
                                    (error:NSError?, ref:Firebase!) in
                                    
                                    if (error != nil) {
                                        println("Error: Notification Key could not be added to Comment.")
                                    } else {
                                        println("Comment sent successfully!")
                                    }
                            })
                            
                            // send APNS
                            let recipientId = self.receiverId
                            let senderId = userData!["id"] as! Int
                            
                            if recipientId != senderId {
                                let pushMessage = "\(senderUsername) left a comment: \(commentBody)"
                                
                                APNS.sendPushNotification(pushMessage, recipientId: recipientId)
                            }
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
        
        // get rid of line seperator for empty cells
        commentsTableView.tableFooterView = UIView(frame: CGRectZero)
        
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
        commentsTableView.layoutIfNeeded()
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
        var count = 0
        
        switch(currentCommentTableState) {
        case .Comments:
            count = comments.count
        case .Handles:
            count = following.count
        case .Hashtags:
            break // tentative
        }
        
        return count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch(currentCommentTableState) {
        case .Comments:
            break
        case .Handles:
            if self.following.count > 0 {
                var followingUser = self.following[indexPath.row]

                var username = followingUser["username"] as! String
                
                // replace and autocomplete
                // cut away the halfway typed handle, and append the full lengthed one
                var commentString = commentTextView.text
                commentString = commentString.substringWithRange(Range<String.Index>(start: commentString.startIndex, end: advance(commentString.endIndex, -count(currentlyTypedHandle))))
                
                commentString = "\(commentString)@\(username)"
                
                commentTextView.text = commentString
                
                // switch back to comments state
                returnToCommentsState()
            }
        case .Hashtags:
            break // tentative
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(commentCellIdentifier, forIndexPath: indexPath) as! CommentCell
        
        switch(currentCommentTableState) {
        case .Comments:
            let comment = comments[indexPath.row]
            let author = comment["author"] as! NSDictionary
            let authorImageURL = NSURL(string: author["image"] as! String)
            let createAt = comment["created_at"] as! String
            let duration = calculateDuration(createAt)
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.userNameLabel.text = author["username"] as? String
            cell.timeAgo.text = duration
            
            // userComment actions
            cell.userComment.text = comment["body"] as? String
            cell.userComment.setAttributes([
                NSForegroundColorAttributeName: sprubixColor
                ], hotWord: STTweetHotWord.Handle)
            cell.userComment.detectionBlock = { (hotWord: STTweetHotWord, string: String!, prot: String!, range: NSRange) in
                
                let hotWords: NSArray = ["Handle", "Hashtag", "Link"]
                let hotWordType: String = hotWords[hotWord.hashValue] as! String
                
                println("hotWord type: \(hotWordType)")
                println("string: \(string)")
                
                switch hotWordType {
                case "Handle":
                    // REST call to server to retrieve user details
                    manager.POST(SprubixConfig.URL.api + "/users",
                        parameters: [
                            "username": string.stringByReplacingOccurrencesOfString("@", withString: "")
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                            
                            var data = responseObject["data"] as? NSArray
                            
                            if data?.count > 0 {
                                var user = data![0] as! NSDictionary

                                // go to user profile
                                self.delegate?.showUserProfile(user)
                            } else {
                                println("Error: User Profile cannot load user.")
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
            
            // user image view
            cell.userImageView.setImageWithURL(authorImageURL)
            cell.authorName = author["username"] as? String
            
            let goToUserProfileGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "goToUserProfile:")
            goToUserProfileGestureRecognizer.numberOfTapsRequired = 1
            
            cell.userImageView.addGestureRecognizer(goToUserProfileGestureRecognizer)
            cell.userImageView.userInteractionEnabled = true

        case .Handles:
            var followingUser = following[indexPath.row]
            
            cell.selectionStyle = UITableViewCellSelectionStyle.Default
            cell.userImageView.setImageWithURL(NSURL(string: followingUser["image"] as! String))
            
            cell.userNameLabel.text = followingUser["username"] as? String
            cell.userComment.text = followingUser["name"] as? String
            cell.timeAgo.text = ""
            
        case .Hashtags:
            break
        }
        
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
        if currentCommentTableState == CommentTableState.Comments {
            makeKeyboardVisible = false
            
            self.view.endEditing(true)
        }
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
        
        /*
        let range = commentTextView.text.rangeOfString("\\b(?<=@)[^ @]+\\b", options: NSStringCompareOptions.RegularExpressionSearch)
        
        if range != nil {
            let found = commentTextView.text.substringWithRange(range!)
            println("found: \(found)") // found @username
        }
        */
        
        //let matches = matchesForRegexInText("\\b(?<=@)[^ @]+$\\b", text: commentTextView.text)
        
        let matches = matchesForRegexInText("((?:^|\\s)(?:@){1}[0-9a-zA-Z_]{1,15}$)", text: commentTextView.text)
        
        if matches.last != nil {
            currentlyTypedHandle = matches.last!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            // REST call to server to retrieve related user
            manager.POST(SprubixConfig.URL.api + "/user/following",
                parameters: [
                    "initials": matches.last!.stringByReplacingOccurrencesOfString("@", withString: "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    self.following.removeAll()
                    self.following = responseObject as! [NSDictionary]
                    
                    var firstFollowingUser: NSDictionary? = self.following.first
                    var firstFollowingUserName = firstFollowingUser?["username"] as? String
                    
                    if self.following.count > 0 && self.commentTextView.text != "" && firstFollowingUserName != self.currentlyTypedHandle.stringByReplacingOccurrencesOfString("@", withString: "") {
                        self.currentCommentTableState = CommentTableState.Handles
                        self.commentsTableView.reloadData()
                    } else {
                        self.currentCommentTableState = CommentTableState.Comments
                        self.commentsTableView.reloadData()
                        self.commentsTableView.alpha = 0
                        
                        self.returnToCommentsState()
                    }

                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            if currentCommentTableState != CommentTableState.Comments {
                returnToCommentsState()
            }
        }
    }
    
    private func returnToCommentsState() {
        currentCommentTableState = CommentTableState.Comments
        self.commentsTableView.reloadData()

        self.commentsTableView.alpha = 0
        
        if self.comments.count > 0 {
            // scroll to bottom
            self.commentsTableView.layoutIfNeeded()
            var nsPath = NSIndexPath(forRow: self.comments.count - 1, inSection: 0)
            self.commentsTableView.scrollToRowAtIndexPath(nsPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
        
        self.commentsTableView.alpha = 1
    }
    
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        let regex = NSRegularExpression(pattern: regex,
            options: nil, error: nil)!
        let nsString = text as NSString
        let results = regex.matchesInString(text,
            options: nil, range: NSMakeRange(0, nsString.length))
            as! [NSTextCheckingResult]
        return map(results) { nsString.substringWithRange($0.range)}
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
    
    // gesture recognizer callbacks
    func goToUserProfile(gesture: UITapGestureRecognizer) {
        let parentView = gesture.view?.superview
        
        if parentView != nil {
            var commentCell = parentView?.superview as! CommentCell
            
            // REST call to server to retrieve user details
            manager.POST(SprubixConfig.URL.api + "/users",
                parameters: [
                    "username": commentCell.authorName!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var data = responseObject["data"] as? NSArray
                    
                    if data?.count > 0 {
                        var user = data![0] as! NSDictionary
                        
                        // go to user profile
                        self.delegate?.showUserProfile(user)
                    } else {
                        println("Error: User Profile cannot load user.")
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }

    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    // button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

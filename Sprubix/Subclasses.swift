//
//  Subclasses.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 19/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import STTweetLabel
import SSKeychain
import AFNetworking
import Foundation
import SystemConfiguration
import TSMessages

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate{
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let transition = Transition()
        transition.presenting = operation == .Pop
        
        return transition
    }
}

let transitionDelegateHolder = NavigationControllerDelegate()

class SprubixItemCommentRow: UIView {
    var commentRowHeight:CGFloat!
    var postCommentButton:UIButton!
    
    let commentRowPaddingBottom:CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(username:String, commentString:String, y: CGFloat, button: Bool, userThumbnail:String = "person-placeholder.jpg") {
        self.init()
        
        var commentRowView = self
        
        self.backgroundColor = UIColor.whiteColor()
        let commentImageViewWidth:CGFloat = 40
        
        // commenter's image
        var commentImageView:UIImageView = UIImageView(frame: CGRect(x: 20, y: 0, width: commentImageViewWidth, height: commentImageViewWidth))

        if userThumbnail == "sprubix-user" {
            let userData:NSDictionary! = defaults.dictionaryForKey("userData")
            
            // create profile UIImageView programmatically
            let userThumbnailURL = NSURL(string: userData["image"] as! String)
            
            commentImageView.setImageWithURL(userThumbnailURL)
        } else {
            // create profile UIImageView programmatically
            let userThumbnailURL = NSURL(string: userThumbnail)
            
            commentImageView.setImageWithURL(userThumbnailURL)
        }
        
        // circle mask
        commentImageView.layer.cornerRadius = commentImageView.frame.size.width / 2
        commentImageView.clipsToBounds = true
        commentImageView.layer.borderWidth = 1.0
        commentImageView.layer.borderColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1).CGColor
        
        commentRowView.addSubview(commentImageView)
        
        if button {
            postCommentButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
            postCommentButton.frame = CGRect(x: commentImageViewWidth + 28, y: 0, width: screenWidth - (commentImageViewWidth + 50), height: commentImageViewWidth)
            postCommentButton.setTitle("Add a comment", forState: UIControlState.Normal)
            postCommentButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
            postCommentButton.backgroundColor = UIColor.whiteColor()
            postCommentButton.layer.cornerRadius = commentImageViewWidth / 2
            postCommentButton.layer.borderWidth = 2.0
            postCommentButton.layer.borderColor = sprubixColor.CGColor
            postCommentButton.exclusiveTouch = true
            
            commentRowView.addSubview(postCommentButton)
            
            commentRowHeight = postCommentButton.frame.height + commentRowPaddingBottom
            
            commentRowView.frame = CGRect(x: 0, y: y, width: screenWidth, height: commentRowHeight)
            
        } else {
            // commenter's nickname
            let commentUsernameHeight:CGFloat = 21
            var commentUsername:UILabel = UILabel(frame: CGRect(x: commentImageViewWidth + 28, y: 0, width: screenWidth - (commentImageViewWidth + 28), height: commentUsernameHeight))
            commentUsername.textColor = tintColor
            commentUsername.text = username
            
            commentRowView.addSubview(commentUsername)
            
            // comment
            var comment:UILabel = UILabel()
            comment.lineBreakMode = NSLineBreakMode.ByWordWrapping
            comment.numberOfLines = 0
            comment.text = commentString
            
            let commentHeight = heightForTextLabel(comment.text!, font: comment.font, width: screenWidth - (commentImageViewWidth + 40), hasInsets: false)
            comment.frame = CGRect(x: commentImageViewWidth + 28, y: 18, width: screenWidth - (commentImageViewWidth + 40), height: commentHeight)
            
            commentRowView.addSubview(comment)
            
            commentRowHeight = commentUsernameHeight + commentHeight + commentRowPaddingBottom
            
            commentRowView.frame = CGRect(x: 0, y: y, width: screenWidth, height: commentRowHeight)
        }
    }
    
    func heightForTextLabel(text:String, font:UIFont, width:CGFloat, hasInsets:Bool) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return hasInsets ? label.frame.height + 70 : label.frame.height // + 70 because of the custom insets from SprubixItemDescription
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SprubixItemDescription: UILabel {
    override func drawTextInRect(rect: CGRect) {
        let insets:UIEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}

class SprubixHandleBarSeperator: UIView {
    var seperatorLineTop: UIView!
    var handleBar: UIView!
    var draggable: Bool!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, handleWidth: CGFloat, lineStroke: CGFloat, glow: Bool = true, opacity: CGFloat = 1.0) {
        super.init(frame: frame)
        
        // seperator line
        seperatorLineTop = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: lineStroke))
        seperatorLineTop.backgroundColor = UIColor.whiteColor()
        seperatorLineTop.alpha = opacity
        
        self.addSubview(seperatorLineTop)
        
        // handlebar
        let handleBarWidth: CGFloat = handleWidth
        let handleBarHeight: CGFloat = 5.0 + lineStroke
        handleBar = UIView(frame: CGRectMake(self.frame.width / 2 - handleBarWidth / 2, lineStroke / 2 - handleBarHeight / 2, handleBarWidth, handleBarHeight))
        handleBar.backgroundColor = UIColor.whiteColor()
        handleBar.layer.cornerRadius = handleBarHeight / 2
        handleBar.alpha = opacity
        
        self.addSubview(handleBar)
        
        if glow != false {
            Glow.addGlow(seperatorLineTop)
            Glow.addGlow(handleBar)
        }
    }
    
    func setCustomBackgroundColor(color: UIColor) {
        seperatorLineTop.backgroundColor = color
        handleBar.backgroundColor = color
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SprubixCreditButton: UIButton {
    var user: NSDictionary?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, buttonLabel: String, username: String, userThumbnail: String = "person-placeholder.jpg") {
        super.init(frame:frame)
        
        // the button
        self.autoresizesSubviews = true
        self.backgroundColor = UIColor.whiteColor()
        self.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        self.exclusiveTouch = true
        
        // profile pic inside button
        var creditImageView: UIImageView = UIImageView()
        
        if userThumbnail == "person-placeholder.jpg" {
            creditImageView.image = UIImage(named: userThumbnail)
        } else {
            // create profile UIImageView programmatically
            let userThumbnailURL = NSURL(string: userThumbnail)
            creditImageView.setImageWithURL(userThumbnailURL)
        }
        
        let creditImageViewWidth:CGFloat = 35
        creditImageView.frame = CGRect(x: 20, y: (self.frame.height/2) - creditImageViewWidth/2, width: creditImageViewWidth, height: creditImageViewWidth)
        
        // circle mask
        creditImageView.layer.cornerRadius = creditImageView.frame.size.width / 2
        creditImageView.clipsToBounds = true
        creditImageView.layer.borderWidth = 1.0
        creditImageView.layer.borderColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1).CGColor
        
        self.addSubview(creditImageView)
        
        // UILines on top and buttom of button
        var buttonLineBottom = UIView(frame: CGRect(x: 0, y: self.frame.height - 10.0, width: self.frame.width, height: 10))
        buttonLineBottom.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        var buttonLineTop = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 10))
        buttonLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        self.addSubview(buttonLineTop)
        self.addSubview(buttonLineBottom)
        
        // labels 'posted by'/'from' and user name below
        var buttonLabelTopHeight:CGFloat = 20
        var buttonLabelTop:UILabel = UILabel(frame: CGRect(x: creditImageView.frame.origin.x + 43, y: buttonLabelTopHeight, width: self.frame.width - creditImageViewWidth + 20, height: 21))
        buttonLabelTop.font = UIFont(name: buttonLabelTop.font.fontName, size: 13)
        buttonLabelTop.textColor = UIColor.lightGrayColor()
        buttonLabelTop.text = buttonLabel
        
        var buttonLabelBottom:UILabel = UILabel(frame: CGRect(x: creditImageView.frame.origin.x + 43, y: buttonLabelTopHeight + 18, width: self.frame.width - creditImageViewWidth + 20, height: 21))
        buttonLabelBottom.font = UIFont(name: buttonLabelTop.font.fontName, size: 13)
        buttonLabelBottom.text = username
        
        self.addSubview(buttonLabelTop)
        self.addSubview(buttonLabelBottom)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SprubixTweetLabel: STTweetLabel {
    override func intrinsicContentSize() -> CGSize {
        var size: CGSize = self.suggestedFrameSizeToFitEntireStringConstrainedToWidth(screenWidth - 120)
        
        return CGSizeMake(size.width, size.height)
    }
}

class SprubixNotificationItemImageView: UIImageView {
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        var frame:CGRect = CGRectInset(self.bounds, -20, -20)
        
        println(CGRectContainsPoint(frame, point))
        println(event)
        
        return CGRectContainsPoint(frame, point) ? self : nil
    }
}

class Glow {
    class func addGlow(item: AnyObject) {
        item.layer.shadowColor = UIColor.blackColor().CGColor
        item.layer.shadowOpacity = 0.8
        item.layer.shadowRadius = 1
        item.layer.shadowOffset = CGSizeZero
        item.layer.masksToBounds = false
    }
}

class Delay {
    class func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}

class SprubixButtonIconRight: UIButton {
    override func imageRectForContentRect(contentRect:CGRect) -> CGRect {
        var imageFrame = super.imageRectForContentRect(contentRect)
        imageFrame.origin.x = CGRectGetMaxX(super.titleRectForContentRect(contentRect)) - CGRectGetWidth(imageFrame)
        return imageFrame
    }
    
    override func titleRectForContentRect(contentRect:CGRect) -> CGRect {
        var titleFrame = super.titleRectForContentRect(contentRect)
        if (self.currentImage != nil) {
            titleFrame.origin.x = CGRectGetMinX(super.imageRectForContentRect(contentRect))
        }
        return titleFrame
    }
}

class SprubixReachability {
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
        }
        
        var flags: SCNetworkReachabilityFlags = 0
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
            return false
        }
        
        let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return isReachable && !needsConnection
    }
    
    class func handleError(code: Int) {
        var errorTitle: String!
        var errorMessage: String!
        var notificationType: TSMessageNotificationType!
        
        switch code {
        case -1004, -1005:
            errorTitle = "Server Offline"
            errorMessage = "The connection to the server is currently unavailable."
            notificationType = TSMessageNotificationType.Warning
        case -1001:
            errorTitle = "Request Timed Out"
            errorMessage = "The connection to the server has timed out."
            notificationType = TSMessageNotificationType.Warning
        case  -1011:
            errorTitle = "Logged out"
            errorMessage = "You have been logged out."
            notificationType = TSMessageNotificationType.Warning
        default:
            fatalError("Unknown error code \(code) returned at MainFeedController")
        }
        
        var automatic: NSTimeInterval = 0
        
        // warning message
        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: errorTitle, subtitle: errorMessage, image: nil, type: notificationType, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: false)
    }
}

// APNS
class APNS {
    class func sendPushNotification(message: String, recipientId: Int) {
        manager.POST(SprubixConfig.URL.api + "/notification/send",
            parameters: [
                "message": message,
                "recipient_id": recipientId
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var status = responseObject["status"] as! String
                
                if status == "500" {
                    println(responseObject)
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
}

// Firebase
class FirebaseAuth {
    class func retrieveFirebaseToken() {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            let username = userData!["username"] as! String
            let firebaseToken: String? = SSKeychain.passwordForService("firebase", account: username)
            
            if firebaseToken != nil {
                authenticateFirebase()
            } else {
                // retrieving token from kindling core
                println("Retrieving Firebase token from server...")
                manager.GET(SprubixConfig.URL.api + "/auth/firebase/token",
                    parameters: nil,
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        var data = responseObject as! NSDictionary
                        let token = data["token"] as! String
                        
                        SSKeychain.setPassword(token, forService: "firebase", account: username)
                        
                        self.authenticateFirebase()
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            }
            
        } else {
            println("FirebaseAuth.retrieveFirebaseToken: userData not found, please login or create an account")
        }
    }

    class func authenticateFirebase() {
        // handle token expiration gracefully
        let handle = firebaseRef.observeAuthEventWithBlock { authData in
            if authData != nil {
                // user authenticated with Firebase
                println("User already authenticated with Firebase! \(authData)")
                
                if sprubixNotificationViewController == nil {
                    sprubixNotificationViewController = UIStoryboard.notificationViewController()
                }
            } else {
                // user is logged out, need to reauthenticate
                let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                
                // user is logged in
                if userData != nil {
                    let username = userData!["username"] as! String
                    let firebaseToken: String? = SSKeychain.passwordForService("firebase", account: username)
                    
                    // auth with firebase
                    firebaseRef.authWithCustomToken(firebaseToken, withCompletionBlock: { error, authData in
                        if error != nil {
                            var description = (error.userInfo! as NSDictionary)["NSLocalizedDescription"] as! String
                            
                            println("Firebase Login failed!\n\(error.code)\n\(description)")
                            
                            // if code=9999 expired_token
                            if (error.code == 9999 && description == "expired_token") {
                                // remove token from SSKeychain and retrieve firebase token from server again
                                SSKeychain.deletePasswordForService("firebase", account: username)
                                
                                self.retrieveFirebaseToken()
                            }
                            
                        } else {
                            println("Firebase Login succeeded! \(authData)")
                            
                            // check if firebase has user data, if not, write it to firebase
                            var userRef = firebaseRef.childByAppendingPath("users/\(username)")
                            
                            userRef.observeSingleEventOfType(.Value, withBlock: {
                                snapshot in
                                
                                var result = ((snapshot.value as? NSNull) != nil) ? "is not" : "is"
                                println("\(username.capitalizeFirst) \(result) an entry in Users firebase.")
                                
                                if (snapshot.value as? NSNull) != nil {
                                    // does not exist, add it
                                    var userInfo = ["username": userData!["username"] as! String,
                                        "id": userData!["id"] as! Int,
                                        "image": userData!["image"] as! String]
                                    
                                    userRef.setValue(userInfo)
                                    println("userInfo added to firebase")
                                }
                                
                                // finally, init notificationViewController
                                if sprubixNotificationViewController == nil {
                                    sprubixNotificationViewController = UIStoryboard.notificationViewController()
                                }
                            })
                        }
                    })
                    
                } else {
                    println("FirebaseAuth.authenticateFirebase: userData not found, please login or create an account")
                }
            }
        }
    }
}

// Mixpanel
class MixpanelService {
    
    // Register user for Mixpanel People
    class func register(data: NSDictionary) {
        
        let email: String = data["email"] as! String
        let id: Int = data["id"] as! Int
        let username: String = data["username"] as! String
        let distinctId: String = mixpanel.distinctId
        
        mixpanel.createAlias(email, forDistinctID: distinctId)
        mixpanel.identify(email)
        
        mixpanel.people.set([
            "$email": email,
            "ID": id,
            "Username": username,
            "$first_name": username,
            "$last_name": "",
            "$created": NSDate(),
            "Points" : 0,
            "Exposed Outfits": 0,
            "Liked Outfits": 0,
            "Liked Pieces": 0,
            "Outfits Created": 0,
            "Spruce Outfit": 0,
            "Spruce Outfit Swipe": 0,
            "Viewed Outfit Details": 0,
            "Viewed Piece Details": 0,
            "Viewed Outfit Comments": 0,
            "Viewed Piece Comments": 0
        ])
        
        println("Mixpanel People created for \(username) with id \(id) & alias \(email) for distinctId \(distinctId)")
    }
    
    // Identify user, set Super Properties
    class func setup() {
        // User logged in
        if let userData = defaults.dictionaryForKey("userData") {
            let email: String = userData["email"] as! String
            let id: Int = userData["id"] as! Int
            let username: String = userData["username"] as! String
            
            mixpanel.identify(email)
            mixpanel.registerSuperProperties([
                "User ID": id,
                "Timestamp": NSDate()
            ])
            
            println("MixpanelService.setup: \(username) identified with \(email)")
        } else {
            println("MixpanelService.setup: userData not found, please login or create an account")
        }
    }
    
    // Get user id, -1 if new user
    class func getUserIdWithNewUser() -> Int {
        var currentUserId: Int = -1  // New user (or not logged in)
        
        // User logged in
        if let userData = defaults.dictionaryForKey("userData") {
            let id: Int = userData["id"] as! Int
            currentUserId = id
        }
        return currentUserId
    }
    
    // Track Event
    class func track(eventName: String, propertySet: [String: AnyObject]? = nil) {
        var errorMessage: String = ""
        
        switch eventName {
            
        case "App Launched":
            let id = getUserIdWithNewUser()
            
            mixpanel.track(eventName, properties: [
                "User ID": id,
                "Timestamp": NSDate()
            ])
            
        case "Viewed Signup Page":
            let id = getUserIdWithNewUser()
            
            mixpanel.track(eventName, properties: [
                "User ID": id,
                "Timestamp": NSDate()
            ])
            
        case "User Signed Up":
            if let property = propertySet {
                var id: Int = getUserIdWithNewUser()
                let status: String = property["Status"] as! String
                
                if status == "Success" {
                    id = property["User ID"] as! Int
                }
                
                mixpanel.track(eventName, properties: [
                    "User ID": id,
                    "Status": status,
                    "Timestamp": NSDate()
                ])
            } else {
                errorMessage = "MixpanelService.track: eventName \'\(eventName)\', no data passed"
            }
            
        case "Viewed Main Feed":
            // Only trigger if signed in
            if let userData = defaults.dictionaryForKey("userData") {
                if let property = propertySet {
                    let page: String = property["Page"] as! String
                    
                    mixpanel.track(eventName, properties: ["Page": page])
                } else {
                    errorMessage = "MixpanelService.track: eventName \'\(eventName)\', no data passed"
                }
            }
        
        default:
            errorMessage = "MixpanelService.track: eventName \'\(eventName)\' unavailable, no event tracked"
        }
        
        if errorMessage != "" {
            println (errorMessage)
        }
    }
}

// Mandrill
class MandrillService {
    // Register user for Mixpanel People
    class func register(data: NSDictionary) {
        
        let id: Int = data["id"] as! Int
        let username: String = data["username"] as! String
        
        manager.POST(SprubixConfig.URL.api + "/mail/subaccount/create",
            parameters: [
                "id" : id,
                "name" : username
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                // Print reply from server
                println("Mandrill subaccount created for \(username) with id \(id)")
                
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
        })
    }
}
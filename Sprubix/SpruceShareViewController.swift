//
//  SpruceShareViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 29/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import MRProgress
import FBSDKShareKit
import FBSDKLoginKit
import TSMessages

class SpruceShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, FBSDKSharingDelegate {
    
    var pieces: [NSDictionary]!
    var numPieces: Int!
    
    var userIdFrom: Int!
    var usernameFrom: String!
    var userThumbnailFrom: String!
    
    var outfitImageView:UIImageView! = UIImageView()
    var descriptionCellText: String = ""
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    // table
    var spruceShareTableView:UITableView!
    var outfitImageCell: UITableViewCell = UITableViewCell()
    var creditsCell: UITableViewCell = UITableViewCell()
    var descriptionCell: UITableViewCell = UITableViewCell()
    var socialCell: UITableViewCell = UITableViewCell()
    
    var shareButton: UIButton!
    let creditsViewHeight:CGFloat = 80
    var lastContentOffset:CGFloat = 0
    
    // description
    let descriptionTextHeight: CGFloat = 100
    var descriptionText: UITextView!
    var placeholderText: String = "Tell us more about this outfit!"
    var makeKeyboardVisible = true
    var oldFrameRect: CGRect!
    
    // social button
    var socialButtonFacebook: UIButton!
    let facebookBlue: UIColor = UIColor(red: 65/255, green: 93/255, blue: 174/255, alpha: 1)
    var shareToFacebook: Bool = Bool(false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // table view
        spruceShareTableView = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Plain)
        spruceShareTableView.delegate = self
        spruceShareTableView.dataSource = self
        spruceShareTableView.showsVerticalScrollIndicator = false
        spruceShareTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        view.addSubview(spruceShareTableView)
        
        shareButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
        shareButton.backgroundColor = sprubixColor
        shareButton.titleLabel?.font = UIFont.boldSystemFontOfSize(18.0)
        shareButton.setTitle("Spruce it!", forState: UIControlState.Normal)
        shareButton.addTarget(self, action: "spruceConfirmed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(shareButton)
        
        oldFrameRect = spruceShareTableView.frame
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil);
        
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Good to go?"
        
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
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var currentDistanceMoved:CGFloat = 0
        
        if lastContentOffset > scrollView.contentOffset.y {
            // up
            currentDistanceMoved = lastContentOffset - scrollView.contentOffset.y
            
            outfitImageView.frame.origin.y -= currentDistanceMoved * 0.8
            
        } else if lastContentOffset < scrollView.contentOffset.y {
            // down
            currentDistanceMoved = scrollView.contentOffset.y - lastContentOffset

            outfitImageView.frame.origin.y += currentDistanceMoved * 0.8
        }

        lastContentOffset = scrollView.contentOffset.y
        
        // if image gets covered by bottom cells it goes haywire, 400 = imageheight - 100
        if scrollView.contentOffset.y >= outfitImageView.frame.size.height {
            scrollView.contentOffset.y = outfitImageView.frame.size.height
        } else if scrollView.contentOffset.y <= 0 {
            scrollView.contentOffset.y = 0
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight : CGFloat!
        
        switch(indexPath.row)
        {
        case 0:
            cellHeight = outfitImageView.frame.size.height
        case 1:
            cellHeight = creditsViewHeight // creditsViewHeight
        case 2:
            cellHeight = descriptionTextHeight
        case 3:
            cellHeight = 200 // social share
        default:
            cellHeight = 300
        }
        
        return cellHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch(indexPath.row)
        {
        case 0:
            outfitImageView.clipsToBounds = true
            outfitImageView.backgroundColor = sprubixGray
            outfitImageView.contentMode = UIViewContentMode.ScaleAspectFit
            
            outfitImageCell.addSubview(outfitImageView)
            outfitImageCell.clipsToBounds = true
            
            return outfitImageCell
        case 1:
            let userData:NSDictionary! = defaults.dictionaryForKey("userData")
            
            // init 'posted by' and 'from' credits
            var creditsView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: creditsViewHeight))
            
            var postedByButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "posted by", username: userData["username"] as! String, userThumbnail: userData["image"] as! String)
            var fromButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "inspired by", username: usernameFrom, userThumbnail: userThumbnailFrom)
            
            creditsView.addSubview(postedByButton)
            creditsView.addSubview(fromButton)
            
            creditsCell.addSubview(creditsView)
            
            return creditsCell
        case 2:
            descriptionText = UITextView(frame: CGRectInset(CGRect(x: 0, y: 0, width: screenWidth, height: descriptionTextHeight), 15, 0))
            
            descriptionText.tintColor = sprubixColor
            descriptionText.text = placeholderText
            descriptionText.textColor = UIColor.lightGrayColor()
            descriptionText.font = UIFont(name: descriptionText.font.fontName, size: 17)
            descriptionText.delegate = self
            
            descriptionCell.addSubview(descriptionText)
            
            return descriptionCell
        case 3:
            // Social Label
            let socialLabelY: CGFloat = 10
            let socialLabelHeight: CGFloat = 20
            let socialLabel: UILabel = UILabel(frame: CGRect(x: 20, y: socialLabelY, width: screenWidth, height: socialLabelHeight))
            socialLabel.text = "Share this outfit"
            socialLabel.textColor = UIColor.darkGrayColor()
            
            socialCell.addSubview(socialLabel)
            
            // Facebook
            let socialButtonRow1Y: CGFloat = socialLabelY + socialLabelHeight
            var socialButtonRow1: UIView = UIView(frame: CGRect(x: 0, y: socialButtonRow1Y, width: screenWidth, height: 44))
            
            var socialImageFacebook = UIImage(named: "spruce-share-fb")
            socialImageFacebook = socialImageFacebook!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            
            socialButtonFacebook = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            socialButtonFacebook.setImage(socialImageFacebook, forState: UIControlState.Normal)
            socialButtonFacebook.setTitle("Facebook", forState: UIControlState.Normal)
            socialButtonFacebook.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            socialButtonFacebook.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonFacebook.imageView!.tintColor = UIColor.lightGrayColor()
            socialButtonFacebook.frame = CGRect(x: 0, y: 10, width: screenWidth/2, height: 44)
            socialButtonFacebook.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonFacebook.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonFacebook.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)
            socialButtonFacebook.addTarget(self, action: "facebookTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
            socialButtonRow1.addSubview(socialButtonFacebook)
            
            socialCell.selectionStyle = UITableViewCellSelectionStyle.None
            socialCell.addSubview(socialButtonRow1)
            
            var socialButtonsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
            socialButtonsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            socialCell.addSubview(socialButtonsLineTop)
            
            setSocialButtons()
            
            /*
            // Twitter
            var socialButtonTwitter = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            socialButtonTwitter.setImage(UIImage(named: "spruce-share-twitter"), forState: UIControlState.Normal)
            socialButtonTwitter.setTitle("Twitter", forState: UIControlState.Normal)
            socialButtonTwitter.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            socialButtonTwitter.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonTwitter.frame = CGRect(x: screenWidth / 2, y: 0, width: screenWidth / 2, height: 44)
            socialButtonTwitter.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonTwitter.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonTwitter.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)
        
            socialButtonRow1.addSubview(socialButtonTwitter)
            
            // Tumblr
            var socialButtonRow2:UIView = UIView(frame: CGRect(x: 0, y: 54, width: screenWidth, height: 44))
            
            var socialButtonTumblr = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            socialButtonTumblr.setImage(UIImage(named: "spruce-share-tumblr"), forState: UIControlState.Normal)
            socialButtonTumblr.setTitle("Tumblr", forState: UIControlState.Normal)
            socialButtonTumblr.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            socialButtonTumblr.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonTumblr.frame = CGRect(x: 0, y: 0, width: screenWidth / 2, height: 44)
            socialButtonTumblr.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonTumblr.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonTumblr.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)

            socialButtonRow2.addSubview(socialButtonTumblr)
        
            // Pinterest
            var socialButtonPinterest = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            socialButtonPinterest.setImage(UIImage(named: "spruce-share-pinterest"), forState: UIControlState.Normal)
            socialButtonPinterest.setTitle("Pinterest", forState: UIControlState.Normal)
            socialButtonPinterest.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            socialButtonPinterest.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonPinterest.frame = CGRect(x: screenWidth / 2, y: 0, width: screenWidth / 2, height: 44)
            socialButtonPinterest.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonPinterest.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonPinterest.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)
            
            socialButtonRow2.addSubview(socialButtonPinterest)
            
            socialCell.addSubview(socialButtonRow2)
        
            */

            return socialCell
        default: fatalError("Unknown row in section")
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
                
                self.spruceShareTableView.frame.origin.y = self.oldFrameRect.origin.y - keyboardFrame.height

                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                    }
            })
        } else {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.spruceShareTableView.frame.origin.y = self.oldFrameRect.origin.y
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                        self.makeKeyboardVisible = true
                    }
            })
        }
    }
    
    // UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView.text == placeholderText {
            descriptionText.text = ""
            descriptionText.textColor = UIColor.blackColor()
        }
        
        // stop receiving gestures for outfitImageView
        outfitImageView.userInteractionEnabled = false
        
        var emptyNavItem:UINavigationItem = UINavigationItem()
        emptyNavItem.title = "Outfit Description"
        
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("done", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "descriptionDoneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        emptyNavItem.rightBarButtonItem = nextBarButtonItem
        
        // set
        newNavBar.setItems([emptyNavItem], animated: false)
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" {
            descriptionText.text = placeholderText
            descriptionText.textColor = UIColor.lightGrayColor()
            descriptionText.resignFirstResponder()
        }
        
        outfitImageView.userInteractionEnabled = true
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    func descriptionDoneTapped(sender: UIButton) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }

    func spruceConfirmed(sender: UIButton) {
        let validateResult = self.validateInputs()
        let delay: NSTimeInterval = 3
        
        if validateResult.valid {
            // sprubix outfit dictionary with each piece id
            // new outfit will be created but pieces will be reused
            
            // what we need
            // 1. piece ids
            // 2. outfit image
            // 3. outfit description
            // 4. outfit from (immediate prev person)
            // 5. current user's id (this will be the new posted by)
            
            // create SprubixOutfit
            let userData:NSDictionary! = defaults.dictionaryForKey("userData")
            
            var realHeight: CGFloat = outfitImageView.image!.scale * outfitImageView.image!.size.height
            
            var realWidth: CGFloat = outfitImageView.image!.scale * outfitImageView.image!.size.width
            var finalWidth: CGFloat = 750.0
            var ratio = realWidth / finalWidth
            
            var finalHeight = realHeight / ratio
            
            var spruceOutfitDict: NSMutableDictionary = [
                "num_pieces": numPieces,
                "description": descriptionText.text == placeholderText ? "" : descriptionText.text,
                "created_by": userData["id"] as! Int,
                "from": userIdFrom,
                "height": finalHeight,
                "width": finalWidth,
            ]
            
            var pieceArr: [Int] = [Int]()
            for piece in pieces {
                pieceArr.append(piece["id"] as! Int)
            }
            
            spruceOutfitDict.setObject(pieceArr, forKey: "pieces")
            
            // Mixpanel - Create Outfit Image Upload, Timer
            mixpanel.timeEvent("Create Outfit Image Upload")
            // Mixpanel - End
            
            // upload
            var outfitImageData: NSData = UIImageJPEGRepresentation(outfitImageView.image, 0.9);
            
            var requestOperation: AFHTTPRequestOperation = manager.POST(SprubixConfig.URL.api + "/upload/outfit/spruce", parameters: spruceOutfitDict, constructingBodyWithBlock: { formData in
                let data: AFMultipartFormData = formData
                
                // append outfit image
                data.appendPartWithFileData(outfitImageData, name: "outfit", fileName: "outfit.jpg", mimeType: "image/jpeg")
            }, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                // success block
                //println("Upload Success")

                var response = responseObject as! NSDictionary
                var status = response["status"] as! String
                
                if status == "200" {
                    var outfit = response["outfit"] as! NSDictionary
                    var pieces = outfit["pieces"] as! [NSDictionary]
                    
                    // outfit notification
                    let outfitId = outfit["id"] as! Int
                    let itemIdentifier = "outfit_\(outfitId)"
                    
                    var outfitImagesString = outfit["images"] as! NSString
                    var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                    
                    var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                    var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
                    
                    let thumbnailURLString = outfitImageDict["thumbnail"] as! String
                    let receiverUsername: String = self.usernameFrom
                    
                    self.sendNotification(itemIdentifier, thumbnailURLString: thumbnailURLString, receiverUsername: receiverUsername, poutfitType: "outfit")
                    
                    // unique piece owners dictionary
                    var uniquePieceOwners = NSMutableDictionary()
                    
                    // send notification to each piece owner
                    for piece in pieces {
                        let pieceOwner = piece["user"] as! NSDictionary
                        let pieceOwnerUsername = pieceOwner["username"] as! String
                        
                        // pieceOwner has not been sent notification yet
                        // this is to prevent spamming of multiple pieces to same owner
                        if uniquePieceOwners.objectForKey(pieceOwnerUsername) == nil {
                            self.sendNotification(itemIdentifier, thumbnailURLString: thumbnailURLString, receiverUsername: pieceOwnerUsername, poutfitType: "piece")
                            
                            uniquePieceOwners.setObject(true, forKey: pieceOwnerUsername)
                        }
                    }
                    
                    // Mixpanel - Create Outfit Image Upload, Success
                    mixpanel.track("Create Outfit Image Upload", properties: [
                        "Method": "Closet",
                        "Type": "Outfit",
                        "Status": "Success"
                    ])
                    mixpanel.people.increment("Outfits Created", by: 1)
                    mixpanel.people.increment("Pieces Created", by: self.numPieces)
                    // Mixpanel - End
                    
                    self.returnToMainFeed()
                    
                } else if status == "400" {
                    // error exception
                    TSMessage.showNotificationInViewController(
                        TSMessage.defaultViewController(),
                        title: "Error",
                        subtitle: "Something went wrong.\nPlease try again.",
                        image: UIImage(named: "filter-cross"),
                        type: TSMessageNotificationType.Error,
                        duration: delay,
                        callback: nil,
                        buttonTitle: nil,
                        buttonCallback: nil,
                        atPosition: TSMessageNotificationPosition.Bottom,
                        canBeDismissedByUser: true)
                    
                    // Print reply from server
                    var data = response["data"] as! NSDictionary
                    var message = response["message"] as! String
                    
                    println(message + " " + status)
                    println(data)
                    
                } else if status == "500" {
                    // Mixpanel - Create Outfit Image Upload, Fail
                    mixpanel.track("Create Outfit Image Upload", properties: [
                        "Method": "Closet",
                        "Type": "Outfit",
                        "Status": "Fail"
                    ])
                    // Mixpanel - End
                }

            }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                // failure block
                //println("Upload Fail")
                
                // Mixpanel - Create Outfit Image Upload, Fail
                mixpanel.track("Create Outfit Image Upload", properties: [
                    "Method": "Closet",
                    "Type": "Outfit",
                    "Status": "Fail"
                ])
                // Mixpanel - End
                
                SprubixReachability.handleError(error.code)
            })
            
            // upload progress
            requestOperation.setUploadProgressBlock { (bytesWritten: UInt, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void in
                var percentDone: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                
                println("percentage done: \(percentDone)")
            }
            
            // overlay indicator
            var overlayView: MRProgressOverlayView = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
            overlayView.setModeAndProgressWithStateOfOperation(requestOperation)
            
            overlayView.tintColor = sprubixColor
            
            // Share to Facebook
            if shareToFacebook {
                sharePhotoToFacebook(outfitImageView.image!)

                // Mixpanel - Share, Facebook
                mixpanel.track("Share", properties: [
                    "Type": "Outfit",
                    "Platform": "Facebook"
                ])
                // Mixpanel - End
            }
                
        } else {
            // Validation failed
            TSMessage.showNotificationInViewController(
                self,
                title: "Error",
                subtitle: validateResult.message,
                image: UIImage(named: "filter-cross"),
                type: TSMessageNotificationType.Error,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
        }
    }
    
    private func sendNotification(itemIdentifier: String, thumbnailURLString: String, receiverUsername: String, poutfitType: String) {
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
                    "type": "spruce_\(poutfitType)",
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
    
    func returnToMainFeed() {
        Delay.delay(0.6, closure: {
            // go back to main feed
            self.navigationController!.delegate = nil
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = kCATransitionReveal
            transition.subtype = kCATransitionFromBottom
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
            
            // Goto where the spruceButton is pressed: currentVC - 2 (SpruceShare, SpruceView)
            let vcDesinationIndex = self.navigationController!.viewControllers.count - 3
            
            // Make sure furthest is MainFeed (index 0), but this case shouldn't happen (just checking to make sure)
            if vcDesinationIndex >= 0 {
                self.navigationController!.popToViewController(self.navigationController!.viewControllers[vcDesinationIndex] as! UIViewController, animated: false)
            }
                // Go to MainFeed (furthest)
            else {
                self.navigationController!.popToViewController(self.navigationController!.viewControllers.first as! UIViewController, animated: false)
            }
            
            containerViewController.mainInstance()?.retrieveOutfits(scrollToTop: true)
        })
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
        //delegate?.dismissSpruceView()
    }
    
    func facebookTapped(sender: UIButton) {
        // toggle button to share
        if !shareToFacebook {
            let action = "publish_actions"
            // no token or has token but no permission, request publish permission
            if FBSDKAccessToken.currentAccessToken() == nil || !FBSDKAccessToken.currentAccessToken().hasGranted(action) {
                let loginManager = FBSDKLoginManager()
                loginManager.logInWithPublishPermissions([action], handler: { (response:FBSDKLoginManagerLoginResult!, error: NSError!) in
                    if(error != nil){
                        // Handle error
                        println("FBSDKLogin Error: \(error)")
                    }
                    else if(response.isCancelled){
                        // Authorization has been cancelled by user
                        println("FBSDKLogin Cancelled, permission not granted for: \(action)")
                    }
                    else {
                        // Authorization successful
                        println("FBSDKLogin Successsful, permission granted for: \(response.grantedPermissions)")
                        
                        self.shareToFacebook = true
                        self.setSocialButtons()
                    }
                })
            }
            // has token, has permission, proceed to share
            else {
                println("FBSDKLogin has permission for: \(action)")
                
                self.shareToFacebook = true
                self.setSocialButtons()
            }
        }
        // toggle button to not-share
        else {
            self.shareToFacebook = false
            self.setSocialButtons()
        }
    }
    
    func setSocialButtons() {
        if shareToFacebook {
            socialButtonFacebook.imageView!.tintColor = facebookBlue
            socialButtonFacebook.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        } else {
            socialButtonFacebook.imageView!.tintColor = UIColor.lightGrayColor()
            socialButtonFacebook.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        }
    }
    
    func sharePhotoToFacebook(image: UIImage) {
        let photo: FBSDKSharePhoto = FBSDKSharePhoto()
        photo.image = image
        photo.userGenerated = true
        photo.caption = descriptionText.text
        let content: FBSDKSharePhotoContent = FBSDKSharePhotoContent()
        content.photos = [photo]
        
        FBSDKShareAPI.shareWithContent(content, delegate: self)
    }
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject: AnyObject]) {
        println("FBSDKSharing Photo Sharing Completed:")
        println(results)
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        println("FBSDKSharing Photo Sharing Error:")
        println(error)
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!) {
        println("FBSDKSharing Photo Sharing Cancelled")
    }
    
    func validateInputs() -> (valid: Bool, message: String) {
        var valid: Bool = true
        var message: String = ""
        
        if count(descriptionText.text) > 255 {
            message += "The description is too long\n"
            valid = false
        }
        
        return (valid, message)
    }
}

//
//  SnapshotShareController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 8/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import MRProgress
import ActionSheetPicker_3_0
import FBSDKShareKit
import FBSDKLoginKit
import TSMessages

class SnapshotShareController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, SprubixPieceProtocol, FBSDKSharingDelegate {
    
    var sprubixPieces: [SprubixPiece] = [SprubixPiece]()
    var images: [UIImage]! = [UIImage]()
    var imageViewHeights: [CGFloat] = [CGFloat]()
    var selectedPiecesOrdered: [String] = [String]()
    var outfitImageView: UIImageView!
    var heightPercentages = [CGFloat]()
    let outfitViewHeight = screenWidth / 0.75
    var totalHeight: CGFloat = 0
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    // table 
    var shareTableView: UITableView!
    var outfitImageCell: UITableViewCell = UITableViewCell()
    var creditsCell: UITableViewCell = UITableViewCell()
    var detailsCell: UITableViewCell = UITableViewCell()
    var descriptionCell: UITableViewCell = UITableViewCell()
    var socialCell: UITableViewCell = UITableViewCell()
    
    var shareButton: UIButton!
    let creditsViewHeight:CGFloat = 80
    var lastContentOffset:CGFloat = 0
    
    // details
    let detailsHeight: CGFloat = 55
    var detailsCategory: UIButton!
    var detailsCategoryText: UITextField!
    var outfitCategories: [String] = [String]()
    
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
        
        initTableView()
        initOutfitView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil);
        
        initNavBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Ready to go?"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initTableView() {
        // tableview
        shareTableView = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Plain)
        shareTableView.delegate = self
        shareTableView.dataSource = self
        shareTableView.showsVerticalScrollIndicator = false
        shareTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        shareTableView.userInteractionEnabled = true
        
        self.view.addSubview(shareTableView)
        
        // register method when tapped to hide keyboard
        let tableTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tableTapped:")
        self.view.addGestureRecognizer(tableTapGestureRecognizer)
        
        shareButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
        shareButton.backgroundColor = sprubixColor
        shareButton.titleLabel?.font = UIFont.boldSystemFontOfSize(18.0)
        shareButton.setTitle("Share it!", forState: UIControlState.Normal)
        shareButton.addTarget(self, action: "shareButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view.addSubview(shareButton)
    }
    
    func initOutfitView() {
        // outfit image view
        var totalPieceHeight: CGFloat = 0
        
        // calculate % of height each piece takes
        for imageViewHeight in imageViewHeights {
            var fraction = imageViewHeight / totalHeight
            heightPercentages.append(fraction)
            
            totalPieceHeight += imageViewHeight
        }
        
        // instantiate sprubixPieces
        for var i = 0; i < images.count; i++ {
            images[i] = resizeImage(images[i], width: screenWidth)
            var type = selectedPiecesOrdered[i]
            
            var sprubixPiece = SprubixPiece()
            sprubixPiece.images.append(images[i])
            sprubixPiece.type = type
            
            sprubixPieces.append(sprubixPiece)
        }
        
        if totalPieceHeight > outfitViewHeight {
            totalPieceHeight = outfitViewHeight
        }
        
        outfitImageView = UIImageView(frame: CGRectMake(0, 0, screenWidth, totalPieceHeight))
        outfitImageView.backgroundColor = sprubixGray
        
        oldFrameRect = shareTableView.frame
        
        var yPosition: CGFloat = 0
        let pieceTagIconWidth: CGFloat = 50
        
        // add images to outfitView
        for var i = 0; i < images.count; i++ {
            var height = heightPercentages[i] * outfitImageView.frame.size.height
            var pieceView: UIImageView = UIImageView(frame: CGRectMake(0, yPosition, screenWidth, height))
            
            // add the item tag icon
            let pieceTagIcon: UIImageView = UIImageView(image: UIImage(named: "details-info-add"))
            pieceTagIcon.frame = CGRectMake(screenWidth - pieceTagIconWidth, 0, pieceTagIconWidth, pieceTagIconWidth)
            Glow.addGlow(pieceTagIcon)
            
            pieceView.contentMode = UIViewContentMode.ScaleAspectFit
            pieceView.image = images[i]
            pieceView.addSubview(pieceTagIcon)
            
            yPosition += height
            
            // gesture recognizer
            var singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
            singleTap.numberOfTapsRequired = 1
            
            pieceView.addGestureRecognizer(singleTap)
            pieceView.userInteractionEnabled = true
            outfitImageView.userInteractionEnabled = true
            
            outfitImageView.addSubview(pieceView)
        }
    }
    
    // tableViewDelegate
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
            /*
            cellHeight = detailsHeight
        case 3:
            */
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
            outfitImageView.contentMode = UIViewContentMode.ScaleAspectFill
            
            outfitImageCell.addSubview(outfitImageView)
            outfitImageCell.clipsToBounds = true
            
            return outfitImageCell
        case 1:
            let userData:NSDictionary! = defaults.dictionaryForKey("userData")
            
            // init 'posted by' and 'from' credits
            var creditsView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: creditsViewHeight))
            
            var postedByButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "posted by", username: userData["username"] as! String, userThumbnail: userData["image"] as! String)
            var fromButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "from", username: userData["username"] as! String, userThumbnail: userData["image"] as! String)
            
            creditsView.addSubview(postedByButton)
            creditsView.addSubview(fromButton)
            
            creditsCell.addSubview(creditsView)
            
            return creditsCell
        case 2:
            /*
            // category
            let itemImageViewWidth:CGFloat = 0.3 * screenWidth
            
            var categoryImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            categoryImage.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
            categoryImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            categoryImage.frame = CGRect(x: 0, y: 0, width: itemImageViewWidth, height: detailsHeight)
            categoryImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(categoryImage)
            
            detailsCategory = UIButton(frame: CGRectMake(itemImageViewWidth, 0, screenWidth - itemImageViewWidth, detailsHeight))
            detailsCategoryText = UITextField(frame: CGRectMake(0, 0, screenWidth - itemImageViewWidth, detailsHeight))
            detailsCategoryText.tintColor = sprubixColor
            detailsCategoryText.placeholder = "Add a outfit category!"
            detailsCategoryText.enabled = false
            detailsCategory.addSubview(detailsCategoryText)
            detailsCategory.addTarget(self, action: "itemDetailsCategoryPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            detailsCell.addSubview(categoryImage)
            detailsCell.addSubview(detailsCategory)
            
            return detailsCell
        case 3:
            */
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
            
            socialCell.addSubview(socialButtonRow1)
            
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
    
    // item image tapped
    func handleTap(gesture: UITapGestureRecognizer) {
        var pos = find(images, (gesture.view as! UIImageView).image!)
        
        // pos is not enough, please pass from the beginning, the piece type array
        if pos != nil {
            
            let snapshotDetailsController = SnapshotDetailsController()
            
            snapshotDetailsController.itemCoverImageView.image = (gesture.view as! UIImageView).image!
            snapshotDetailsController.delegate = self
            snapshotDetailsController.pos = pos
            snapshotDetailsController.sprubixPiece = sprubixPieces[pos!]
            
            self.navigationController?.pushViewController(snapshotDetailsController, animated: true)
            
            // Mixpanel - Add Item Details, Camera, Outfit
            mixpanel.track("Add Item Details", properties: [
                "Method": "Camera",
                "Type" : "Outfit"
            ])
            // Mixpanel - End
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
    
    // SprubixPieceProtocol
    func setSprubixPiece(sprubixPiece: SprubixPiece, position: Int) {
        sprubixPieces[position] = sprubixPiece
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
                
                self.shareTableView.frame.origin.y = self.oldFrameRect.origin.y - keyboardFrame.height
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                    }
            })
        } else {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.shareTableView.frame.origin.y = self.oldFrameRect.origin.y
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                        self.makeKeyboardVisible = true
                    }
            })
        }
    }
    
    /**
    * Called when the user click on the view (outside the UITextField).
    */
    func tableTapped(gesture: UITapGestureRecognizer) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }
    
    // Callback Handler: navigation bar back button
    func backTapped(sender: UIBarButtonItem) {
        var alert = UIAlertController(title: "Are you sure?", message: "Changes made to the current outfit will be lost", preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = sprubixColor
        
        // Yes
        alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: UIAlertActionStyle.Default, handler: { action in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        // No
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func itemDetailsCategoryPressed(sender: UIButton) {
        ActionSheetStringPicker.showPickerWithTitle("Choose a category", rows: outfitCategories, initialSelection: 2,
            doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                
                self.detailsCategoryText.text = "\(selectedValue)"
                
            }, cancelBlock: nil, origin: sender)
    }
    
    func shareButtonPressed(sender: UIButton) {
        let validateResult = self.validateInputs()
        let delay: NSTimeInterval = 3
        
        if validateResult.valid {
            
            var width: CGFloat = screenWidth
            var totalHeight: CGFloat = 0
            
            // calculate totalHeight
            for image in images {
                var newImageHeight = image.size.height * width / image.size.width
                
                totalHeight += newImageHeight
            }
            
            // create the merged outfit image (all pieces into one)
            var size:CGSize = CGSizeMake(width, totalHeight)
            var prevHeight:CGFloat = 0
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0) // avoid image quality degrading
            
            for image in images {
                var newImageHeight = image.size.height * width / image.size.width
                
                image.drawInRect(CGRectMake(0, prevHeight, size.width, newImageHeight))
                
                prevHeight += newImageHeight
            }
            
            // final image
            var outfitImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()

            // create SprubixOutfit
            let userData:NSDictionary! = defaults.dictionaryForKey("userData")
            
            var sprubixOutfitDict: NSMutableDictionary = [
                "num_pieces": sprubixPieces.count,
                "description": descriptionText.text,
                "created_by": userData["username"] as! String,
                "from": userData["username"] as! String,
                "user_id": userData["id"] as! Int,
                "height": outfitImage.scale * outfitImage.size.height,
                "width": outfitImage.scale * outfitImage.size.width
            ]
            
            var pieces: NSMutableDictionary = NSMutableDictionary()
            for sprubixPiece in sprubixPieces {
                var pieceDict: NSMutableDictionary = NSMutableDictionary()
                pieceDict.setObject(sprubixPiece.images.count, forKey: "num_images")
                pieceDict.setObject(sprubixPiece.name != nil ? sprubixPiece.name : "", forKey: "name")
                pieceDict.setObject(sprubixPiece.category != nil ? sprubixPiece.category : "", forKey: "category")
                pieceDict.setObject(sprubixPiece.type, forKey: "type")
                pieceDict.setObject(sprubixPiece.isDress, forKey: "is_dress")
                pieceDict.setObject(sprubixPiece.brand != nil ? sprubixPiece.brand : "", forKey: "brand")
                pieceDict.setObject(sprubixPiece.price != nil ? sprubixPiece.price : "", forKey: "price")
                pieceDict.setObject(sprubixPiece.desc != nil ? sprubixPiece.desc : "", forKey: "description")
                pieceDict.setObject(sprubixPiece.images[0].scale * sprubixPiece.images[0].size.height, forKey: "height")
                pieceDict.setObject(sprubixPiece.images[0].scale * sprubixPiece.images[0].size.width, forKey: "width")
                pieceDict.setObject(sprubixPiece.size != nil ? sprubixPiece.size : "", forKey: "size")
                
                if sprubixPiece.quantity != nil {
                    pieceDict.setObject(sprubixPiece.quantity, forKey: "quantity")
                }
                
                pieces.setObject(pieceDict, forKey: sprubixPiece.type.lowercaseString)
            }
            
            sprubixOutfitDict.setObject(pieces, forKey: "pieces")
            
            // Mixpanel - Create Outfit Image Upload, Timer
            mixpanel.timeEvent("Create Outfit Image Upload")
            // Mixpanel - End
            
            // upload:
            // 1. outfit finalimage
            // 2. piece images for each sprubixPiece
            // 3. sprubixOutfit information (parameters)
            // 4. sprubixPiece information (parameters)
            
            var outfitImageData: NSData = UIImageJPEGRepresentation(outfitImage, 0.5);
            
            var requestOperation: AFHTTPRequestOperation = manager.POST(SprubixConfig.URL.api + "/upload/outfit/create", parameters: sprubixOutfitDict, constructingBodyWithBlock: { formData in
                let data: AFMultipartFormData = formData
                
                // append outfit image
                data.appendPartWithFileData(outfitImageData, name: "outfit", fileName: "outfit.jpg", mimeType: "image/jpeg")
                
                // append piece images
                for var i = 0; i < self.sprubixPieces.count; i++ {
                    var sprubixPiece = self.sprubixPieces[i]
                    
                    for var j = 0; j < sprubixPiece.images.count; j++ {
                        var pieceImage: UIImage = sprubixPiece.images[j]
                        var pieceImageData: NSData = UIImageJPEGRepresentation(pieceImage, 0.5)
                        
                        var pieceImageName = "piece_\(sprubixPiece.type.lowercaseString)_\(j)"
                        var pieceImageFileName = pieceImageName + ".jpg"
                        
                        data.appendPartWithFileData(pieceImageData, name: pieceImageName, fileName: pieceImageFileName, mimeType: "image/jpeg")
                    }
                }
                
                }, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    // success block
                    var response = responseObject as! NSDictionary
                    var status = response["status"] as! String
                    
                    if status == "200" {
                        println("Upload Success")
                        
                        self.delay(0.6) {
                            // go back to main feed
                            self.navigationController!.delegate = nil
                            
                            let transition = CATransition()
                            transition.duration = 0.3
                            transition.type = kCATransitionReveal
                            transition.subtype = kCATransitionFromBottom
                            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                            
                            self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
                            self.navigationController?.popToViewController(self.navigationController?.viewControllers.first! as! UIViewController, animated: false)
                        }
                        
                        // Mixpanel - Create Outfit Image Upload, Success
                        mixpanel.track("Create Outfit Image Upload", properties: [
                            "Method": "Camera",
                            "Type" : "Outfit",
                            "Status": "Success"
                        ])
                        mixpanel.people.increment("Outfits Created", by: 1)
                        mixpanel.people.increment("Pieces Created", by: self.sprubixPieces.count)
                        // Mixpanel - End
                        
                    } else {
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
                        var message = response["message"] as! String
                        var data = response["data"] as! NSDictionary
                        
                        println(message + " " + status)
                        println(data)
                    }
                    
                }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    // failure block
                    println("Upload Fail")
                    
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
                    
                    // Mixpanel - Create Outfit Image Upload, Fail
                    mixpanel.track("Create Outfit Image Upload", properties: [
                        "Method": "Camera",
                        "Type" : "Outfit",
                        "Status": "Fail"
                    ])
                    // Mixpanel - End
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
                sharePhotoToFacebook(outfitImage)
                
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
    
    func resizeImage(image: UIImage, width: CGFloat) -> UIImage {
        var newImageHeight = image.size.height * width / image.size.width
        
        var size: CGSize = CGSizeMake(width, newImageHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0) // avoid image quality degrading
        
        image.drawInRect(CGRectMake(0, 0, width, newImageHeight))
        
        // final image
        let finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return finalImage
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
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
        
        // All pieces must have a category
        var allHaveCategory: Bool = true
        
        for sprubixPiece in sprubixPieces {
            if sprubixPiece.category == nil {
                allHaveCategory = false
            }
        }
        
        if allHaveCategory == false {
            message += "Please choose a category for all the items\n"
            valid = false
        }
        
        // If description is placeholder text, remove it
        if descriptionText.text == placeholderText {
            descriptionText.text = ""
        }
        
        if count(descriptionText.text) > 255 {
            message += "The description is too long\n"
            valid = false
        }
        
        return (valid, message)
    }
}

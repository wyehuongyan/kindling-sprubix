//
//  SnapshotShareController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 8/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SnapshotShareController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, SprubixPieceProtocol {
    
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
    var descriptionCell: UITableViewCell = UITableViewCell()
    var socialCell: UITableViewCell = UITableViewCell()
    
    var shareButton: UIButton!
    let creditsViewHeight:CGFloat = 80
    var lastContentOffset:CGFloat = 0
    
    // description
    let descriptionTextHeight: CGFloat = 100
    var descriptionText: UITextView!
    var placeholderText: String = "Tell us more about this outfit!"
    var keyboardVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
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
        shareButton.setTitle("Share it!", forState: UIControlState.Normal)
        shareButton.addTarget(self, action: "shareButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view.addSubview(shareButton)
        
        // outfit image view
        var totalPieceHeight: CGFloat = 0
        
        // calculate % of height each piece takes
        for imageViewHeight in imageViewHeights {
            var fraction = imageViewHeight / totalHeight
            heightPercentages.append(fraction)
            
            totalPieceHeight += imageViewHeight
        }
        
        if totalPieceHeight > outfitViewHeight {
            totalPieceHeight = outfitViewHeight
        }
        
        outfitImageView = UIImageView(frame: CGRectMake(0, 0, screenWidth, totalPieceHeight))
        outfitImageView.backgroundColor = sprubixGray
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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

        var yPosition: CGFloat = 0
        let pieceTagIconWidth: CGFloat = 50
        
        // add images to outfitView
        for var i = 0; i < images.count; i++ {
            var height = heightPercentages[i] * outfitImageView.frame.size.height
            var pieceView: UIImageView = UIImageView(frame: CGRectMake(0, yPosition, screenWidth, height))
            
            // add the item tag icon
            var pieceTagIcon: UIImageView = UIImageView(image: UIImage(named: "details-info-add"))
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
            
            // sprubixPieces
            sprubixPieces.append(SprubixPiece())
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
            //outfitImageView = UIImageView(image: UIImage(named: "person-placeholder.jpg"))
            //outfitImageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 500)
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
            descriptionText = UITextView(frame: CGRectInset(CGRect(x: 0, y: 0, width: screenWidth, height: descriptionTextHeight), 15, 0))
            
            descriptionText.tintColor = sprubixColor
            descriptionText.text = placeholderText
            descriptionText.textColor = UIColor.lightGrayColor()
            descriptionText.font = UIFont(name: descriptionText.font.fontName, size: 16)
            descriptionText.delegate = self
            
            descriptionCell.addSubview(descriptionText)
            
            return descriptionCell
        case 3:
            // Facebook
            var socialButtonRow1:UIView = UIView(frame: CGRect(x: 0, y: 10, width: screenWidth, height: 44))
            
            var socialButtonFacebook = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            socialButtonFacebook.setImage(UIImage(named: "spruce-share-fb"), forState: UIControlState.Normal)
            socialButtonFacebook.setTitle("Facebook", forState: UIControlState.Normal)
            socialButtonFacebook.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            socialButtonFacebook.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonFacebook.frame = CGRect(x: 0, y: 0, width: screenWidth / 2, height: 44)
            socialButtonFacebook.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonFacebook.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonFacebook.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)
            
            socialButtonRow1.addSubview(socialButtonFacebook)
            
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
            
            var socialButtonsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
            socialButtonsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            socialCell.addSubview(socialButtonsLineTop)
            
            return socialCell
        default: fatalError("Unknown row in section")
        }
    }
    
    // item image tapped
    func handleTap(gesture: UITapGestureRecognizer) {
        var pos = find(images, (gesture.view as! UIImageView).image!)
        
        // pos is not enough, please pass from the beginning, the piece type array
        if pos != nil {
            
            var snapshotDetailsController = SnapshotDetailsController()
            snapshotDetailsController.itemCoverImageView.image = (gesture.view as! UIImageView).image!
            snapshotDetailsController.itemCategory = selectedPiecesOrdered[pos!]
            snapshotDetailsController.delegate = self
            snapshotDetailsController.pos = pos
            snapshotDetailsController.sprubixPiece = sprubixPieces[pos!]
            
            self.navigationController?.pushViewController(snapshotDetailsController, animated: true)
        }
    }
    
    func heightForTextLabel(text:String, width:CGFloat, padding: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.text = text
        
        label.sizeToFit()
        return label.frame.height + padding
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
        if textView.text == "" {
            descriptionText.text = placeholderText
            descriptionText.textColor = UIColor.lightGrayColor()
            descriptionText.resignFirstResponder()
        }
        
        outfitImageView.userInteractionEnabled = true
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    func descriptionDoneTapped(sender: UIButton) {
        self.view.endEditing(true)
    }
    
    // SprubixPieceProtocol
    func setSprubixPiece(sprubixPiece: SprubixPiece, position: Int) {
        sprubixPieces[position] = sprubixPiece
        
        println((sprubixPieces[position].images).count)
        println(sprubixPieces[position].name)
        println(sprubixPieces[position].category)
        println(sprubixPieces[position].brand)
        println(sprubixPieces[position].size)
        println(sprubixPieces[position].desc)
    }
    
    /**
    * Handler for keyboard show event
    */
    func keyboardWillShow(notification: NSNotification) {
        if !keyboardVisible {
            var info = notification.userInfo!
            var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.shareTableView.frame.origin.y -= keyboardFrame.height
                self.keyboardVisible = true
                
                }, completion: nil)
        }
    }
    
    /**
    * Handler for keyboard hide event
    */
    func keyboardWillHide(notification: NSNotification) {
        if keyboardVisible {
            var info = notification.userInfo!
            var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.shareTableView.frame.origin.y += keyboardFrame.height
                self.keyboardVisible = false
                
                }, completion: nil)
        }
    }
    
    /**
    * Called when the user click on the view (outside the UITextField).
    */
    func tableTapped(gesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    /**
    * Called when 'return' key pressed. return NO to ignore.
    */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
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
    
    func shareButtonPressed(sender: UIButton) {
        var width: CGFloat = 600
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
        var finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        println(finalImage)

    }
}

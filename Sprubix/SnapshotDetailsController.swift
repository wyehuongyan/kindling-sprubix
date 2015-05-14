//
//  SnapshotDetailsController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SprubixItemThumbnail: UIButton {
    var hasThumbnail: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, thumbnail: String = "icon-placeholder.png") {
        self.init()
        
        self.setImage(UIImage(named: thumbnail), forState: UIControlState.Normal)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol SprubixPieceProtocol {
    func setSprubixPiece(sprubixPiece: SprubixPiece, position: Int)
}

class SnapshotDetailsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate, SprubixCameraDelegate {
    
    var delegate: SnapshotShareController?
    var pos: Int!
    var sprubixPiece: SprubixPiece!
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    // item
    var itemCoverImageView: UIImageView = UIImageView()
    var itemCategory: String!
    
    // camera
    var cameraCapture: UIButton!
    var cameraPreview: UIView?
    var preview: AVCaptureVideoPreviewLayer?
    var camera: SprubixCamera?
    
    // tableview cells
    var itemTableView: UITableView!
    var itemImageCell: UITableViewCell = UITableViewCell()
    var itemThumbnailsCell: UITableViewCell = UITableViewCell()
    var itemDetailsCell: UITableViewCell = UITableViewCell()
    var itemDescriptionCell: UITableViewCell = UITableViewCell()
    
    // description
    let descriptionTextHeight: CGFloat = 100
    var descriptionText: UITextView!
    var placeholderText: String = "Tell us more about this item!"
    var keyboardVisible = false
    
    // thumbnails
    var thumbnails: [SprubixItemThumbnail] = [SprubixItemThumbnail]()
    var hasThumbnails: [SprubixItemThumbnail] = [SprubixItemThumbnail]()
    let thumbnailViewWidth: CGFloat = (screenWidth - 20) / 4
    var selectedThumbnail: SprubixItemThumbnail!
    
    // itemDetails textfields
    var pieceSpecsView:UIView!
    var itemDetailsName: UITextField!
    var itemDetailsCategory: UITextField!
    var itemDetailsBrand: UITextField!
    var itemDetailsSize: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        // table
        itemTableView = UITableView(frame: CGRectMake(0, navigationHeight, screenWidth, screenHeight - navigationHeight))
        itemTableView.delegate = self
        itemTableView.dataSource = self
        itemTableView.showsVerticalScrollIndicator = false
        itemTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        itemTableView.userInteractionEnabled = true
        
        // register method when tapped to hide keyboard
        let tableTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tableTapped:")
        self.view.addGestureRecognizer(tableTapGestureRecognizer)
        
        self.view.addSubview(itemTableView)
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
        newNavItem.title = "Item Details"
        
        // 4. create a cancel button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        backButton.setTitle("cancel", forState: UIControlState.Normal)
        backButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.addTarget(self, action: "cancelTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("done", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "doneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.camera?.stopCamera()
    }
    
    // camera
    func initializeCamera() {
        self.camera = SprubixCamera(sender: self)
    }
    
    func establishVideoPreviewArea() {
        if cameraPreview != nil {
            var touch = UITapGestureRecognizer(target:self, action:"manualFocus:")
            cameraPreview!.addGestureRecognizer(touch)
            cameraPreview!.alpha = 1.0
        
            self.preview = AVCaptureVideoPreviewLayer(session: self.camera?.session)
            self.preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.preview?.frame = self.cameraPreview!.bounds
            self.cameraPreview!.layer.addSublayer(self.preview)
        }
    }
    
    // tap to focus
    func manualFocus(gesture :UITapGestureRecognizer) {
        var touchPoint: CGPoint = gesture.locationInView(gesture.view)
        
        self.camera?.focus(touchPoint, preview: self.preview!)
    }
    
    func captureFrame(sender: AnyObject) {
        // this is the part where image is captured successfully
        self.cameraCapture.enabled = false
        self.itemCoverImageView.alpha = 0.0
        
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview!.alpha = 0.0
        })
        
        self.camera?.captureStillImage({ (image) -> Void in
            if image != nil {
                // crop image to square
                var fixedImage: UIImage = self.fixOrientation(image!)
                
                var cropCenter: CGPoint = CGPointMake((fixedImage.size.width / 2), (fixedImage.size.height / 2));
                var cropStart: CGPoint = CGPointMake((cropCenter.x - fixedImage.size.width / 2), (cropCenter.y - fixedImage.size.width / 2));
                let cropRect: CGRect = CGRectMake(cropStart.x, cropStart.y, fixedImage.size.width, fixedImage.size.width);
                
                let cropRef: CGImageRef = CGImageCreateWithImageInRect(fixedImage.CGImage, cropRect);
                let cropImage: UIImage = UIImage(CGImage: cropRef)!
                
                self.selectedThumbnail.setImage(cropImage, forState: UIControlState.Normal)
                self.selectedThumbnail.hasThumbnail = true
                self.itemCoverImageView.image = cropImage
                self.itemCoverImageView.alpha = 1.0

                self.itemTableView.scrollEnabled = true
                self.pieceSpecsView.alpha = 1.0
                self.cameraCapture.alpha = 0.0
                self.itemDescriptionCell.alpha = 1.0
                
                self.cameraCapture.enabled = true
                
                self.newNavBar.setItems([self.newNavItem], animated: true)
            } else {
                NSLog("Uh oh! Something went wrong. Try it again.")
            }
        })
    }
    
    // fix image orientation
    func fixOrientation(img: UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.Up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.drawInRect(rect)
        
        var normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage;
        
    }
    
    // MARK: Camera Delegate
    func cameraSessionConfigurationDidComplete() {
        self.camera?.startCamera()
    }
    
    func cameraSessionDidBegin() {
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview!.alpha = 1.0
        })
    }
    
    func cameraSessionDidStop() {
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview!.alpha = 0.0
        })
    }
    
    // tableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight : CGFloat!
        
        switch(indexPath.row)
        {
        case 0:
            cellHeight = screenWidth
        case 1:
            cellHeight = thumbnailViewWidth + 20 // itemThumbnails
        case 2:
            cellHeight = 230 // itemDetails
        case 3:
            cellHeight = descriptionTextHeight // description
        default:
            cellHeight = 300
        }
        
        return cellHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch(indexPath.row)
        {
        case 0:
            itemCoverImageView.frame = CGRectMake(0, 0, screenWidth, screenWidth)
            itemCoverImageView.contentMode = UIViewContentMode.ScaleAspectFit
            itemCoverImageView.backgroundColor = sprubixGray

            // camera view is at the same location as itemCover
            cameraPreview = UIView(frame: itemCoverImageView.frame)
            cameraPreview!.alpha = 0
            
            itemImageCell.addSubview(itemCoverImageView)
            itemImageCell.addSubview(cameraPreview!)
            itemImageCell.backgroundColor = sprubixGray
            
            return itemImageCell
            
        case 1:
            
            for var i = 0; i < 4; i++ {
                var thumbnailView: SprubixItemThumbnail = SprubixItemThumbnail.buttonWithType(UIButtonType.Custom) as! SprubixItemThumbnail
                
                if i == 0 {
                    // first one
                    thumbnailView.setImage(itemCoverImageView.image, forState: UIControlState.Normal)
                    thumbnailView.hasThumbnail = true
                } else {
                    if sprubixPiece.images.count > i {
                        thumbnailView.setImage(sprubixPiece.images[i], forState: UIControlState.Normal)
                        thumbnailView.hasThumbnail = true
                    } else {
                        thumbnailView.setImage(UIImage(named: "details-thumbnail-add"), forState: UIControlState.Normal)
                    }
                }
                
                // tap gesture recognizer
                var singleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
                singleTapGestureRecognizer.numberOfTapsRequired = 1
                
                thumbnailView.addGestureRecognizer(singleTapGestureRecognizer)
                
                thumbnailView.frame = CGRectMake(CGFloat(i) * thumbnailViewWidth, 0, thumbnailViewWidth, thumbnailViewWidth)
                thumbnailView.imageEdgeInsets = UIEdgeInsetsMake(20, 20, 0, 0) // top left bottom right
                thumbnailView.contentMode = UIViewContentMode.ScaleAspectFit
                
                thumbnails.append(thumbnailView)
                
                itemThumbnailsCell.addSubview(thumbnailView)
            }
            
            return itemThumbnailsCell
            
        case 2:
            // init piece specifications
            let itemSpecHeight:CGFloat = 55
            let itemSpecHeightTotal:CGFloat = itemSpecHeight * 4
            
            pieceSpecsView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: itemSpecHeightTotal))
            pieceSpecsView.backgroundColor = UIColor.whiteColor()
            
            // generate 4 labels with icons
            let itemImageViewWidth:CGFloat = 0.3 * screenWidth
            
            // name
            var itemNameImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemNameImage.setImage(UIImage(named: "view-item-name"), forState: UIControlState.Normal)
            itemNameImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemNameImage.frame = CGRect(x: 0, y: 0, width: itemImageViewWidth, height: itemSpecHeight)
            itemNameImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemNameImage)
            
            itemDetailsName = UITextField(frame: CGRectMake(itemImageViewWidth, 0, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsName.tintColor = sprubixColor
            itemDetailsName.placeholder = "Name of your item?"
            itemDetailsName.returnKeyType = UIReturnKeyType.Done
            itemDetailsName.delegate = self

            if sprubixPiece.name != nil {
                itemDetailsName.text = sprubixPiece.name
            }
            
            // category
            var itemCategoryImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemCategoryImage.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
            itemCategoryImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemCategoryImage.frame = CGRect(x: 0, y: itemSpecHeight, width: itemImageViewWidth, height: itemSpecHeight)
            itemCategoryImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemCategoryImage)
            
            itemDetailsCategory = UITextField(frame: CGRectMake(itemImageViewWidth, itemSpecHeight, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsCategory.tintColor = sprubixColor
            itemDetailsCategory.placeholder = "Which category is it from?" // user cannot enter, it will be decided by system
            itemDetailsCategory.text = itemCategory.lowercaseString.capitalizeFirst
            itemDetailsCategory.enabled = false
            itemDetailsCategory.returnKeyType = UIReturnKeyType.Done
            itemDetailsCategory.delegate = self
            
            // brand
            var itemBrandImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemBrandImage.setImage(UIImage(named: "view-item-brand"), forState: UIControlState.Normal)
            itemBrandImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemBrandImage.frame = CGRect(x: 0, y: itemSpecHeight * 2, width: itemImageViewWidth, height: itemSpecHeight)
            itemBrandImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemBrandImage)
            
            itemDetailsBrand = UITextField(frame: CGRectMake(itemImageViewWidth, itemSpecHeight * 2, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsBrand.tintColor = sprubixColor
            itemDetailsBrand.placeholder = "What brand is it?"
            itemDetailsBrand.returnKeyType = UIReturnKeyType.Done
            itemDetailsBrand.delegate = self
            
            if sprubixPiece.brand != nil {
                itemDetailsBrand.text = sprubixPiece.brand
            }
            
            // size
            var itemSizeImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemSizeImage.setImage(UIImage(named: "view-item-size"), forState: UIControlState.Normal)
            itemSizeImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemSizeImage.frame = CGRect(x: 0, y: itemSpecHeight * 3, width: itemImageViewWidth, height: itemSpecHeight)
            itemSizeImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemSizeImage)
            
            itemDetailsSize = UITextField(frame: CGRectMake(itemImageViewWidth, itemSpecHeight * 3, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsSize.tintColor = sprubixColor
            itemDetailsSize.placeholder = "What are the measurements?"
            itemDetailsSize.returnKeyType = UIReturnKeyType.Done
            itemDetailsSize.delegate = self
            
            if sprubixPiece.size != nil {
                itemDetailsSize.text = sprubixPiece.size
            }
            
            pieceSpecsView.addSubview(itemNameImage)
            pieceSpecsView.addSubview(itemDetailsName)
            
            pieceSpecsView.addSubview(itemCategoryImage)
            pieceSpecsView.addSubview(itemDetailsCategory)
            
            pieceSpecsView.addSubview(itemBrandImage)
            pieceSpecsView.addSubview(itemDetailsBrand)
            
            pieceSpecsView.addSubview(itemSizeImage)
            pieceSpecsView.addSubview(itemDetailsSize)
            
            itemDetailsCell.addSubview(pieceSpecsView)
            
            // cameraCapture button
            let cameraCaptureWidth: CGFloat = 100
            cameraCapture = UIButton(frame: CGRectMake(screenWidth / 2 - cameraCaptureWidth / 2, 0, cameraCaptureWidth, cameraCaptureWidth))
            cameraCapture.backgroundColor = sprubixColor
            cameraCapture.alpha = 0.0
            cameraCapture.addTarget(self, action: "captureFrame:", forControlEvents: UIControlEvents.TouchUpInside)
            cameraCapture.exclusiveTouch = true
            cameraCapture.layer.cornerRadius = cameraCaptureWidth / 2
            cameraCapture.setTitle("Snap!", forState: UIControlState.Normal)
            cameraCapture.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            
            itemDetailsCell.addSubview(cameraCapture)
            
            return itemDetailsCell
            
        case 3:
            descriptionText = UITextView(frame: CGRectInset(CGRect(x: 0, y: 0, width: screenWidth, height: descriptionTextHeight), 15, 0))
            
            descriptionText.tintColor = sprubixColor
            
            if sprubixPiece.desc != nil {
                descriptionText.text = sprubixPiece.desc
            } else if descriptionText.text == "" {
                descriptionText.text = placeholderText
                descriptionText.textColor = UIColor.lightGrayColor()
            }
            
            descriptionText.font = UIFont(name: descriptionText.font.fontName, size: 16)
            descriptionText.delegate = self
            
            itemDescriptionCell.addSubview(descriptionText)
            
            return itemDescriptionCell
            
        default: fatalError("Unknown row in section")
        }
    }
    
    // thumbnail tap gesture recognizer
    func handleTap(gesture: UITapGestureRecognizer) {
        
        selectedThumbnail = gesture.view as! SprubixItemThumbnail
        
        if selectedThumbnail.hasThumbnail != true {
            cameraPreview!.alpha = 1.0
            
            // show the needed items
            itemTableView.scrollRectToVisible(itemCoverImageView.frame, animated: true)
            itemTableView.scrollEnabled = false
            pieceSpecsView.alpha = 0.0
            cameraCapture.alpha = 1.0
            itemDescriptionCell.alpha = 0.0
            
            setNavBar("Add Image", leftButtonTitle: "cancel", leftButtonCallback: "addImageCancelTapped:", rightButtonTitle: "", rightButtonCallback: nil)
            
            if camera == nil {
                // activate camera mode (square)
                initializeCamera()
                establishVideoPreviewArea()
            }
        } else {
            itemCoverImageView.image = selectedThumbnail.imageView?.image
        }
    }
    
    func setNavBar(title: String, leftButtonTitle: String, leftButtonCallback: Selector, rightButtonTitle: String, rightButtonCallback: Selector) {
        // create a new navbar
        var emptyNavItem:UINavigationItem = UINavigationItem()
        emptyNavItem.title = title
        
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        cancelButton.setTitle(leftButtonTitle, forState: UIControlState.Normal)
        cancelButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        cancelButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        cancelButton.addTarget(self, action: leftButtonCallback, forControlEvents: UIControlEvents.TouchUpInside)
        
        var cancelBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: cancelButton)
        emptyNavItem.leftBarButtonItem = cancelBarButtonItem

        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle(rightButtonTitle, forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: rightButtonCallback, forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        emptyNavItem.rightBarButtonItem = nextBarButtonItem
        
        // set
        newNavBar.setItems([emptyNavItem], animated: false)

    }
    
    func addImageCancelTapped(sender: UIButton) {
        itemCoverImageView.alpha = 1.0
        
        itemTableView.scrollEnabled = true
        pieceSpecsView.alpha = 1.0
        cameraPreview!.alpha = 0.0
        cameraCapture.alpha = 0.0
        itemDescriptionCell.alpha = 1.0
        
        cameraCapture.enabled = true
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    // UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView.text == placeholderText {
            descriptionText.text = ""
            descriptionText.textColor = UIColor.blackColor()
        }
        
        setNavBar("Item Description", leftButtonTitle: "", leftButtonCallback: nil, rightButtonTitle: "done", rightButtonCallback: "descriptionDoneTapped:")
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            descriptionText.text = placeholderText
            descriptionText.textColor = UIColor.lightGrayColor()
            descriptionText.resignFirstResponder()
        }
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    func descriptionDoneTapped(sender: UIButton) {
        self.view.endEditing(true)
    }
    
    /**
    * Handler for keyboard show event
    */
    func keyboardWillShow(notification: NSNotification) {
        if !keyboardVisible {
            var info = notification.userInfo!
            var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.itemTableView.frame.origin.y -= keyboardFrame.height
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
                
                self.itemTableView.frame.origin.y += keyboardFrame.height
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
    func cancelTapped(sender: UIBarButtonItem) {
        var alert = UIAlertController(title: "Are you sure?", message: "Changes made to the current item will be lost", preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = sprubixColor
        
        // Yes
        alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: UIAlertActionStyle.Default, handler: { action in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        // No
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func doneTapped(sender: UIBarButtonItem) {
        sprubixPiece.images.removeAll()
        
        for thumbnail in thumbnails {
            if thumbnail.hasThumbnail {
                sprubixPiece.images.append(thumbnail.imageView!.image!)
            }
        }
        
        // item details
        sprubixPiece.name = itemDetailsName.text
        sprubixPiece.category = itemDetailsCategory.text
        sprubixPiece.brand = itemDetailsBrand.text
        sprubixPiece.size = itemDetailsSize.text
        sprubixPiece.desc = descriptionText.text
        
        delegate?.setSprubixPiece(sprubixPiece, position: pos)
        self.navigationController?.popViewControllerAnimated(true)
    }
}
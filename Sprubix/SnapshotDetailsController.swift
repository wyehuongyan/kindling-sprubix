//
//  SnapshotDetailsController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import MRProgress
import PermissionScope
import ActionSheetPicker_3_0
import MLPAutoCompleteTextField

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

class SnapshotDetailsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate, SprubixCameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let cameraPscope = PermissionScope()
    let photoPscope = PermissionScope()
    
    var delegate: SprubixPieceProtocol?
    var pos: Int!
    var sprubixPiece: SprubixPiece!
    var onlyOnePiece: Bool = false
    var addToClosetButton: UIButton?
    
    let imagePicker = UIImagePickerController()
    var photoLibraryButton: UIButton!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    // item
    var itemCoverImageView: UIImageView = UIImageView()
    var itemCategories: [String] = [String]()
    
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
    var makeKeyboardVisible = true
    var oldFrameRect: CGRect!
    
    // thumbnails
    var thumbnails: [SprubixItemThumbnail] = [SprubixItemThumbnail]()
    var hasThumbnails: [SprubixItemThumbnail] = [SprubixItemThumbnail]()
    let thumbnailViewWidth: CGFloat = (screenWidth - 100) / 4
    var selectedThumbnail: SprubixItemThumbnail!
    
    // itemDetails textfields
    var pieceSpecsView: UIView!
    var itemDetailsName: UITextField!
    var itemDetailsCategory: UIButton!
    var itemDetailsCategoryText: UITextField!
    var itemDetailsBrand: MLPAutoCompleteTextField!
    var itemDetailsSize: UITextField!
    var itemIsDress: Bool = false
    var itemSpecHeightTotal: CGFloat = 220
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
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
        
        oldFrameRect = itemTableView.frame
        
        // initialized permissions
        cameraPscope.addPermission(PermissionConfig(type: .Camera, demands: .Required, message: "We need this so you can snap\r\nawesome pictures of your items!", notificationCategories: .None))
        
        cameraPscope.tintColor = sprubixColor
        cameraPscope.headerLabel.text = "Hey there,"
        cameraPscope.headerLabel.textColor = UIColor.darkGrayColor()
        cameraPscope.bodyLabel.textColor = UIColor.lightGrayColor()
        
        photoPscope.addPermission(PermissionConfig(type: .Photos, demands: .Required, message: "We need this so you can import\r\nawesome pictures of your items!", notificationCategories: .None))
        
        photoPscope.tintColor = sprubixColor
        photoPscope.headerLabel.text = "Hey there,"
        photoPscope.headerLabel.textColor = UIColor.darkGrayColor()
        photoPscope.bodyLabel.textColor = UIColor.lightGrayColor()
        
        if onlyOnePiece {
            addToClosetButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
            addToClosetButton!.backgroundColor = sprubixColor
            addToClosetButton!.setTitle("Add to Closet!", forState: UIControlState.Normal)
            addToClosetButton!.addTarget(self, action: "addToClosetPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            self.view.addSubview(addToClosetButton!)
        }
        
        retrieveItemCategories()
    }
    
    private func retrieveItemCategories() {
        if itemCategories.count <= 0 {
            // REST call to retrieve piece categories
            manager.GET(SprubixConfig.URL.api + "/piece/categories",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    var categories = responseObject as? [NSDictionary]
                    
                    if categories != nil {
                        for category in categories! {
                            var categoryName = category["name"] as? String
                            
                            self.itemCategories.append(categoryName!)
                        }
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil)
        
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
        
        if onlyOnePiece != true {
            // 5. create a done buton
            var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            nextButton.setTitle("done", forState: UIControlState.Normal)
            nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
            nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
            nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            nextButton.addTarget(self, action: "doneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            
            var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
            newNavItem.rightBarButtonItem = nextBarButtonItem
        }
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
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
    
    func setPreviewStillImage(image: UIImage?, fromPhotoLibrary: Bool) {
        if image != nil {
            // crop image to square
            var fixedImage: UIImage = self.fixOrientation(image!)
            
            var cropWidth = fixedImage.size.width
            var cropHeight = fixedImage.size.height
            var cropCenter: CGPoint = CGPointMake((cropWidth / 2), (cropHeight / 2));
            
            if fromPhotoLibrary != true {
                cropHeight = cropWidth
            }
            
            var cropStart: CGPoint = CGPointMake((cropCenter.x - cropWidth / 2), (cropCenter.y - cropHeight / 2));
            let cropRect: CGRect = CGRectMake(cropStart.x, cropStart.y, cropWidth, cropHeight);
            
            let cropRef: CGImageRef = CGImageCreateWithImageInRect(fixedImage.CGImage, cropRect);
            let cropImage: UIImage = UIImage(CGImage: cropRef)!
            
            var resizedImage = self.resizeImage(cropImage, width: screenWidth)
            
            //println(resizedImage.size)
            
            self.selectedThumbnail.setImage(resizedImage, forState: UIControlState.Normal)
            self.selectedThumbnail.hasThumbnail = true
            self.itemCoverImageView.image = resizedImage
            self.itemCoverImageView.alpha = 1.0
            
            self.itemTableView.scrollEnabled = true
            self.pieceSpecsView.alpha = 1.0
            self.cameraCapture.alpha = 0.0
            self.itemDescriptionCell.alpha = 1.0
            self.photoLibraryButton.alpha = 0.0
            self.addToClosetButton?.alpha = 1.0
            
            self.cameraCapture.enabled = true
            
            self.newNavBar.setItems([self.newNavItem], animated: true)
        } else {
            NSLog("Uh oh! Something went wrong. Try it again.")
        }
    }
    
    func captureFrame(sender: AnyObject) {
        // this is the part where image is captured successfully
        self.cameraCapture.enabled = false
        self.itemCoverImageView.alpha = 0.0
        
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview!.alpha = 0.0
        })
        
        self.camera?.captureStillImage({ (image) -> Void in
            self.setPreviewStillImage(image, fromPhotoLibrary: false)
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
            cellHeight = itemSpecHeightTotal + 10 // itemDetails
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
                
                thumbnailView.frame = CGRectMake(20 + CGFloat(i) * (thumbnailViewWidth + 20), 20, thumbnailViewWidth, thumbnailViewWidth)

                thumbnailView.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                thumbnailView.backgroundColor = sprubixGray
                
                thumbnails.append(thumbnailView)
                
                itemThumbnailsCell.addSubview(thumbnailView)
            }
            
            return itemThumbnailsCell
            
        case 2:
            // init piece specifications
            let itemSpecHeight: CGFloat = 55
            itemSpecHeightTotal = itemSpecHeight * 4
            
            pieceSpecsView = UIView(frame: CGRect(x: 0, y: 10, width: screenWidth, height: itemSpecHeightTotal))
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
            
            itemDetailsCategory = UIButton(frame: CGRectMake(itemImageViewWidth, itemSpecHeight, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsCategoryText = UITextField(frame: CGRectMake(0, 0, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsCategoryText.tintColor = sprubixColor
            itemDetailsCategoryText.placeholder = "Which category is it from?"
            itemDetailsCategoryText.enabled = false
            itemDetailsCategory.addSubview(itemDetailsCategoryText)
            itemDetailsCategory.addTarget(self, action: "itemDetailsCategoryPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            // brand
            var itemBrandImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            itemBrandImage.setImage(UIImage(named: "view-item-brand"), forState: UIControlState.Normal)
            itemBrandImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemBrandImage.frame = CGRect(x: 0, y: itemSpecHeight * 2, width: itemImageViewWidth, height: itemSpecHeight)
            itemBrandImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            
            Glow.addGlow(itemBrandImage)
            
            itemDetailsBrand = MLPAutoCompleteTextField(frame: CGRectMake(itemImageViewWidth, itemSpecHeight * 2, screenWidth - itemImageViewWidth, itemSpecHeight))
            itemDetailsBrand.tintColor = sprubixColor
            itemDetailsBrand.placeholder = "What brand is it?"
            itemDetailsBrand.returnKeyType = UIReturnKeyType.Done
            itemDetailsBrand.delegate = self
            
            // autocomplete
            itemDetailsBrand.autoCompleteDataSource = self
            itemDetailsBrand.autoCompleteTableAppearsAsKeyboardAccessory = true
            itemDetailsBrand.autoCompleteDelegate = self
            itemDetailsBrand.autoCompleteTableCellTextColor = sprubixColor
            itemDetailsBrand.autoCompleteTableBorderColor = sprubixLightGray
            
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
            cameraCapture = UIButton(frame: CGRectMake(screenWidth / 2 - cameraCaptureWidth / 2, 20, cameraCaptureWidth, cameraCaptureWidth))
            cameraCapture.backgroundColor = sprubixColor
            cameraCapture.alpha = 0.0
            cameraCapture.addTarget(self, action: "captureFrame:", forControlEvents: UIControlEvents.TouchUpInside)
            cameraCapture.exclusiveTouch = true
            cameraCapture.layer.cornerRadius = cameraCaptureWidth / 2
            cameraCapture.setTitle("Snap!", forState: UIControlState.Normal)
            cameraCapture.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            
            itemDetailsCell.addSubview(cameraCapture)
            
            initPhotoLibrary()
            
            return itemDetailsCell
            
        case 3:
            if descriptionText == nil {
                descriptionText = UITextView(frame: CGRectInset(CGRect(x: 0, y: 0, width: screenWidth, height: descriptionTextHeight), 15, 0))
            }
            
            descriptionText.tintColor = sprubixColor
            
            if descriptionText.text == "" {
                descriptionText.text = placeholderText
                descriptionText.textColor = UIColor.lightGrayColor()
            }
            
            descriptionText.font = UIFont(name: descriptionText.font.fontName, size: 17)
            descriptionText.delegate = self
            
            itemDescriptionCell.addSubview(descriptionText)
            
            return itemDescriptionCell
            
        default: fatalError("Unknown row in section")
        }
    }
    
    // is dress? switch callback
    func isDressPressed(sender: UISwitch) {
        sprubixPiece.isDress = sender.on
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
            photoLibraryButton.alpha = 1.0
            itemDescriptionCell.alpha = 0.0
            addToClosetButton?.alpha = 0.0
            
            setNavBar("Add Image", leftButtonTitle: "cancel", leftButtonCallback: "addImageCancelTapped:", rightButtonTitle: "", rightButtonCallback: nil)
            
            if camera == nil {
                // activate camera mode (square)
                cameraPscope.show(authChange: { (finished, results) -> Void in
                        //println("got results \(results)")
                        self.initializeCamera()
                        self.establishVideoPreviewArea()
                    }, cancelled: { (results) -> Void in
                        //println("thing was cancelled")
                        
                        self.addImageCancelTapped(UIButton())
                })
            }
        } else {
            itemCoverImageView.image = selectedThumbnail.imageView?.image
        }
    }
    
    //MARK: PhotoLibrary Delegates
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
        var chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismissViewControllerAnimated(true, completion: nil)
        
        // this is the part where image is captured successfully
        self.cameraCapture.enabled = false
        self.itemCoverImageView.alpha = 0.0
        
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview!.alpha = 0.0
        })
        
        self.setPreviewStillImage(chosenImage, fromPhotoLibrary: true)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        addImageCancelTapped(UIButton())
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func initPhotoLibrary() {
        let photoLibraryButtonWidth: CGFloat = 40
        
        photoLibraryButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        photoLibraryButton.frame = CGRectMake(cameraCapture.frame.origin.x / 2 - photoLibraryButtonWidth / 2, cameraCapture.frame.origin.y + (cameraCapture.frame.height / 2 - photoLibraryButtonWidth / 2), photoLibraryButtonWidth, photoLibraryButtonWidth)
        
        var image: UIImage = UIImage(named: "camera-roll")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        photoLibraryButton.setImage(image, forState: UIControlState.Normal)
        photoLibraryButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        photoLibraryButton.imageView?.tintColor = UIColor.lightGrayColor()
        photoLibraryButton.addTarget(self, action: "photoFromLibrary:", forControlEvents: UIControlEvents.TouchUpInside)
        photoLibraryButton.layer.cornerRadius = 5
        photoLibraryButton.alpha = 0.0
        
        itemDetailsCell.addSubview(photoLibraryButton)
        
        imagePicker.delegate = self
        imagePicker.navigationBar.translucent = true
        imagePicker.navigationBar.barTintColor = sprubixGray
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
        photoLibraryButton.alpha = 0.0
        addToClosetButton?.alpha = 1.0
        
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
        if textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" {
            descriptionText.text = placeholderText
            descriptionText.textColor = UIColor.lightGrayColor()
            descriptionText.resignFirstResponder()
        }
        
        newNavBar.setItems([newNavItem], animated: true)
    }
    
    func descriptionDoneTapped(sender: UIButton) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
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
                
                self.itemTableView.frame.origin.y = self.oldFrameRect.origin.y - keyboardFrame.height
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                    }
            })
        } else {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.itemTableView.frame.origin.y = self.oldFrameRect.origin.y
                
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
    
    /**
    * Called when 'return' key pressed. return NO to ignore.
    */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        makeKeyboardVisible = false
        
        textField.resignFirstResponder()
        
        return true
    }
    
    // MLPAutoCompleteTextFieldDataSource
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        
        if count(textField.text) > 0 {
            manager.POST(SprubixConfig.URL.api + "/piece/brands",
                parameters: [
                    "name": textField.text
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var brands = responseObject["data"] as! [NSDictionary]
                    var completions: [String] = [String]()
                    
                    for brand in brands {
                        completions.append(brand["name"] as! String)
                    }
                    
                    handler(completions)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
    
    // MLPAutoCompleteTextFieldDelegate
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, didSelectAutoCompleteString selectedString: String!, withAutoCompleteObject selectedObject: MLPAutoCompletionObject!, forRowAtIndexPath indexPath: NSIndexPath!) {
        
        if selectedObject != nil {
            println("selected object from autocomplete menu \(selectedObject) with string \(selectedObject.autocompleteString())");
        } else {
            println("selected string '\(selectedString)' from autocomplete menu");
        }
        
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }
    
    // button callbacks
    func itemDetailsCategoryPressed(sender: UIButton) {

        let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Choose a category", rows: itemCategories, initialSelection: 2,
            doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                
                if selectedIndex as Int == 3 && selectedValue as! String == "Dress" {
                    self.itemIsDress = true
                } else {
                    self.itemIsDress = false
                }
                
                self.itemDetailsCategoryText.text = "\(selectedValue)"
                
            }, cancelBlock: nil, origin: sender)
        
        // custom done button
        let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        doneButton.setTitleTextAttributes([
            NSForegroundColorAttributeName: sprubixColor,
            ], forState: UIControlState.Normal)
        
        picker.setDoneButton(doneButton)
        
        // custom cancel button
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        cancelButton.setTitle("X", forState: UIControlState.Normal)
        cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
        
        picker.showActionSheetPicker()
    }
    
    // Callback Handler: navigation bar back button
    func cancelTapped(sender: UIBarButtonItem) {
        var alert = UIAlertController(title: "Are you sure?", message: "Changes made to the current item will be lost", preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = sprubixColor
        
        // Yes
        alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: UIAlertActionStyle.Default, handler: { action in
            
            self.camera?.stopCamera()
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        // No
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func addToClosetPressed(sender: UIButton) {
        // init sprubix piece
        sprubixPiece.images.removeAll()
        
        for thumbnail in thumbnails {
            if thumbnail.hasThumbnail {
                sprubixPiece.images.append(thumbnail.imageView!.image!)
            }
        }
        
        // item details
        sprubixPiece.name = (itemDetailsName != nil) ? itemDetailsName.text : ""
        sprubixPiece.category = (itemDetailsCategoryText != nil) ? itemDetailsCategoryText.text : ""
        sprubixPiece.brand = (itemDetailsBrand != nil) ? itemDetailsBrand.text : ""
        sprubixPiece.size = (itemDetailsSize != nil) ? itemDetailsSize.text : ""
        sprubixPiece.desc = (descriptionText != nil && descriptionText.text != placeholderText) ? descriptionText.text : ""
        sprubixPiece.isDress = itemIsDress
        
        let userData: NSDictionary! = defaults.dictionaryForKey("userData")

        var sprubixDict: NSMutableDictionary = [
            "num_pieces": 1,
            "created_by": userData["username"] as! String,
            "from": userData["username"] as! String,
            "user_id": userData["id"] as! Int,
        ]
        
        var pieces: NSMutableDictionary = NSMutableDictionary()
        var pieceDict: NSDictionary = [
            "num_images": sprubixPiece.images.count,
            "name": sprubixPiece.name != nil ? sprubixPiece.name : "",
            "category": sprubixPiece.category != nil ? sprubixPiece.category : "",
            "type": sprubixPiece.type, // type will never be nil
            "is_dress": sprubixPiece.isDress,
            "brand": sprubixPiece.brand != nil ? sprubixPiece.brand : "",
            "size": sprubixPiece.size != nil ? sprubixPiece.size : "",
            "description": sprubixPiece.desc != nil ? sprubixPiece.desc : "",
            "height": sprubixPiece.images[0].scale * sprubixPiece.images[0].size.height,
            "width": sprubixPiece.images[0].scale * sprubixPiece.images[0].size.width
        ]
        
        pieces.setObject(pieceDict, forKey: sprubixPiece.type.lowercaseString)

        sprubixDict.setObject(pieces, forKey: "pieces")
        
        // upload piece data
        var requestOperation: AFHTTPRequestOperation = manager.POST(SprubixConfig.URL.api + "/upload/piece/create", parameters: sprubixDict, constructingBodyWithBlock: { formData in
            let data: AFMultipartFormData = formData
        
            for var j = 0; j < self.sprubixPiece.images.count; j++ {
                var pieceImage: UIImage = self.sprubixPiece.images[j]
                var pieceImageData: NSData = UIImageJPEGRepresentation(pieceImage, 0.5)
                
                var pieceImageName = "piece_\(self.sprubixPiece.type.lowercaseString)_\(j)"
                var pieceImageFileName = pieceImageName + ".jpg"
                
                data.appendPartWithFileData(pieceImageData, name: pieceImageName, fileName: pieceImageFileName, mimeType: "image/jpeg")
            }
            
            }, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                // success block
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
                
            }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                // failure block
                println("Upload Fail")
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
    }

    func doneTapped(sender: UIBarButtonItem) {
        sprubixPiece.images.removeAll()
        
        for thumbnail in thumbnails {
            if thumbnail.hasThumbnail {
                sprubixPiece.images.append(thumbnail.imageView!.image!)
            }
        }
        
        // item details
        sprubixPiece.name = (itemDetailsName != nil) ? itemDetailsName.text : ""
        sprubixPiece.category = (itemDetailsCategoryText != nil) ? itemDetailsCategoryText.text : ""
        sprubixPiece.brand = (itemDetailsBrand != nil) ? itemDetailsBrand.text : ""
        sprubixPiece.size = (itemDetailsSize != nil) ? itemDetailsSize.text : ""
        sprubixPiece.desc = (descriptionText != nil && descriptionText.text != placeholderText) ? descriptionText.text : ""
        sprubixPiece.isDress = itemIsDress
        
        delegate?.setSprubixPiece(sprubixPiece, position: pos)
        
        self.camera?.stopCamera()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func resizeImage(image: UIImage, width: CGFloat) -> UIImage {
        var newImageHeight = image.size.height * width / image.size.width
        
        var size: CGSize = CGSizeMake(width, newImageHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0) // avoid image quality degrading
        
        image.drawInRect(CGRectMake(0, 0, width, newImageHeight))
        
        // final image
        let finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    func photoFromLibrary(sender: UIButton) {
        photoPscope.show(authChange: { (finished, results) -> Void in
            //println("got results \(results)")
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
            }, cancelled: { (results) -> Void in
                //println("thing was cancelled")
        })
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
//
//  SprubixCameraViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AVFoundation
import PermissionScope
import MRProgress

class SprubixCameraViewController: UIViewController, UIScrollViewDelegate, SprubixCameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let cameraPscope = PermissionScope()
    let photoPscope = PermissionScope()
    
    var editSnapshotViewController: EditSnapshotViewController!
    
    let imagePicker = UIImagePickerController()
    var photoLibraryButton: UIButton!
    
    let buttonWidth: CGFloat = 80
    var headButton: UIButton!
    var topButton: UIButton!
    var dressButton: UIButton!
    var bottomButton: UIButton!
    var feetButton: UIButton!
    
    var cameraPreview: UIView!
    var cameraPreviewSilhouette: UIImageView?
    var handleBarView: UIView!
    var pieceSelectorView: UIView!
    var pieceSelectorlabel: UILabel!
    var previewStillScrollView: UIScrollView!
    var previewStillImages: [UIImageView] = [UIImageView]()
    
    var selectedPieces: [String: Bool] = ["HEAD": false, "TOP": false, "BOTTOM": false, "FEET": false]
    var pieceTypes: [String] = ["HEAD", "TOP", "BOTTOM", "FEET"]
    var selectedPiecesOrdered: [String] = [String]()
    var snappedCount:CGFloat = 0.0
    var selectedCount:CGFloat = 0.0
    
    // loading overlay
    var overlay: MRProgressOverlayView!
    var loaded: Bool = false
    
    //@IBOutlet var cameraPreview: UIView!
    var cameraCapture: UIButton!
    var okButton: UIButton!
    
    @IBAction func closeCreateOutfit(sender: AnyObject) {
        editSnapshotViewController = nil
        
        camera?.stopCamera()
        
        if fromAddDetails {
            self.navigationController!.delegate = nil
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = kCATransitionReveal
            transition.subtype = kCATransitionFromBottom
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
            
            self.navigationController!.popViewControllerAnimated(false)
        } else {
            /*
            // pop to main feed
            self.navigationController!.popToViewController(self.navigationController!.viewControllers[self.navigationController!.viewControllers.count - 3] as! UIViewController, animated: false)
            */
            self.navigationController!.popViewControllerAnimated(true)
        }
    }
    
    var preview: AVCaptureVideoPreviewLayer?
    var camera: SprubixCamera?
    
    var fromAddDetails: Bool = false
    var fromAddDetailsPieceType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // initialized permissions
        dispatch_async(dispatch_get_main_queue(), {
            self.cameraPscope.addPermission(PermissionConfig(type: .Camera, demands: .Required, message: "We need this so you can snap\r\nawesome pictures of your items!", notificationCategories: .None))
            
            self.cameraPscope.tintColor = sprubixColor
            self.cameraPscope.headerLabel.text = "Hey there,"
            self.cameraPscope.headerLabel.textColor = UIColor.darkGrayColor()
            self.cameraPscope.bodyLabel.textColor = UIColor.lightGrayColor()
            
            self.photoPscope.addPermission(PermissionConfig(type: .Photos, demands: .Required, message: "We need this so you can import\r\nawesome pictures of your items!", notificationCategories: .None))
            
            self.photoPscope.tintColor = sprubixColor
            self.photoPscope.headerLabel.text = "Hey there,"
            self.photoPscope.headerLabel.textColor = UIColor.darkGrayColor()
            self.photoPscope.bodyLabel.textColor = UIColor.lightGrayColor()
        })
        
        initPieceSelector()
        loaded = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        if fromAddDetails == true {
            pieceSelectorView.alpha = 0.0
            selectedPieces[fromAddDetailsPieceType] = true
            selectedCount = 1
            
            confirmPiecesSelected()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        editSnapshotViewController = nil
        
        if loaded {
            dispatch_async(dispatch_get_main_queue(), {
                // code here
                self.cameraPscope.show(authChange: { (finished, results) -> Void in
                    //println("got results \(results)")
                    self.initializeCamera()
                    self.establishVideoPreviewArea()
                    
                    }, cancelled: { (results) -> Void in
                        //println("thing was cancelled")
                        
                        self.closeCreateOutfit(UIButton())
                })
            })
        } else {
            loaded = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func initPieceSelector() {
        pieceSelectorView = UIView(frame: CGRectMake(0, 0, screenWidth, screenWidth / 0.75))
        pieceSelectorView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
        
        // scrollview
        previewStillScrollView = UIScrollView(frame: CGRectMake(0, navigationHeight, screenWidth, screenWidth / 0.75))
        previewStillScrollView.contentSize = CGSize(width: screenWidth, height: pieceSelectorView.frame.size.height)
        previewStillScrollView.backgroundColor = UIColor.lightGrayColor()
        previewStillScrollView.scrollEnabled = true
        previewStillScrollView.pagingEnabled = false
        previewStillScrollView.alwaysBounceVertical = true
        previewStillScrollView.showsVerticalScrollIndicator = false
        previewStillScrollView.delegate = self
        
        // label
        pieceSelectorlabel = UILabel(frame: CGRectMake(0, previewStillScrollView.frame.origin.y - navigationHeight, screenWidth, navigationHeight))
        if !fromAddDetails {
            pieceSelectorlabel.text = "Lay the item flat and snap!"
        } else {
            pieceSelectorlabel.text = "Snap additional images!"
        }
        pieceSelectorlabel.textColor = UIColor.lightGrayColor()
        pieceSelectorlabel.textAlignment = NSTextAlignment.Center
        
        self.view.addSubview(pieceSelectorlabel)
        
        // create four buttons
        
        // head
        headButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        headButton.frame = CGRectMake(screenWidth / 2 - buttonWidth / 2, 0.2 * pieceSelectorView.frame.size.height - buttonWidth / 2, buttonWidth, buttonWidth)
        headButton.setImage(UIImage(named: "view-item-cat-head"), forState: UIControlState.Normal)
        headButton.backgroundColor = UIColor.lightGrayColor()
        headButton.layer.cornerRadius = buttonWidth / 2
        headButton.addTarget(self, action: "headPieceSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceSelectorView.addSubview(headButton)
        
        // top
        topButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        topButton.frame = CGRectMake((screenWidth / 2 - buttonWidth / 2) - (0.2 * pieceSelectorView.frame.size.height) / 2, 0.4 * pieceSelectorView.frame.size.height - buttonWidth / 2, buttonWidth, buttonWidth)
        topButton.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
        topButton.backgroundColor = UIColor.lightGrayColor()
        topButton.layer.cornerRadius = buttonWidth / 2
        topButton.addTarget(self, action: "topPieceSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceSelectorView.addSubview(topButton)
        
        // dress
        dressButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        dressButton.frame = CGRectMake((screenWidth / 2 - buttonWidth / 2) + (0.2 * pieceSelectorView.frame.size.height) / 2, 0.4 * pieceSelectorView.frame.size.height - buttonWidth / 2, buttonWidth, buttonWidth)
        dressButton.setImage(UIImage(named: "view-item-cat-dress"), forState: UIControlState.Normal)
        dressButton.backgroundColor = UIColor.lightGrayColor()
        dressButton.layer.cornerRadius = buttonWidth / 2
        dressButton.addTarget(self, action: "dressPieceSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceSelectorView.addSubview(dressButton)
        
        // bottom
        bottomButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        bottomButton.frame = CGRectMake(screenWidth / 2 - buttonWidth / 2, 0.6 * pieceSelectorView.frame.size.height - buttonWidth / 2, buttonWidth, buttonWidth)
        bottomButton.setImage(UIImage(named: "view-item-cat-bot"), forState: UIControlState.Normal)
        bottomButton.backgroundColor = UIColor.lightGrayColor()
        bottomButton.layer.cornerRadius = buttonWidth / 2
        bottomButton.addTarget(self, action: "bottomPieceSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceSelectorView.addSubview(bottomButton)
        
        // feet
        feetButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        feetButton.frame = CGRectMake(screenWidth / 2 - buttonWidth / 2, 0.8 * pieceSelectorView.frame.size.height - buttonWidth / 2, buttonWidth, buttonWidth)
        feetButton.setImage(UIImage(named: "view-item-cat-feet"), forState: UIControlState.Normal)
        feetButton.backgroundColor = UIColor.lightGrayColor()
        feetButton.layer.cornerRadius = buttonWidth / 2
        feetButton.addTarget(self, action: "feetPieceSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceSelectorView.addSubview(feetButton)
        
        previewStillScrollView.addSubview(pieceSelectorView)
        
        // init "Ok" button
        let okButtonWidth: CGFloat = screenHeight - navigationHeight - pieceSelectorView.frame.height - 10 * 2 // 10 is padding
        okButton = UIButton(frame: CGRectMake(screenWidth / 2 - okButtonWidth / 2, screenHeight - 10 - okButtonWidth, okButtonWidth, okButtonWidth))
        okButton.setTitle("OK", forState: UIControlState.Normal)
        okButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        okButton.backgroundColor = UIColor.whiteColor()
        okButton.layer.cornerRadius = okButtonWidth / 2
        okButton.layer.borderColor = sprubixColor.CGColor
        okButton.layer.borderWidth = 3.0
        okButton.addTarget(self, action: "confirmPiecesSelected", forControlEvents: UIControlEvents.TouchUpInside)
        
        cameraCapture = UIButton(frame: okButton.frame)
        cameraCapture.backgroundColor = sprubixColor
        cameraCapture.layer.cornerRadius = okButtonWidth / 2
        cameraCapture.addTarget(self, action: "captureFrame:", forControlEvents: UIControlEvents.TouchUpInside)
        cameraCapture.alpha = 0
        
        self.view.addSubview(cameraCapture)
        self.view.addSubview(okButton)
        self.view.addSubview(previewStillScrollView)
    }
    
    func resetPieceSelector() {
        for subview in previewStillScrollView.subviews {
            subview.removeFromSuperview()
        }
        
        previewStillScrollView.contentSize = CGSize(width: screenWidth, height: pieceSelectorView.frame.size.height)
        cameraPreview.frame.origin.y = 0
        previewStillScrollView.addSubview(cameraPreview)
        previewStillScrollView.addSubview(pieceSelectorView)
        
        okButton.alpha = 1.0
        cameraCapture.alpha = 1.0
        pieceSelectorView.alpha = 1.0
        cameraCapture.alpha = 0.0
        
        if !fromAddDetails {
            pieceSelectorlabel.text = "Lay the item flat and snap!"
        } else {
            pieceSelectorlabel.text = "Snap additional images!"
        }
        
        pieceSelectorlabel.alpha = 1.0
        snappedCount = 0.0
        selectedCount = 0.0
        photoLibraryButton.removeFromSuperview()
        
        for (key, value) in selectedPieces {
            selectedPieces[key] = false
        }
        
        selectedPiecesOrdered.removeAll()
        previewStillImages.removeAll()
        
        headButton.selected = false
        headButton.backgroundColor = UIColor.lightGrayColor()
        
        topButton.selected = false
        topButton.backgroundColor = UIColor.lightGrayColor()
        
        dressButton.selected = false
        dressButton.backgroundColor = UIColor.lightGrayColor()
        
        bottomButton.selected = false
        bottomButton.backgroundColor = UIColor.lightGrayColor()
        
        bottomButton.enabled = true
        feetButton.frame.origin.y = 0.8 * self.pieceSelectorView.frame.size.height - buttonWidth / 2
        
        feetButton.selected = false
        feetButton.backgroundColor = UIColor.lightGrayColor()
        
        camera?.stopCamera()
        loaded = false
    }
    
    func initPhotoLibrary() {
        let photoLibraryButtonWidth: CGFloat = 40
        
        photoLibraryButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton

        photoLibraryButton.frame = CGRectMake(okButton.frame.origin.x / 2 - photoLibraryButtonWidth / 2, okButton.frame.origin.y + (cameraCapture.frame.height / 2 - photoLibraryButtonWidth / 2), photoLibraryButtonWidth, photoLibraryButtonWidth)
        
        var image: UIImage = UIImage(named: "camera-roll")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        photoLibraryButton.setImage(image, forState: UIControlState.Normal)
        photoLibraryButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        photoLibraryButton.imageView?.tintColor = UIColor.lightGrayColor()
        photoLibraryButton.addTarget(self, action: "photoFromLibrary:", forControlEvents: UIControlEvents.TouchUpInside)
        photoLibraryButton.layer.cornerRadius = 5
        
        view.addSubview(photoLibraryButton)
        
        imagePicker.delegate = self
        imagePicker.navigationBar.translucent = true
        imagePicker.navigationBar.barTintColor = sprubixGray
    }
    
    func initializeCamera() {
        if camera == nil {
            camera = SprubixCamera(sender: self, front: false)
        }
    }
    
    func establishVideoPreviewArea() {
        if cameraPreview == nil {
            cameraPreview = UIView(frame: CGRectMake(0, 0, screenWidth, screenWidth / 0.75))
            
            cameraPreviewSilhouette = UIImageView(frame: cameraPreview.bounds)
            cameraPreviewSilhouette?.contentMode = UIViewContentMode.ScaleAspectFit
            cameraPreviewSilhouette?.alpha = 0.5
            
            var touch = UITapGestureRecognizer(target:self, action:"manualFocus:")
            cameraPreview.addGestureRecognizer(touch)
            
            previewStillScrollView.insertSubview(cameraPreview, atIndex: 0)
        
            self.preview = AVCaptureVideoPreviewLayer(session: self.camera?.session)
            self.preview?.videoGravity = AVLayerVideoGravityResizeAspect
            self.preview?.frame = self.cameraPreview.bounds
            self.cameraPreview.layer.addSublayer(self.preview)
            
            cameraPreview.addSubview(cameraPreviewSilhouette!)
        }
    }
    
    // tap to focus
    func manualFocus(gesture :UITapGestureRecognizer) {
        var touchPoint: CGPoint = gesture.locationInView(gesture.view)

        self.camera?.focus(touchPoint, preview: self.preview!)
    }
    
    func calculatePage() {
        let pageHeight = previewStillScrollView.frame.size.height
        let page = Int(floor((previewStillScrollView.contentOffset.y * 2.0 + pageHeight) / (pageHeight * 2.0)))
        
        if selectedPiecesOrdered.count > 0 {
            setSnapButtonIcon(selectedPiecesOrdered[page])
        }
    }
    
    // ScrollViewDelegate
    private func calculatePage(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset
        
        var nearestPoint: CGPoint?
        var page: Int?
        var prevDistance: Float = 0
        var points: [CGPoint] = [CGPoint]()
        
        for stillImage in previewStillImages {
            points.append(stillImage.frame.origin)
        }
        
        points.append(cameraPreview.frame.origin)
        
        for var i = 0; i < points.count; i++ {
            // see which stillImage's offset Y is currentOffsetY closest to
            var point = points[i]
            
            if nearestPoint == nil {
                nearestPoint = point
                page = i
            }
            
            let distance = hypotf(Float(currentOffset.x - point.x), Float(currentOffset.y - point.y))
            
            if distance < prevDistance {
                nearestPoint = point
                page = i
            }
            
            prevDistance = distance
        }
        
        if nearestPoint != nil && page != nil {
            scrollView.setContentOffset(nearestPoint!, animated: true)
            
            if page < selectedPiecesOrdered.count {
                setSnapButtonIcon(selectedPiecesOrdered[page!])
            }
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        calculatePage(scrollView)
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        calculatePage(scrollView)
    }
    
    // MARK: PhotoLibrary Delegates
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        var chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismissViewControllerAnimated(true, completion: nil)
        
        // Mixpanel - Take Photo, Library
        let currentPieceType: String = self.selectedPiecesOrdered[Int(self.snappedCount)].lowercaseString.capitalizeFirst
        mixpanel.track("Take Photo", properties: [
            "Source": "Library",
            "Type" : currentPieceType
        ])
        // Mixpanel - End

        setPreviewStillImage(chosenImage)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Button Actions
    func captureFrame(sender: AnyObject) {
        // this is the part where image is captured successfully
        self.cameraCapture.enabled = false
        
        self.camera?.captureStillImage({ (image) -> Void in
            self.setPreviewStillImage(image)
        })
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.cameraPreview.alpha = 0.0
        })
        
        // Mixpanel - Take Photo, Camera
        let currentPieceType: String = self.selectedPiecesOrdered[Int(self.snappedCount)].lowercaseString.capitalizeFirst
        
        mixpanel.track("Take Photo", properties: [
            "Source": "Camera",
            "Type" : currentPieceType
        ])
        // Mixpanel - End
    }
    
    func setPreviewStillImage(image: UIImage?) {
        if image != nil {
            // was selected by user
            let selectedPiece = self.selectedPiecesOrdered[Int(self.snappedCount)]
            
            let scale = image!.size.width / screenWidth
            let previewStillWidth = image!.size.width / scale
            let previewStillHeight = image!.size.height / scale
            
            var totalPrevHeights: CGFloat = 0
            
            for stillImage in self.previewStillImages {
                totalPrevHeights += stillImage.frame.height
            }
            
            var previewStillImageView: UIImageView = UIImageView(frame: CGRectMake(0, totalPrevHeights, previewStillWidth, previewStillHeight))
            previewStillImageView.contentMode = UIViewContentMode.ScaleAspectFit
            
            fixOrientation(image!)
            
            previewStillImageView.image = image
            
            // add this preview still into the storage array
            self.previewStillImages.append(previewStillImageView)
            
            self.cameraPreview.frame.origin.y = self.cameraPreview.frame.origin.y + previewStillImageView.frame.height
            self.cameraPreview.alpha = 1.0
            self.previewStillScrollView.addSubview(previewStillImageView)
            //self.previewStillScrollView.contentSize = CGSize(width: screenWidth, height: self.pieceSelectorView.frame.size.height * (self.snappedCount + 2))
            self.previewStillScrollView.contentSize = CGSize(width: screenWidth, height: totalPrevHeights + previewStillImageView.frame.height + self.pieceSelectorView.frame.size.height)
            
            self.snappedCount += 1
            
            if self.snappedCount == self.selectedCount {
                
                // init overlay
                self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Processing...", mode: MRProgressOverlayViewMode.Indeterminate, animated: true)
                
                self.overlay.tintColor = sprubixColor
                self.cameraCapture.alpha = 0.0
                
                // go to edit controller
                if self.editSnapshotViewController == nil {
                    self.editSnapshotViewController = EditSnapshotViewController()
                }
                
                self.editSnapshotViewController.sprubixCameraViewController = self
                self.editSnapshotViewController.selectedPiecesOrdered = self.selectedPiecesOrdered
                self.editSnapshotViewController.previewStillImages = self.previewStillImages
                self.editSnapshotViewController.fromAddDetails = self.fromAddDetails
                
                // check if top is dress
                if self.dressButton.selected {
                    self.editSnapshotViewController.topIsDress = true
                } else {
                    self.editSnapshotViewController.topIsDress = false
                }
                
                if self.fromAddDetails == true {
                    let prevViewController = self.navigationController!.viewControllers[self.navigationController!.viewControllers.count - 2] as! SnapshotDetailsController
                    
                    self.editSnapshotViewController.delegate = prevViewController
                }
                
                self.resetPieceSelector()
                self.overlay.dismiss(true)
                self.cameraCapture.enabled = true
                
                self.navigationController?.delegate = nil
                self.navigationController?.pushViewController(self.editSnapshotViewController, animated: true)
                
                // Mixpanel - Edit Photo
                mixpanel.track("Edit Photo")
                // Mixpanel - End
            } else {
                Delay.delay(0.6, closure: {
                    // shift view to cameraPreview
                    self.previewStillScrollView.scrollRectToVisible(self.cameraPreview.frame, animated: true)
                    self.setSnapButtonIcon(self.selectedPiecesOrdered[Int(self.snappedCount)])
                    self.cameraCapture.enabled = true
                })
            }
            
        } else {
            NSLog("Uh oh! Something went wrong. Try it again.")
        }
    }
    
    func setSnapButtonIcon(currentPiece: String) {
        switch currentPiece {
        case "HEAD":
            self.cameraCapture.setImage(UIImage(named: "view-item-cat-head"), forState: UIControlState.Normal)
            cameraPreviewSilhouette?.image = UIImage(named: "silhouette-head")
            
        case "TOP":
            if dressButton.selected {
                self.cameraCapture.setImage(UIImage(named: "view-item-cat-dress"), forState: UIControlState.Normal)
                cameraPreviewSilhouette?.image = UIImage(named: "silhouette-dress")
            } else {
                self.cameraCapture.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
                cameraPreviewSilhouette?.image = UIImage(named: "silhouette-top")
            }
            
        case "BOTTOM":
            self.cameraCapture.setImage(UIImage(named: "view-item-cat-bot"), forState: UIControlState.Normal)
            cameraPreviewSilhouette?.image = UIImage(named: "silhouette-shorts")
            
        case "FEET":
            self.cameraCapture.setImage(UIImage(named: "view-item-cat-feet"), forState: UIControlState.Normal)
            cameraPreviewSilhouette?.image = UIImage(named: "silhouette-feet")
            
        default:
            fatalError("Invalid piece info for setting snapbutton icon")
        }
    }
    
    // MARK: Camera Delegate
    func cameraSessionConfigurationDidComplete() {
        self.camera?.startCamera()
    }
    
    func cameraSessionDidBegin() {
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview.alpha = 1.0
            self.cameraCapture.alpha = 1.0
        })
    }
    
    func cameraSessionDidStop() {
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview.alpha = 0.0
            self.camera = nil
            self.cameraPreview = nil
        })
    }
    
    // Button Callbacks
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
    
    func headPieceSelected(sender: UIButton) {
        if sender.selected != true {
            sender.backgroundColor = sprubixColor
            sender.selected = true
            selectedCount += 1
            selectedPieces["HEAD"] = true
        } else {
            sender.backgroundColor = UIColor.lightGrayColor()
            sender.selected = false
            selectedCount -= 1
            selectedPieces["HEAD"] = false
        }
    }
    
    func topPieceSelected(sender: UIButton) {
        if sender.selected != true {
            sender.backgroundColor = sprubixColor
            sender.selected = true
            selectedCount += 1
            selectedPieces["TOP"] = true
            
            // if top is selected and dress is selected, deselect dress
            if dressButton.selected {
                dressButton.backgroundColor = UIColor.lightGrayColor()
                dressButton.selected = false
                selectedCount -= 1
            }
            
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                
                // shift feet icon down to original position
                self.bottomButton.enabled = true
                self.feetButton.frame.origin.y = 0.8 * self.pieceSelectorView.frame.size.height - self.buttonWidth / 2
                
                }, completion: nil)
            
        } else {
            sender.backgroundColor = UIColor.lightGrayColor()
            sender.selected = false
            selectedCount -= 1
            selectedPieces["TOP"] = false
        }
    }
    
    func dressPieceSelected(sender: UIButton) {
        if sender.selected != true {
            sender.backgroundColor = sprubixColor
            sender.selected = true
            selectedCount += 1
            selectedPieces["TOP"] = true
            
            // if dress is selected and top is selected, deselect top
            if topButton.selected {
                topButton.backgroundColor = UIColor.lightGrayColor()
                topButton.selected = false
                selectedCount -= 1
            }
            
            // if dress is selected and bottom is selected, deselect bottom
            if bottomButton.selected {
                bottomButton.backgroundColor = UIColor.lightGrayColor()
                bottomButton.selected = false
                selectedCount -= 1
                selectedPieces["BOTTOM"] = false
            }
            
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                
                // shift feet icon up to bottom's position
                self.bottomButton.enabled = false
                self.feetButton.frame.origin.y = self.bottomButton.frame.origin.y
                
                }, completion: nil)
            
        } else {
            sender.backgroundColor = UIColor.lightGrayColor()
            sender.selected = false
            selectedCount -= 1
            selectedPieces["TOP"] = false
        }
    }
    
    func bottomPieceSelected(sender: UIButton) {
        if sender.selected != true {
            sender.backgroundColor = sprubixColor
            sender.selected = true
            selectedCount += 1
            selectedPieces["BOTTOM"] = true
            
        } else {
            sender.backgroundColor = UIColor.lightGrayColor()
            sender.selected = false
            selectedCount -= 1
            selectedPieces["BOTTOM"] = false
        }
    }
    
    func feetPieceSelected(sender: UIButton) {
        if sender.selected != true {
            sender.backgroundColor = sprubixColor
            sender.selected = true
            selectedCount += 1
            selectedPieces["FEET"] = true
        } else {
            sender.backgroundColor = UIColor.lightGrayColor()
            sender.selected = false
            selectedCount -= 1
            selectedPieces["FEET"] = false
        }
    }
    
    func confirmPiecesSelected() {
        if selectedCount > 0 {
            okButton.alpha = 0.0
            pieceSelectorView.alpha = 0.0
            cameraCapture.alpha = 1.0
            
            for var i = 0; i < self.pieceTypes.count; i++ {
                let pieceType = self.pieceTypes[i]
                
                if self.selectedPieces[pieceType] != false {
                    selectedPiecesOrdered.append(pieceType)
                }
            }
            
            // enable image picker 
            initPhotoLibrary()
            
            // first one
            setSnapButtonIcon(selectedPiecesOrdered[0])
        }
    }
    
    // fix image orientation
    func fixOrientation(img: UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.Up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.drawInRect(rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage;
        
    }
}

extension UINavigationController {
    func pushViewController(viewController: UIViewController,
        animated: Bool, completion: Void -> Void) {
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
            pushViewController(viewController, animated: animated)
            CATransaction.commit()
    }
}

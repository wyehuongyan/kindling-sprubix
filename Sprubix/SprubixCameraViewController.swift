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

class SprubixCameraViewController: UIViewController, UIScrollViewDelegate, SprubixCameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let cameraPscope = PermissionScope()
    let photoPscope = PermissionScope()
    
    var editSnapshotViewController: EditSnapshotViewController!
    
    let imagePicker = UIImagePickerController()
    var photoLibraryButton: UIButton!
    
    var headButton: UIButton!
    var topButton: UIButton!
    var bottomButton: UIButton!
    var feetButton: UIButton!
    
    var cameraPreview: UIView!
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
        
        initPieceSelector()
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
        
        cameraPscope.show(authChange: { (finished, results) -> Void in
            //println("got results \(results)")
            self.initializeCamera()
            self.establishVideoPreviewArea()
            }, cancelled: { (results) -> Void in
                //println("thing was cancelled")
                
                self.closeCreateOutfit(UIButton())
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = nil
        
        //self.camera?.stopCamera()
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
        pieceSelectorlabel.text = "I'm snapping my..."
        pieceSelectorlabel.textColor = UIColor.lightGrayColor()
        pieceSelectorlabel.textAlignment = NSTextAlignment.Center
        
        self.view.addSubview(pieceSelectorlabel)
        
        // create four buttons
        let buttonWidth: CGFloat = 80
        
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
        topButton.frame = CGRectMake(screenWidth / 2 - buttonWidth / 2, 0.4 * pieceSelectorView.frame.size.height - buttonWidth / 2, buttonWidth, buttonWidth)
        topButton.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
        topButton.backgroundColor = UIColor.lightGrayColor()
        topButton.layer.cornerRadius = buttonWidth / 2
        topButton.addTarget(self, action: "topPieceSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceSelectorView.addSubview(topButton)
        
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
        pieceSelectorlabel.text = "I'm snapping my..."
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
        
        bottomButton.selected = false
        bottomButton.backgroundColor = UIColor.lightGrayColor()
        
        feetButton.selected = false
        feetButton.backgroundColor = UIColor.lightGrayColor()
        
        camera?.stopCamera()
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
            
            var touch = UITapGestureRecognizer(target:self, action:"manualFocus:")
            cameraPreview.addGestureRecognizer(touch)
            
            previewStillScrollView.insertSubview(cameraPreview, atIndex: 0)
        
            self.preview = AVCaptureVideoPreviewLayer(session: self.camera?.session)
            self.preview?.videoGravity = AVLayerVideoGravityResizeAspect
            self.preview?.frame = self.cameraPreview.bounds
            self.cameraPreview.layer.addSublayer(self.preview)
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

        setPreviewStillImage(chosenImage)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Button Actions
    func captureFrame(sender: AnyObject) {
        // this is the part where image is captured successfully
        self.cameraCapture.enabled = false
        
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview.alpha = 0.0
        })
        
        self.camera?.captureStillImage({ (image) -> Void in
            self.setPreviewStillImage(image)
        })
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
            previewStillImageView.image = image
            
            // add this preview still into the storage array
            self.previewStillImages.append(previewStillImageView)
            
            self.cameraPreview.frame.origin.y = self.cameraPreview.frame.origin.y + previewStillImageView.frame.height
            self.cameraPreview.alpha = 1.0
            self.previewStillScrollView.addSubview(previewStillImageView)
            //self.previewStillScrollView.contentSize = CGSize(width: screenWidth, height: self.pieceSelectorView.frame.size.height * (self.snappedCount + 2))
            self.previewStillScrollView.contentSize = CGSize(width: screenWidth, height: totalPrevHeights + previewStillImageView.frame.height + self.pieceSelectorView.frame.size.height)
            
            self.snappedCount += 1
            
            // the delay is for the cameraStill to remain on screen for a while before moving away
            self.delay(0.6) {
                if self.snappedCount == self.selectedCount {
                    
                    self.cameraCapture.alpha = 0.0
                    
                    // go to edit controller
                    if self.editSnapshotViewController == nil {
                        self.editSnapshotViewController = EditSnapshotViewController()
                    }
                    
                    self.editSnapshotViewController.selectedPiecesOrdered = self.selectedPiecesOrdered
                    self.editSnapshotViewController.previewStillImages = self.previewStillImages
                    self.editSnapshotViewController.fromAddDetails = self.fromAddDetails
                    
                    if self.fromAddDetails == true {
                        let prevViewController = self.navigationController!.viewControllers[self.navigationController!.viewControllers.count - 2] as! SnapshotDetailsController
                        
                        self.editSnapshotViewController.delegate = prevViewController
                    }
                    
                    self.navigationController?.delegate = nil
                    self.navigationController?.pushViewController(self.editSnapshotViewController, animated: true) {
                        // Animation done
                        self.resetPieceSelector()
                    }
                    
                } else {
                    // shift view to cameraPreview
                    self.previewStillScrollView.scrollRectToVisible(self.cameraPreview.frame, animated: true)
                    self.setSnapButtonIcon(self.selectedPiecesOrdered[Int(self.snappedCount)])
                }
                
                self.cameraCapture.enabled = true
            }
            
        } else {
            NSLog("Uh oh! Something went wrong. Try it again.")
        }
    }
    
    func setSnapButtonIcon(currentPiece: String) {
        switch currentPiece {
        case "HEAD":
            self.cameraCapture.setImage(UIImage(named: "view-item-cat-head"), forState: UIControlState.Normal)
        case "TOP":
            self.cameraCapture.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
        case "BOTTOM":
            self.cameraCapture.setImage(UIImage(named: "view-item-cat-bot"), forState: UIControlState.Normal)
        case "FEET":
            self.cameraCapture.setImage(UIImage(named: "view-item-cat-feet"), forState: UIControlState.Normal)
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
            pieceSelectorlabel.alpha = 0.0
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
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
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

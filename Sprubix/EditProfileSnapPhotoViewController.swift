//
//  EditProfileSnapPhotoViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 1/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import PermissionScope

class EditProfileSnapPhotoViewController: UIViewController, SprubixCameraDelegate {
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!

    // camera
    let cameraPscope = PermissionScope()
    
    var cameraCapture: UIButton!
    var acceptPhoto: UIButton!
    var toggleFrontCamera: UIButton!
    var retakePhoto: UIButton!
    
    var frontCamera: Bool = true
    var viaToggle: Bool = false
    
    var cameraPreview: UIView!
    var previewStill: UIImageView!
    var preview: AVCaptureVideoPreviewLayer?
    var camera: SprubixCamera?
    
    var photoType: SelectedPhotoType = SelectedPhotoType.Profile
    var editProfileViewController: EditProfileViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // initialized permissions
        cameraPscope.addPermission(PermissionConfig(type: .Camera, demands: .Required, message: "We need this so you can snap\r\nawesome pictures of your items!", notificationCategories: .None))
        
        cameraPscope.tintColor = sprubixColor
        cameraPscope.headerLabel.text = "Hey there,"
        cameraPscope.headerLabel.textColor = UIColor.darkGrayColor()
        cameraPscope.bodyLabel.textColor = UIColor.lightGrayColor()
        
        initButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        cameraPscope.show(authChange: { (finished, results) -> Void in
            //println("got results \(results)")
            self.initializeCamera(self.frontCamera)
            self.establishVideoPreviewArea()
            }, cancelled: { (results) -> Void in
                //println("thing was cancelled")
                
                self.backTapped(UIBarButtonItem())
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        camera?.stopCamera()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        // create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        backButton.setTitle("X", forState: UIControlState.Normal)
        backButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.exclusiveTouch = true
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = sprubixColor

        self.navigationItem.setLeftBarButtonItem(backBarButtonItem, animated: false)
    }
    
    func initButtons() {
        // preview still image
        previewStill = UIImageView(frame: CGRectMake(0, navigationHeight, screenWidth, screenWidth / 0.75))
        previewStill.alpha = 0.0
        
        view.addSubview(previewStill)
        
        // "snap" button
        let captureButtonWidth: CGFloat = screenHeight - navigationHeight - (screenWidth / 0.75) - 10 * 2 // 10 is padding
        
        cameraCapture = UIButton(frame: CGRectMake(screenWidth / 2 - captureButtonWidth / 2, screenHeight - 10 - captureButtonWidth, captureButtonWidth, captureButtonWidth))
        var image: UIImage = UIImage(named: "details-thumbnail-add")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        cameraCapture.setImage(image, forState: UIControlState.Normal)
        cameraCapture.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        cameraCapture.imageView?.tintColor = UIColor.whiteColor()
        cameraCapture.backgroundColor = sprubixColor
        cameraCapture.layer.cornerRadius = captureButtonWidth / 2
        cameraCapture.addTarget(self, action: "captureFrame:", forControlEvents: UIControlEvents.TouchUpInside)
        cameraCapture.alpha = 0
        
        view.addSubview(cameraCapture)
        
        // accept photo button
        acceptPhoto = UIButton(frame: cameraCapture.frame)
        image = UIImage(named: "filter-check")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        acceptPhoto.setImage(image, forState: UIControlState.Normal)
        acceptPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        acceptPhoto.imageView?.tintColor = sprubixColor
        acceptPhoto.backgroundColor = UIColor.whiteColor()
        acceptPhoto.layer.cornerRadius = captureButtonWidth / 2
        acceptPhoto.layer.borderColor = sprubixColor.CGColor
        acceptPhoto.layer.borderWidth = 3.0
        acceptPhoto.addTarget(self, action: "photoAcceptPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        acceptPhoto.alpha = 0.0
        
        view.addSubview(acceptPhoto)
        
        // flip camera mode button
        let toggleFrontCameraButtonWidth: CGFloat = 40
        
        toggleFrontCamera = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        toggleFrontCamera.frame = CGRectMake(cameraCapture.frame.origin.x / 2 - toggleFrontCameraButtonWidth / 2, cameraCapture.frame.origin.y + (cameraCapture.frame.height / 2 - toggleFrontCameraButtonWidth / 2), toggleFrontCameraButtonWidth, toggleFrontCameraButtonWidth)
        image = UIImage(named: "camera-switch")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        toggleFrontCamera.setImage(image, forState: UIControlState.Normal)
        toggleFrontCamera.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        toggleFrontCamera.imageView?.tintColor = UIColor.lightGrayColor()
        toggleFrontCamera.addTarget(self, action: "toggleFrontCameraPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        toggleFrontCamera.layer.cornerRadius = 5
        
        view.addSubview(toggleFrontCamera)
        
        // retake photo button
        retakePhoto = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        retakePhoto.frame = toggleFrontCamera.frame
        image = UIImage(named: "snapshot-retake")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        retakePhoto.setImage(image, forState: UIControlState.Normal)
        retakePhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        retakePhoto.imageView?.tintColor = UIColor.lightGrayColor()
        retakePhoto.addTarget(self, action: "photoRetakePressed:", forControlEvents: UIControlEvents.TouchUpInside)
        retakePhoto.layer.cornerRadius = 5
        retakePhoto.alpha = 0.0
        
        view.addSubview(retakePhoto)
    }
    
    func initializeCamera(front: Bool) {
        if camera == nil {
            camera = SprubixCamera(sender: self, front: front)
        }
    }
    
    func establishVideoPreviewArea() {
        if cameraPreview == nil {
            cameraPreview = UIView(frame: CGRectMake(0, navigationHeight, screenWidth, screenWidth / 0.75))
            
            var touch = UITapGestureRecognizer(target:self, action:"manualFocus:")
            cameraPreview.addGestureRecognizer(touch)
            
            view.addSubview(cameraPreview)
            
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
    
    // MARK: Camera Delegate
    func cameraSessionConfigurationDidComplete() {
        self.camera?.startCamera()
    }
    
    func cameraSessionDidBegin() {
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview.alpha = 1.0
            self.cameraCapture.alpha = 1.0
            self.viaToggle = false
        })
    }
    
    func cameraSessionDidStop() {
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview.alpha = 0.0
            self.camera = nil
            self.cameraPreview.removeFromSuperview()
            self.cameraPreview = nil
            
            if self.viaToggle {
                // switch to front camera
                self.initializeCamera(self.frontCamera)
                self.establishVideoPreviewArea()
            }
        })
    }
    
    // button callbacks
    func toggleFrontCameraPressed(sender: UIButton) {
        viaToggle = true
        frontCamera = !frontCamera
        camera?.stopCamera()
    }
    
    func captureFrame(sender: AnyObject) {
        // this is the part where image is captured successfully
        self.cameraCapture.enabled = false
        
        UIView.animateWithDuration(0.225, animations: { () -> Void in
            self.cameraPreview.alpha = 0.0

            }, completion: { finished in
                if finished {
                    self.camera?.captureStillImage({ (image) -> Void in
                        var flippedImage = image
                        
                        if self.frontCamera {
                            flippedImage = UIImage(CGImage: image!.CGImage, scale: image!.scale, orientation:.LeftMirrored)
                        }
                        
                        self.setPreviewStillImage(flippedImage)
                    })
                }
        })
    }
    
    func setPreviewStillImage(image: UIImage?) {
        if image != nil {
            // hide snap and toggle buttons
            cameraCapture.alpha = 0.0
            toggleFrontCamera.alpha = 0.0
            
            // show accept and retake buttons
            acceptPhoto.alpha = 1.0
            retakePhoto.alpha = 1.0
            
            previewStill.image = image
            previewStill.alpha = 1.0
        }
    }
    
    func photoAcceptPressed(sender: UIButton) {
        let editProfileCropPhotoViewController = EditProfileCropPhotoViewController()
        
        // go to edit controller
        editProfileCropPhotoViewController.photoImageView.image = previewStill.image
        editProfileCropPhotoViewController.delegate = editProfileViewController
        editProfileCropPhotoViewController.photoType = photoType
        editProfileCropPhotoViewController.fromSnapPhotoView = true
        
        self.navigationController?.pushViewController(editProfileCropPhotoViewController, animated: true)
    }
 
    func photoRetakePressed(sender: UIButton) {
        // show snap and toggle buttons
        cameraCapture.enabled = true
        cameraCapture.alpha = 1.0
        toggleFrontCamera.alpha = 1.0
        
        // hide accept and retake buttons
        acceptPhoto.alpha = 0.0
        retakePhoto.alpha = 0.0
        
        // hide preview still image and show camera preview
        previewStill.alpha = 0.0
        cameraPreview.alpha = 1.0
    }
    
    // nar bar callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController!.delegate = nil
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromBottom
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
        
        self.navigationController!.popViewControllerAnimated(false)
    }
}

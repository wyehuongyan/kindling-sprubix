//
//  SprubixCameraViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AVFoundation

class SprubixCameraViewController: UIViewController, SprubixCameraDelegate {
    
    var editSnapshotViewController: EditSnapshotViewController!
    
    var sprubixHandleBarSeperator2:SprubixHandleBarSeperator!
    var sprubixHandleBarSeperator3:SprubixHandleBarSeperator!
    var sprubixHandleBarSeperator4:SprubixHandleBarSeperator!
    var sprubixHandleBarSeperatorVertical:UIView!
    
    var cameraPreview: UIView!
    var handleBarView:UIView!
    
    //@IBOutlet var cameraPreview: UIView!
    @IBOutlet var cameraCapture: UIButton!
    
    @IBAction func closeCreateOutfit(sender: AnyObject) {
        editSnapshotViewController = nil
        
        self.navigationController!.delegate = nil
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    var preview: AVCaptureVideoPreviewLayer?
    
    var camera: SprubixCamera?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initHandleBarSeperators()
    }
    
    func initHandleBarSeperators() {
        handleBarView = UIView(frame: CGRectMake(0, navigationHeaderAndStatusbarHeight, screenWidth, screenWidth / 0.75))
        
        let sprubixHandleBarSeperatorHeight:CGFloat = 30
        
        // handlebar seperator 2
        sprubixHandleBarSeperator2 = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.20 * handleBarView.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 0, lineStroke: 2, glow: false, opacity: 0.3)
        
        handleBarView.addSubview(sprubixHandleBarSeperator2)
        
        // handlebar seperator 3
        sprubixHandleBarSeperator3 = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.45 * handleBarView.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 0, lineStroke: 2, glow: false, opacity: 0.3)
        
        handleBarView.addSubview(sprubixHandleBarSeperator3)
        
        // handlebar seperator 4
        sprubixHandleBarSeperator4 = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.85 * handleBarView.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 0, lineStroke: 2, glow: false, opacity: 0.3)
        
        handleBarView.addSubview(sprubixHandleBarSeperator4)
        
        // handlebar seperatorVertical
        let sprubixHandleBarSeperatorVerticalWidth:CGFloat = 2
        sprubixHandleBarSeperatorVertical = UIView(frame: CGRectMake(screenWidth / 2 - sprubixHandleBarSeperatorVerticalWidth / 2, 0, sprubixHandleBarSeperatorVerticalWidth, handleBarView.frame.size.height))
        sprubixHandleBarSeperatorVertical.alpha = 0.3
        sprubixHandleBarSeperatorVertical.backgroundColor = UIColor.whiteColor()
        
        handleBarView.addSubview(sprubixHandleBarSeperatorVertical)
        
        self.view.addSubview(handleBarView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        
        self.initializeCamera()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.establishVideoPreviewArea()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = nil
        
        self.camera?.stopCamera()
    }
    
    func initializeCamera() {
        self.camera = SprubixCamera(sender: self)
    }
    
    func establishVideoPreviewArea() {
        if cameraPreview == nil {
            cameraPreview = UIView(frame: CGRectMake(0, navigationHeaderAndStatusbarHeight, screenWidth, screenWidth / 0.75))
            
            self.view.insertSubview(cameraPreview, atIndex: 0)
        }
        
        self.preview = AVCaptureVideoPreviewLayer(session: self.camera?.session)
        self.preview?.videoGravity = AVLayerVideoGravityResizeAspect
        self.preview?.frame = self.cameraPreview.bounds
        self.cameraPreview.layer.addSublayer(self.preview)
    }
    
    // tap to focus
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            let touchPoint: CGPoint = touch.locationInView(touch.view)
            self.camera?.focus(touchPoint, preview: self.preview!)
        }
    }
    
    // MARK: Button Actions
    
    @IBAction func captureFrame(sender: AnyObject) {
            UIView.animateWithDuration(0.225, animations: { () -> Void in
                self.cameraPreview.alpha = 0.0
            })
            
            self.camera?.captureStillImage({ (image) -> Void in
                if image != nil {
                    // this is the part where image is captured successfully
                    // slot in the edit snapshot view here
                    if self.editSnapshotViewController == nil {
                        self.editSnapshotViewController = EditSnapshotViewController()
                    }
                    
                    self.editSnapshotViewController.snapshot.image = image
                    
                    self.navigationController?.pushViewController(self.editSnapshotViewController, animated: false)
                    
                } else {
                    NSLog("Uh oh! Something went wrong. Try it again.")
                }
            })
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
        })
    }
}

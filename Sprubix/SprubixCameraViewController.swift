//
//  SprubixCameraViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AVFoundation

enum Status: Int {
    case Preview, Still, Error
}

class SprubixCameraViewController: UIViewController, SprubixCameraDelegate {
    
    var editSnapshotViewController: EditSnapshotViewController!
    
    var cameraPreview: UIView!
    
    //@IBOutlet var cameraPreview: UIView!
    @IBOutlet var cameraCapture: UIButton!
    
    @IBAction func closeCreateOutfit(sender: AnyObject) {
        editSnapshotViewController = nil
        
        self.navigationController!.delegate = nil
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    var preview: AVCaptureVideoPreviewLayer?
    
    var camera: SprubixCamera?
    var status: Status = .Preview
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            cameraPreview = UIView(frame: CGRectMake(0, 0, screenWidth, screenWidth / 0.75))
            self.view.addSubview(cameraPreview)
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
        if self.status == .Preview {
            UIView.animateWithDuration(0.225, animations: { () -> Void in
                self.cameraPreview.alpha = 0.0
            })
            
            self.camera?.captureStillImage({ (image) -> Void in
                if image != nil {
                    self.status = .Still
                    
                    // this is the part where image is captured successfully
                    // slot in the edit snapshot view here
                    if self.editSnapshotViewController == nil {
                        self.editSnapshotViewController = EditSnapshotViewController()
                    }
                    
                    self.editSnapshotViewController.snapshot.image = image
                    
                    self.navigationController?.pushViewController(self.editSnapshotViewController, animated: false)
                    
                } else {
                    NSLog("Uh oh! Something went wrong. Try it again.")
                    self.status = .Error
                }
                
                self.cameraCapture.setTitle("Reset", forState: UIControlState.Normal)
            })
        } else if self.status == .Still || self.status == .Error {
            UIView.animateWithDuration(0.225, animations: { () -> Void in
                self.cameraPreview.alpha = 1.0
                self.cameraCapture.setTitle("Capture", forState: UIControlState.Normal)
                }, completion: { (done) -> Void in
                    self.status = .Preview
            })
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
        })
    }
}

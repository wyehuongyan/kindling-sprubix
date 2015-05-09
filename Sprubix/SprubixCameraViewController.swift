//
//  SprubixCameraViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AVFoundation

class SprubixCameraViewController: UIViewController, UIScrollViewDelegate, SprubixCameraDelegate {
    
    var editSnapshotViewController: EditSnapshotViewController!
    
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
    @IBOutlet var cameraCapture: UIButton!
    var okButton: UIButton!
    
    @IBAction func closeCreateOutfit(sender: AnyObject) {
        editSnapshotViewController = nil
        
        self.navigationController!.delegate = nil
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    var preview: AVCaptureVideoPreviewLayer?
    
    var camera: SprubixCamera?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initPieceSelector()
    }
    
    func initPieceSelector() {
        pieceSelectorView = UIView(frame: CGRectMake(0, 0, screenWidth, screenWidth / 0.75))
        pieceSelectorView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
        
        // scrollview
        previewStillScrollView = UIScrollView(frame: CGRectMake(0, navigationHeight, screenWidth, screenWidth / 0.75))
        previewStillScrollView.contentSize = CGSize(width: screenWidth, height: pieceSelectorView.frame.size.height)
        previewStillScrollView.scrollEnabled = true
        previewStillScrollView.pagingEnabled = true
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
        let okButtonWidth: CGFloat = 100
        okButton = UIButton(frame: CGRectMake(screenWidth / 2 - okButtonWidth / 2, screenHeight - 10 - okButtonWidth, okButtonWidth, okButtonWidth))
        okButton.setTitle("OK", forState: UIControlState.Normal)
        okButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        okButton.backgroundColor = UIColor.whiteColor()
        okButton.layer.cornerRadius = okButtonWidth / 2
        okButton.layer.borderColor = sprubixColor.CGColor
        okButton.layer.borderWidth = 3.0
        okButton.addTarget(self, action: "confirmPiecesSelected", forControlEvents: UIControlEvents.TouchUpInside)
        
        cameraCapture.alpha = 0
        
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

        editSnapshotViewController = nil
        
        self.establishVideoPreviewArea()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = nil
        
        self.camera?.stopCamera()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.resetPieceSelector()
    }
    
    func initializeCamera() {
        self.camera = SprubixCamera(sender: self)
    }
    
    func establishVideoPreviewArea() {
        if cameraPreview == nil {
            //cameraPreview = UIView(frame: CGRectMake(0, screenHeight / 2 - screenWidth / 1.5, screenWidth, screenWidth / 0.75))
            cameraPreview = UIView(frame: CGRectMake(0, 0, screenWidth, screenWidth / 0.75))
            
            var touch = UITapGestureRecognizer(target:self, action:"manualFocus:")
            cameraPreview.addGestureRecognizer(touch)
            
            previewStillScrollView.insertSubview(cameraPreview, atIndex: 0)
        }
        
        self.preview = AVCaptureVideoPreviewLayer(session: self.camera?.session)
        self.preview?.videoGravity = AVLayerVideoGravityResizeAspect
        self.preview?.frame = self.cameraPreview.bounds
        self.cameraPreview.layer.addSublayer(self.preview)
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
    func scrollViewDidScroll(scrollView: UIScrollView) {
        calculatePage()
    }
    
    // MARK: Button Actions
    @IBAction func captureFrame(sender: AnyObject) {
            UIView.animateWithDuration(0.225, animations: { () -> Void in
                self.cameraPreview.alpha = 0.0
            })
            
            self.camera?.captureStillImage({ (image) -> Void in
                if image != nil {
                    
                    // this is the part where image is captured successfully
                    self.cameraCapture.enabled = false
                    
                    let selectedPiece = self.selectedPiecesOrdered[Int(self.snappedCount)]
                
                    // was selected by user
                    var previewStillImageView: UIImageView = UIImageView(frame: CGRectMake(0, self.snappedCount * screenWidth / 0.75, screenWidth, screenWidth / 0.75))
                    previewStillImageView.image = image
                    
                    // add this preview still into the storage array
                    self.previewStillImages.append(previewStillImageView)
                    
                    self.cameraPreview.frame.origin.y = (self.snappedCount + 1) * screenWidth / 0.75
                    self.cameraPreview.alpha = 1.0
                    self.previewStillScrollView.addSubview(previewStillImageView)
                    self.previewStillScrollView.contentSize = CGSize(width: screenWidth, height: self.pieceSelectorView.frame.size.height * (self.snappedCount + 2))
                    
                    self.snappedCount += 1

                    // the delay is for the cameraStill to remain on screen for a while before moving away
                    self.delay(0.6) {
                        if self.snappedCount == self.selectedCount {
                            self.cameraCapture.alpha = 0.0
                            
                            // go to edit controller
                            if self.editSnapshotViewController == nil {
                                self.editSnapshotViewController = EditSnapshotViewController()
                            }
                            
                            self.editSnapshotViewController.previewStillImages = self.previewStillImages
                            
                            self.navigationController?.pushViewController(self.editSnapshotViewController, animated: true)
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
            })
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
        })
    }
    
    // Button Callbacks
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

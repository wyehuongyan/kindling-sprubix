//
//  EditSnapshotViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

enum EditMode {
    case None
    case Brightness
    case Contrast
    case Sharpness
}

class EditSnapshotViewController: UIViewController {
    var selectedEditingMode: EditMode = .None
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    var handleBarView: UIView = UIView()
    var boundingBoxView: UIView = UIView()

    var firstTouchPoint: CGPoint!
    var lastTouchPoint: CGPoint = CGPointZero
    var draggedHandle: UIView?
    var draggedBox: UIView?
    
    var scale: CGFloat = 1.0
    var previousScale: CGFloat = 1.0
    var pinchedBox: UIView?
    
    var sprubixHandleBarSeperatorTop:SprubixHandleBarSeperator!
    var sprubixHandleBarSeperatorBottom:SprubixHandleBarSeperator!
    
    var sprubixHandleBars: [SprubixHandleBarSeperator] = [SprubixHandleBarSeperator]()
    var sprubixBoundingBoxes: [UIView] = [UIView]()
    var sprubixImageViews: [UIImageView] = [UIImageView]()
    var selectedImageView: UIImageView!
    var selectedPiecesOrdered: [String] = [String]()
    var selectedImagePos: Int!
    var oldBoxSizes: [CGSize] = [CGSize]()
    var imageCopies: [UIImage] = [UIImage]()
    var brightnessValues: [Float] = [0, 0, 0, 0]
    var contrastValues: [Float] = [25, 25, 25, 25]
    var sharpnessValues: [Float] = [0, 0, 0, 0]
    var sliderCurrentValue: Float!
    
    let dragLimit:CGFloat = 30
    
    var editScrollView: UIScrollView!
    var previewStillImages: [UIImageView]!
    
    // UI
    var editControlsPanel: UIView!
    var editControlsLabel: UILabel!
    var brightnessBtn: UIButton!
    var contrastBtn: UIButton!
    var sharpenBtn: UIButton!
    var editSlider: UISlider!
    var editSliderLabel: UILabel!
    
    var editConfirmPanel: UIView!
    var tickBtn: UIButton!
    var crossBtn: UIButton!
    
    // filters
    var gpuImageFilter: GPUImageFilter!
    var quickFilteredImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        initView()
        initBounds()
        initPreviewImages()
        saveImageCopies()
    }
    
    override func viewWillAppear(animated: Bool) {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Edit"
        
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
        
        // 5. create a next button
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        //nextButton.setImage(UIImage(named: "spruce-arrow-back"), forState: UIControlState.Normal)
        nextButton.setTitle("next", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "nextTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initView() {
        // scroll view
        editScrollView = UIScrollView(frame: CGRectMake(0, navigationHeight, screenWidth, screenWidth / 0.75))
        editScrollView.scrollEnabled = true
        editScrollView.alwaysBounceVertical = true
        editScrollView.showsVerticalScrollIndicator = false
        editScrollView.backgroundColor = UIColor.grayColor()
        
        editScrollView.contentSize = CGSizeMake(screenWidth, CGFloat(previewStillImages.count) * screenWidth / 0.75)
        
        self.view.addSubview(editScrollView)
        
        // editConfirmPanel (tick and cross)
        let editConfirmPanelHeight: CGFloat = 50
        editConfirmPanel = UIView(frame: CGRectMake(0, navigationHeight + screenWidth / 0.75, screenWidth, editConfirmPanelHeight)) // behind editControlsPanel
        editConfirmPanel.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        
        // buttons: tick and cross
        // cross
        crossBtn = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        crossBtn.frame = CGRectMake(0, 0, screenWidth / 2, editConfirmPanelHeight)
        var crossBtnImage: UIImage = UIImage(named: "filter-cross")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        crossBtn.setImage(crossBtnImage, forState: UIControlState.Normal)
        crossBtn.imageView?.tintColor = UIColor.whiteColor()
        Glow.addGlow(crossBtn)
        crossBtn.addTarget(self, action: "editBtnConfirmed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        editConfirmPanel.addSubview(crossBtn)
        
        // tick
        tickBtn = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        tickBtn.frame = CGRectMake(screenWidth / 2, 0, screenWidth / 2, editConfirmPanelHeight)
        var tickBtnImage: UIImage = UIImage(named: "filter-check")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        tickBtn.setImage(tickBtnImage, forState: UIControlState.Normal)
        tickBtn.imageView?.tintColor = UIColor.whiteColor()
        Glow.addGlow(tickBtn)
        tickBtn.addTarget(self, action: "editBtnConfirmed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        editConfirmPanel.addSubview(tickBtn)
        
        self.view.addSubview(editConfirmPanel)
        
        // editControlsPanel
        let editControlsPanelHeight: CGFloat = screenHeight - (navigationHeight + screenWidth / 0.75)
        
        editControlsPanel = UIView(frame: CGRectMake(0, navigationHeight + screenWidth / 0.75, screenWidth, editControlsPanelHeight))
        editControlsPanel.backgroundColor = UIColor.whiteColor()
        
        editControlsLabel = UILabel(frame: editControlsPanel.bounds)
        editControlsLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        editControlsLabel.numberOfLines = 0
        editControlsLabel.text = "Tap on an image for effects \n or Tap and Hold to drag"
        editControlsLabel.textColor = UIColor.lightGrayColor()
        editControlsLabel.textAlignment = NSTextAlignment.Center
        
        editControlsPanel.addSubview(editControlsLabel)
        
        // edit buttons: brightness, contrast and sharpen
        // brightness
        brightnessBtn = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        brightnessBtn.frame = CGRectMake(0, 0, screenWidth / 3, editControlsPanelHeight)
        brightnessBtn.setImage(UIImage(named: "snapshot-brightness"), forState: UIControlState.Normal)
        brightnessBtn.addTarget(self, action: "editBtnSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        Glow.addGlow(brightnessBtn)
        brightnessBtn.alpha = 0.0
        
        editControlsPanel.addSubview(brightnessBtn)
        
        // contrast
        contrastBtn = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        contrastBtn.frame = CGRectMake(screenWidth / 3, 0, screenWidth / 3, editControlsPanelHeight)
        contrastBtn.setImage(UIImage(named: "snapshot-contrast"), forState: UIControlState.Normal)
        contrastBtn.addTarget(self, action: "editBtnSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        Glow.addGlow(contrastBtn)
        contrastBtn.alpha = 0.0
        
        editControlsPanel.addSubview(contrastBtn)
        
        // sharpen
        sharpenBtn = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        sharpenBtn.frame = CGRectMake(2 * screenWidth / 3, 0, screenWidth / 3, editControlsPanelHeight)
        sharpenBtn.setImage(UIImage(named: "snapshot-sharpen"), forState: UIControlState.Normal)
        sharpenBtn.addTarget(self, action: "editBtnSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        Glow.addGlow(sharpenBtn)
        sharpenBtn.alpha = 0.0
        
        editControlsPanel.addSubview(sharpenBtn)
        
        // slider
        let editSliderWidth: CGFloat = 0.8 * screenWidth
        
        editSlider = UISlider(frame: CGRectMake(screenWidth / 2 - editSliderWidth / 2, 0, editSliderWidth, editControlsPanelHeight))
        editSlider.minimumValue = -100
        editSlider.maximumValue = 100
        editSlider.continuous = true
        editSlider.tintColor = sprubixColor
        editSlider.value = 0
        editSlider.addTarget(self, action: "editSliderValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        editSlider.alpha = 0.0
        
        let editSliderLabelWidth: CGFloat = 60
        editSliderLabel = UILabel(frame: CGRectMake(editSlider.center.x - editSliderLabelWidth / 2, editSlider.center.y - editSliderLabelWidth, editSliderLabelWidth, editSliderLabelWidth))
        editSliderLabel.text = "0"
        editSliderLabel.textColor = UIColor.lightGrayColor()
        editSliderLabel.textAlignment = NSTextAlignment.Center
        editSliderLabel.alpha = 0.0
        
        editControlsPanel.addSubview(editSliderLabel)
        editControlsPanel.addSubview(editSlider)
        
        self.view.addSubview(editControlsPanel)
    }
    
    func initBounds() {
        let sprubixHandleBarSeperatorHeight:CGFloat = 30
        
        // handlebar top
        sprubixHandleBarSeperatorTop = SprubixHandleBarSeperator(frame: CGRectMake(0, 0, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 0.0, lineStroke: 0)
        sprubixHandleBarSeperatorTop.draggable = false
    
        sprubixHandleBars.append(sprubixHandleBarSeperatorTop)
        handleBarView.addSubview(sprubixHandleBarSeperatorTop)
        
        // create new handle bar based on no. of previewStillImages
        for var i = 1; i < previewStillImages.count; i++ {
            var sprubixHandleBarSeperator = SprubixHandleBarSeperator(frame: CGRectMake(0, CGFloat(i) * screenWidth, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 80.0, lineStroke: 2)
            
            sprubixHandleBars.append(sprubixHandleBarSeperator)
            handleBarView.addSubview(sprubixHandleBarSeperator)
        }
        
        // handlebar bottom
        sprubixHandleBarSeperatorBottom = SprubixHandleBarSeperator(frame: CGRectMake(0, CGFloat(previewStillImages.count) * screenWidth, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 80.0, lineStroke: 2)
        
        sprubixHandleBars.append(sprubixHandleBarSeperatorBottom)
        handleBarView.addSubview(sprubixHandleBarSeperatorBottom)
        
        // bounding boxes
        for var i = 0; i < sprubixHandleBars.count - 1; i++ {
            let boundingBoxHeight: CGFloat = sprubixHandleBars[i + 1].frame.origin.y - sprubixHandleBars[i].frame.origin.y
            
            var boundingBox = UIView(frame: CGRectMake(0, CGFloat(i) * screenWidth, screenWidth, boundingBoxHeight))
            
            oldBoxSizes.append(boundingBox.frame.size)
            
            sprubixBoundingBoxes.append(boundingBox)
            boundingBoxView.addSubview(boundingBox)
        }
        
        // gesture recognizers
        var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handlePan:")
        longPressGestureRecognizer.minimumPressDuration = 0.2
        
        var pinchGestureRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "handlePinch:")
        var singleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        
        editScrollView.addGestureRecognizer(pinchGestureRecognizer)
        editScrollView.addGestureRecognizer(longPressGestureRecognizer)
        editScrollView.addGestureRecognizer(singleTapGestureRecognizer)
        
        editScrollView.addSubview(boundingBoxView)
        editScrollView.addSubview(handleBarView)
    }
    
    func initPreviewImages() {
        for var i = 0; i < previewStillImages.count; i++ {
            var previewStillImage = previewStillImages[i]
            
            sprubixBoundingBoxes[i].contentMode = UIViewContentMode.ScaleAspectFill
            
            var imageView: UIImageView = UIImageView(frame: CGRectMake(0, 0, screenWidth, screenWidth/0.75))
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            
            var fixedImage = fixOrientation(previewStillImage.image!)
            imageView.image = fixedImage
            
            imageView.center.y = sprubixBoundingBoxes[i].frame.size.height / 2
            
            sprubixImageViews.append(imageView)
            sprubixBoundingBoxes[i].addSubview(imageView)
            sprubixBoundingBoxes[i].clipsToBounds = true
        }
    }
    
    func resetHandleBarSeperators() {
        for var i = 0; i < sprubixHandleBars.count; i++ {
            sprubixHandleBars[i].frame.origin.y = CGFloat(i) * screenWidth
        }
    }
    
    func resetBoundingBoxes() {
        for var i = 0; i < sprubixHandleBars.count - 1; i++ {
            let boundingBoxHeight: CGFloat = sprubixHandleBars[i + 1].frame.origin.y - sprubixHandleBars[i].frame.origin.y
        
            sprubixBoundingBoxes[i].frame.origin.y = CGFloat(i) * screenWidth
            sprubixBoundingBoxes[i].frame.size.height = boundingBoxHeight
            sprubixBoundingBoxes[i].setNeedsDisplay()
        }
    }
    
    func handlePinch(gesture: UIPinchGestureRecognizer) {
        // impt: there should be one 'scale' property per image, currently it's shared. hence zoom in max to img1, img2 cant zoom
        firstTouchPoint = gesture.locationInView(boundingBoxView)
        var currentScale: CGFloat = min(gesture.scale * scale, 4.0)
        
        if gesture.state == UIGestureRecognizerState.Began {
            pinchedBox = findBoxBeingTouched(boundingBoxView, touchPoint: firstTouchPoint)
            previousScale = scale
        }
        else if gesture.state == UIGestureRecognizerState.Changed {
            if pinchedBox != nil {
                var scaleStep: CGFloat = currentScale / previousScale
                var pos = find(sprubixBoundingBoxes, pinchedBox!)
                
                sprubixImageViews[pos!].transform = CGAffineTransformScale(sprubixImageViews[pos!].transform, scaleStep, scaleStep)
                
                previousScale = currentScale
            }
        } else if   gesture.state == UIGestureRecognizerState.Ended ||
                    gesture.state == UIGestureRecognizerState.Cancelled ||
                    gesture.state == UIGestureRecognizerState.Failed {
            
                        if pinchedBox != nil {
                            // if trying to scale smaller than current bounding box's frame
                            if  gesture.scale * scale < pinchedBox!.frame.size.height / screenWidth || gesture.scale * scale < 1.0 { // screenWidth is original height of bounding box
                                //underscaled
                                
                                if gesture.scale * scale < pinchedBox!.frame.size.height / screenWidth {
                                    currentScale = pinchedBox!.frame.size.height / screenWidth
                                } else {
                                    currentScale = 1.0
                                }
                                
                                var pos = find(sprubixBoundingBoxes, pinchedBox!)
                                
                                UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                                    
                                    // 2 * self.pinchedBox!.frame.size.height / 3 is the expected width, based on current height
                                    if 2 * self.pinchedBox!.frame.size.height / 3 >= screenWidth / 0.75 {
                                        self.sprubixImageViews[pos!].frame.size = CGSizeMake(2 * self.pinchedBox!.frame.size.height / 3, self.pinchedBox!.frame.size.height)
                                    } else {
                                        self.sprubixImageViews[pos!].frame.size = CGSizeMake(screenWidth, screenWidth / 0.75)
                                    }
                                    
                                    // center image
                                    //self.sprubixImageViews[pos!].center.y = self.pinchedBox!.frame.size.height / 2
                                    
                                    }, completion: { finished in
                                        if finished {
                                            self.checkBoundaries(gesture)
                                            //gesture.scale = self.pinchedBox!.frame.size.height / screenWidth
                                        }
                                })
                            }
                        }

                        self.checkBoundaries(gesture)
                        scale = currentScale
        }
    }
    
    func handleTap(gesture: UITapGestureRecognizer) {
        if selectedEditingMode == .None {
            firstTouchPoint = gesture.locationInView(boundingBoxView)
        
            var tappedBox = findBoxBeingTouched(boundingBoxView, touchPoint: firstTouchPoint)
            
            if tappedBox != nil {
                // selected for image filters
                selectedImagePos = find(sprubixBoundingBoxes, tappedBox!)
                
                if selectedImageView != sprubixImageViews[selectedImagePos] {
                    selectedImageView = sprubixImageViews[selectedImagePos]

                    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                        self.editControlsLabel.alpha = 0.0
                        self.brightnessBtn.alpha = 1.0
                        self.contrastBtn.alpha = 1.0
                        self.sharpenBtn.alpha = 1.0
                        }, completion: nil)
                    
                    // the image selected will be the one where filters are directed at
                    // the other images are dimmed out temporarily
                    
                    for sprubixBoundingBox in sprubixBoundingBoxes {
                        if sprubixBoundingBox != tappedBox {
                            sprubixBoundingBox.alpha = 0.2
                        } else {
                            sprubixBoundingBox.alpha = 1.0
                        }
                    }
                    
                    editScrollView.scrollRectToVisible(tappedBox!.frame, animated: true)
                } else {
                    // tapped on the same image again
                    selectedImageView = nil
                    
                    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                        self.editControlsLabel.alpha = 1.0
                        self.brightnessBtn.alpha = 0.0
                        self.contrastBtn.alpha = 0.0
                        self.sharpenBtn.alpha = 0.0
                        }, completion: nil)
                    
                    for sprubixBoundingBox in sprubixBoundingBoxes {
                        sprubixBoundingBox.alpha = 1.0
                    }
                }
            }
        }
    }
    
    func findBoxBeingTouched(view: UIView, touchPoint: CGPoint) -> UIView? {
        
        // loop through subviews to find colliding handles
        for subview in view.subviews {
            let frame: CGRect = subview.frame
            
            // check x
            if (touchPoint.x >= frame.origin.x) && (touchPoint.x <= frame.origin.x + frame.size.width) {
                // check y
                if (touchPoint.y >= frame.origin.y) && (touchPoint.y <= frame.origin.y + frame.size.height) {
                    // found!
                    return subview as? UIView
                }
            }
        }
        
        return nil
    }
    
    // Callback Handler: handlebar drag gesture recognizer
    func handlePan(gesture: UILongPressGestureRecognizer) {
        //println("handlePan")
        
        if gesture.state == UIGestureRecognizerState.Began {
            firstTouchPoint = gesture.locationInView(handleBarView)
            draggedHandle = findHandlesBeingTouched(handleBarView, touchPoint: firstTouchPoint)
            
            if draggedHandle != nil {
                (draggedHandle as! SprubixHandleBarSeperator).setCustomBackgroundColor(sprubixColor)
            } else {
                // box
                draggedBox = findBoxBeingTouched(boundingBoxView, touchPoint: firstTouchPoint)
                
                if draggedBox != nil {
                    draggedBox!.layer.borderWidth = 5.0
                    draggedBox!.layer.borderColor = UIColor(red: 255/255, green: 102/255, blue: 108/255, alpha: 0.5).CGColor // sprubix color with 50% alpha
                }
            }
            
        } else if gesture.state == UIGestureRecognizerState.Changed {
            if draggedHandle != nil {
                let currentTouchPoint: CGPoint = gesture.locationInView(handleBarView)
                var translation:CGPoint = CGPointMake(currentTouchPoint.x - firstTouchPoint.x, currentTouchPoint.y - firstTouchPoint.y)

                if (draggedHandle as! SprubixHandleBarSeperator).draggable != false {
                    draggedHandle?.frame.origin.y = firstTouchPoint.y + translation.y
                }
                
                updateBoundingBoxes(draggedHandle!)
            } else if draggedBox != nil {
                // box
                let currentTouchPoint: CGPoint = gesture.locationInView(boundingBoxView)
                var translation:CGPoint = CGPointMake(currentTouchPoint.x - firstTouchPoint.x, currentTouchPoint.y - firstTouchPoint.y)
                
                var pos = find(sprubixBoundingBoxes, draggedBox!)
                var diff = CGPointMake(lastTouchPoint.x - translation.x, lastTouchPoint.y - translation.y)
                
                sprubixImageViews[pos!].center = CGPointMake(sprubixImageViews[pos!].center.x - diff.x, sprubixImageViews[pos!].center.y - diff.y)
                
                lastTouchPoint = translation
            }
            
            checkCentered()
            
        } else if gesture.state == UIGestureRecognizerState.Ended {
            if draggedHandle != nil {
                (draggedHandle as! SprubixHandleBarSeperator).setCustomBackgroundColor(UIColor.whiteColor())
            } else if draggedBox != nil {
                // box
                var pos = find(sprubixBoundingBoxes, draggedBox!)
                
                draggedBox!.layer.borderWidth = 0.0
                
                lastTouchPoint = CGPointZero
            }
            
            checkBoundaries(gesture)
        }
    }
    
    func findHandlesBeingTouched(view: UIView, touchPoint: CGPoint) -> UIView? {
        let tolerance: CGFloat = 20.0
        
        // loop through subviews to find colliding handles
        for subview in view.subviews {
            let frame: CGRect = subview.frame
            
            // check x
            if (touchPoint.x >= frame.origin.x - tolerance) && (touchPoint.x <= frame.origin.x + frame.size.width + tolerance) {
                // check y
                if (touchPoint.y >= frame.origin.y - tolerance) && (touchPoint.y <= frame.origin.y + tolerance) {
                    // found!
                    return subview as? UIView
                }
            }
        }
        
        return nil
    }
    
    func checkBoundaries(pinchGestureRecognizer: UIGestureRecognizer) {
        for var i = 0; i < sprubixImageViews.count; i++ {
            let imageView = sprubixImageViews[i]
            let boundingBox = sprubixBoundingBoxes[i]
            
            // check if imageview is dragged to non draggable regions
            if imageView.frame.origin.x > boundingBox.frame.origin.x {
                
                // left
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    pinchGestureRecognizer.enabled = false
                    
                    imageView.frame.origin.x = boundingBox.frame.origin.x
                    
                    }, completion: { finished in
                        pinchGestureRecognizer.enabled = true
                })
            }
            
            if imageView.frame.origin.y > 0 {
                // top
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    pinchGestureRecognizer.enabled = false
                    
                    imageView.frame.origin.y = 0
                    
                    }, completion: { finished in
                        pinchGestureRecognizer.enabled = true
                })
            }
            
            if imageView.frame.origin.x + imageView.frame.size.width < boundingBox.frame.origin.x + boundingBox.frame.size.width {
                // right
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    pinchGestureRecognizer.enabled = false
                    
                    imageView.frame.origin.x = boundingBox.frame.origin.x + boundingBox.frame.size.width - imageView.frame.size.width
                    }, completion: { finished in
                        pinchGestureRecognizer.enabled = true
                })
            }
            
            if imageView.frame.origin.y + imageView.frame.size.height < boundingBox.frame.size.height {
                // bottom
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    pinchGestureRecognizer.enabled = false
                    
                    imageView.frame.origin.y = boundingBox.frame.size.height - imageView.frame.size.height
                    }, completion: { finished in
                        pinchGestureRecognizer.enabled = true
                })
            }
        }
    }
    
    func updateBoundingBoxes(draggedHandle: UIView) {
        let pos = find(sprubixHandleBars, (draggedHandle as! SprubixHandleBarSeperator))!
        
        switch draggedHandle {
        case sprubixHandleBarSeperatorTop:
            
            if (draggedHandle as! SprubixHandleBarSeperator).draggable != false {
                // prevent going out of frame
                if draggedHandle.frame.origin.y < 0 {
                    draggedHandle.frame.origin.y = 0
                }
                
                if draggedHandle.frame.origin.y > sprubixHandleBars[pos + 1].frame.origin.y - dragLimit { // dragging down
                    draggedHandle.frame.origin.y = sprubixHandleBars[pos + 1].frame.origin.y - dragLimit
                }
                
                var boundingBoxBelowHeight:CGFloat = sprubixHandleBars[pos + 1].frame.origin.y - draggedHandle.frame.origin.y
                
                // min size of below section is dragLimit
                if boundingBoxBelowHeight < dragLimit {
                    boundingBoxBelowHeight = dragLimit
                }
                
                sprubixBoundingBoxes[pos].frame.origin.y = draggedHandle.frame.origin.y
                sprubixBoundingBoxes[pos].frame.size.height = boundingBoxBelowHeight
                
            }
            
        case sprubixHandleBarSeperatorBottom:
            
            if (draggedHandle as! SprubixHandleBarSeperator).draggable != false {
                // prevent going out of frame
    //            if draggedHandle.frame.origin.y > snapshot.frame.height {
    //                draggedHandle.frame.origin.y = snapshot.frame.height
    //            }
                
                if draggedHandle.frame.origin.y > sprubixHandleBars[pos - 1].frame.origin.y + sprubixImageViews[pos - 1].frame.height { // dragging down
                    draggedHandle.frame.origin.y = sprubixHandleBars[pos - 1].frame.origin.y + sprubixImageViews[pos - 1].frame.height
                } else if draggedHandle.frame.origin.y < sprubixHandleBars[pos - 1].frame.origin.y + dragLimit { // dragging up
                    draggedHandle.frame.origin.y = sprubixHandleBars[pos - 1].frame.origin.y + dragLimit
                }
                
                var boundingBoxAboveHeight:CGFloat = draggedHandle.frame.origin.y - sprubixHandleBars[pos - 1].frame.origin.y
                
                // min size of above section is dragLimit
                if boundingBoxAboveHeight < dragLimit {
                    boundingBoxAboveHeight = dragLimit
                }
                
                sprubixBoundingBoxes[sprubixBoundingBoxes.count - 1].frame.size.height = boundingBoxAboveHeight
            }
        
        default:
            
            if (draggedHandle as! SprubixHandleBarSeperator).draggable != false {
                // boundingBox above current handlebar
                if draggedHandle.frame.origin.y < sprubixHandleBars[pos + 1].frame.origin.y - sprubixImageViews[pos].frame.height { // dragging up
                    draggedHandle.frame.origin.y = sprubixHandleBars[pos + 1].frame.origin.y - sprubixImageViews[pos].frame.height
                } else if draggedHandle.frame.origin.y < sprubixHandleBars[pos - 1].frame.origin.y + dragLimit { // dragging up
                    draggedHandle.frame.origin.y = dragLimit
                }
                
                // boundingBox below current handlebar
                else if draggedHandle.frame.origin.y > sprubixHandleBars[pos - 1].frame.origin.y + sprubixImageViews[pos - 1].frame.height { // dragging down
                    draggedHandle.frame.origin.y = sprubixHandleBars[pos - 1].frame.origin.y + sprubixImageViews[pos - 1].frame.height
                }
                else if draggedHandle.frame.origin.y > sprubixHandleBars[pos + 1].frame.origin.y - dragLimit {
                    draggedHandle.frame.origin.y = sprubixHandleBars[pos + 1].frame.origin.y - dragLimit
                }
                
                // get latest heights
                var boundingBoxAboveHeight:CGFloat = draggedHandle.frame.origin.y - sprubixHandleBars[pos - 1].frame.origin.y
                var boundingBoxBelowHeight:CGFloat = sprubixHandleBars[pos + 1].frame.origin.y - draggedHandle.frame.origin.y
                
                // min size of above section if dragLimit
                if boundingBoxAboveHeight < dragLimit {
                    boundingBoxAboveHeight = dragLimit
                }
                
                // min size of below section if dragLimit
                if boundingBoxBelowHeight < dragLimit {
                    boundingBoxBelowHeight = dragLimit
                }
                
                sprubixBoundingBoxes[pos - 1].frame.size.height = boundingBoxAboveHeight
                sprubixBoundingBoxes[pos].frame.origin.y = draggedHandle.frame.origin.y
                sprubixBoundingBoxes[pos].frame.size.height = boundingBoxBelowHeight
            }
        }
    }
    
    func checkCentered() {
        for var i = 0; i < sprubixImageViews.count; i++ {
            
            let imageView = sprubixImageViews[i]
            let boundingBox = sprubixBoundingBoxes[i]
            
            // adjusts imageview center so imageview will always be centered
            if oldBoxSizes.count > i {
                var diff = (oldBoxSizes[i].height - boundingBox.frame.size.height) / 2
                imageView.center.y = imageView.center.y - diff
            }
        }
        
        // update old box sizes
        for var i = 0; i < sprubixBoundingBoxes.count; i++ {
            oldBoxSizes[i] = sprubixBoundingBoxes[i].frame.size
        }
    }
    
    // edit button callbacks
    func editBtnSelected(sender: UIButton) {
        
        var emptyNavItem:UINavigationItem = UINavigationItem()
        
        switch sender {
        case brightnessBtn:
            gpuImageFilter = GPUImageBrightnessFilter()
            
            editSlider.minimumValue = -100
            editSlider.maximumValue = 100
            editSlider.value = brightnessValues[selectedImagePos]
            
            selectedEditingMode = .Brightness
            
            emptyNavItem.title = "Brightness"
            
        case contrastBtn:
            
            gpuImageFilter = GPUImageContrastFilter()
            
            editSlider.minimumValue = -100
            editSlider.maximumValue = 100
            editSlider.value = contrastValues[selectedImagePos]
            
            selectedEditingMode = .Contrast
            
            emptyNavItem.title = "Contrast"
            
        case sharpenBtn:
            
            gpuImageFilter = GPUImageSharpenFilter()
            
            // set slider settings
            editSlider.minimumValue = -100
            editSlider.maximumValue = 100
            editSlider.value = sharpnessValues[selectedImagePos]
            
            selectedEditingMode = .Sharpness
            
            emptyNavItem.title = "Sharpen"
            
        default:
            fatalError("Unknown edit button pressed")
        }
        
        newNavBar.setItems([emptyNavItem], animated: false)
        
        // hide editControlsPanel
        // show brightness slider and editConfirmPanel
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.toggleEditSlider()
            self.editConfirmPanel.frame.origin.y = self.editConfirmPanel.frame.origin.y - self.editConfirmPanel.frame.size.height
            }, completion: nil)
    }
    
    func editSliderValueChanged(sender: UISlider) {
        var trackRect: CGRect = sender.trackRectForBounds(sender.bounds)
        var thumbRect: CGRect = sender.thumbRectForBounds(sender.bounds, trackRect: trackRect, value: sender.value)
        
        sliderCurrentValue = sender.value
        editSliderLabel.text = "\(Int(sender.value))"
        editSliderLabel.center = CGPointMake(thumbRect.origin.x + thumbRect.width / 2 + 0.1 * screenWidth,  sender.center.y - editSliderLabel.frame.size.height / 2);
        
        var width = 0.5 * imageCopies[selectedImagePos].size.width
        var resizedHeight = imageCopies[selectedImagePos].size.height * width / imageCopies[selectedImagePos].size.width
        
        switch (selectedEditingMode) {
        case .Brightness:
            // set brightness
            (gpuImageFilter as! GPUImageBrightnessFilter).forceProcessingAtSizeRespectingAspectRatio(CGSizeMake(width, resizedHeight))
            (gpuImageFilter as! GPUImageBrightnessFilter).brightness = CGFloat(sender.value / 100)
            
            quickFilteredImage = (gpuImageFilter as! GPUImageBrightnessFilter).imageByFilteringImage(imageCopies[selectedImagePos])
                
            selectedImageView.image = quickFilteredImage
            
        case .Contrast:
            // set contrast
            (gpuImageFilter as! GPUImageContrastFilter).forceProcessingAtSizeRespectingAspectRatio(CGSizeMake(width, resizedHeight))
            (gpuImageFilter as! GPUImageContrastFilter).contrast = CGFloat(sender.value / 100 * 4)
            
            quickFilteredImage = (gpuImageFilter as! GPUImageContrastFilter).imageByFilteringImage(imageCopies[selectedImagePos])
            
            selectedImageView.image = quickFilteredImage
            
        case .Sharpness:
            // set sharpness
            (gpuImageFilter as! GPUImageSharpenFilter).forceProcessingAtSizeRespectingAspectRatio(CGSizeMake(width, resizedHeight))
            (gpuImageFilter as! GPUImageSharpenFilter).sharpness = CGFloat(sender.value / 100 * 4)
        
            quickFilteredImage = (gpuImageFilter as! GPUImageSharpenFilter).imageByFilteringImage(imageCopies[selectedImagePos])
            
            selectedImageView.image = quickFilteredImage
            
        default:
            fatalError("Unknown editing mode selected")
        }
        
        quickFilteredImage = nil
    }
    
    // save and restore of original images
    func saveImageCopies() {
        for sprubixImageView in sprubixImageViews {
            imageCopies.append(sprubixImageView.image!)
        }
    }
    
    func restoreOriginalImages() {
        selectedImageView.image = imageCopies[selectedImagePos]
    }
    
    func editBtnConfirmed(sender: UIButton) {
        switch sender {
        case tickBtn:
            switch (selectedEditingMode) {
            case .Brightness:
                brightnessValues[selectedImagePos] = sliderCurrentValue
            case .Contrast:
                contrastValues[selectedImagePos] = sliderCurrentValue
            case .Sharpness:
                sharpnessValues[selectedImagePos] = sliderCurrentValue
            default:
                fatalError("Unknown editing mode selected")
            }
            
        case crossBtn:
            restoreOriginalImages()
            
        default:
            fatalError("Unknown edit confirm button pressed")
        }
        
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.toggleEditSlider()
            self.editConfirmPanel.frame.origin.y = self.editConfirmPanel.frame.origin.y + self.editConfirmPanel.frame.size.height
            }, completion: nil)
        
        newNavBar.setItems([newNavItem], animated: true)
        selectedEditingMode = .None
    }
    
    func toggleEditSlider() {
        if editSlider.alpha <= 0.0 {
            // hide the main buttons and show slider
            brightnessBtn.alpha = 0.0
            contrastBtn.alpha = 0.0
            sharpenBtn.alpha = 0.0
            
            editSlider.alpha = 1.0
            editSliderLabel.alpha = 1.0
        } else if editSlider.alpha >= 1 {
            brightnessBtn.alpha = 1.0
            contrastBtn.alpha = 1.0
            sharpenBtn.alpha = 1.0
            
            editSlider.alpha = 0.0
            editSliderLabel.alpha = 0.0
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
        
        var normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage;
        
    }
    
    // Callback Handler: navigation bar back button
    func backTapped(sender: UIBarButtonItem) {
        for subview in handleBarView.subviews {
            subview.removeFromSuperview()
        }
        
        for subview in boundingBoxView.subviews {
            subview.removeFromSuperview()
        }
        
        for subview in editScrollView.subviews {
            subview.removeFromSuperview()
        }
        
        for boundingBox in sprubixBoundingBoxes {
            for subview in boundingBox.subviews {
                subview.removeFromSuperview()
            }
        }
        
        for subview in self.view.subviews {
            subview.removeFromSuperview()
        }
        
        sprubixBoundingBoxes.removeAll()
        sprubixHandleBars.removeAll()
        sprubixImageViews.removeAll()
        oldBoxSizes.removeAll()
        imageCopies.removeAll()
        
        brightnessValues = [0, 0, 0, 0]
        contrastValues = [25, 25, 25, 25]
        sharpnessValues = [0, 0, 0, 0]
        
        scale = 1.0
        previousScale = 1.0
        
        self.navigationController?.popViewControllerAnimated(false)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        gpuImageFilter = nil
        quickFilteredImage = nil
    }
    
    func nextTapped(sender: UIBarButtonItem) {
        var snapshotShareController = SnapshotShareController()
        var totalHeight: CGFloat = 0
        
        var resizedHeight = imageCopies[0].size.height * screenWidth / imageCopies[0].size.width
        
        // GPUImageCropFilter on each sprubixImageView
        for var i = 0; i < sprubixImageViews.count; i++ {
            
            // normalize boundingBox on each sprubixImageView first
            var normalizedCropRegion: CGRect = CGRectMake(abs(sprubixImageViews[i].frame.origin.x)/sprubixImageViews[i].frame.size.width, abs(sprubixImageViews[i].frame.origin.y)/sprubixImageViews[i].frame.size.height, sprubixBoundingBoxes[i].frame.size.width/sprubixImageViews[i].frame.size.width, sprubixBoundingBoxes[i].frame.size.height/sprubixImageViews[i].frame.size.height)
            
            gpuImageFilter = GPUImageCropFilter(cropRegion: normalizedCropRegion)
            (gpuImageFilter as! GPUImageCropFilter).forceProcessingAtSizeRespectingAspectRatio(CGSizeMake(screenWidth, resizedHeight))
            quickFilteredImage = (gpuImageFilter as! GPUImageCropFilter).imageByFilteringImage(sprubixImageViews[i].image)
        
            snapshotShareController.images.append(quickFilteredImage)
            snapshotShareController.imageViewHeights.append(sprubixBoundingBoxes[i].frame.size.height)
            
            totalHeight += sprubixBoundingBoxes[i].frame.size.height
        }
        
        snapshotShareController.selectedPiecesOrdered = self.selectedPiecesOrdered
        snapshotShareController.totalHeight = totalHeight
        
        self.navigationController?.pushViewController(snapshotShareController, animated: true)
    }
}
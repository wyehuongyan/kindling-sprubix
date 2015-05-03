//
//  EditSnapshotViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class EditSnapshotViewController: UIViewController {

    var snapshot: UIImageView = UIImageView()
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
    
    let dragLimit:CGFloat = 30
    
    var editScrollView: UIScrollView!
    var previewStillImages: [UIImageView]!
    
    var oldBoxSizes: [CGSize] = [CGSize]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func initScrollView() {
        editScrollView = UIScrollView(frame: CGRectMake(0, navigationHeight, screenWidth, screenWidth / 0.75))
        editScrollView.scrollEnabled = true
        editScrollView.alwaysBounceVertical = true
        editScrollView.showsVerticalScrollIndicator = false
        editScrollView.backgroundColor = UIColor.lightGrayColor()
        
        editScrollView.contentSize = CGSizeMake(screenWidth, CGFloat(previewStillImages.count) * screenWidth / 0.75)
        
        self.view.addSubview(editScrollView)
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
            //boundingBox.backgroundColor = UIColor(red: CGFloat(i * 255)/255, green: 102/255, blue: 108/255, alpha: 1).colorWithAlphaComponent(0.5)
            
            oldBoxSizes.append(boundingBox.frame.size)
            
            sprubixBoundingBoxes.append(boundingBox)
            boundingBoxView.addSubview(boundingBox)
        }
        
        // gesture recognizer to drag the handle bars
        var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handlePan:")
        longPressGestureRecognizer.minimumPressDuration = 0.2
        
        var pinchGestureRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "handlePinch:")

        editScrollView.addGestureRecognizer(pinchGestureRecognizer)
        editScrollView.addGestureRecognizer(longPressGestureRecognizer)
        
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
            imageView.image = fixedImage//.sepia()
            
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
    
    override func viewWillAppear(animated: Bool) {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        var newNavBar:UINavigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        var newNavItem:UINavigationItem = UINavigationItem()
        newNavItem.title = "Edit"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        backButton.setImage(UIImage(named: "spruce-arrow-back"), forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        Glow.addGlow(backButton)
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
        
        initScrollView()
        initBounds()
        initPreviewImages()
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
    
    // Callback Handler: navigation bar back button
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(false)
        
        for subview in handleBarView.subviews {
            subview.removeFromSuperview()
        }
        
        for subview in boundingBoxView.subviews {
            subview.removeFromSuperview()
        }
        
        for subview in editScrollView.subviews {
            subview.removeFromSuperview()
        }
        
        sprubixBoundingBoxes.removeAll()
        sprubixHandleBars.removeAll()
        sprubixImageViews.removeAll()
        oldBoxSizes.removeAll()
        
        scale = 1.0
        previousScale = 1.0
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
}

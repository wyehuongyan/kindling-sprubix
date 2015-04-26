//
//  EditSnapshotViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class EditSnapshotViewController: UIViewController {

    var snapshot:UIImageView = UIImageView()
    var handleBarView:UIView = UIView()
    var boundingBoxView:UIView = UIView()
    var firstTouchPoint:CGPoint!
    var draggedHandle:UIView?
    
    var sprubixHandleBarSeperator1:SprubixHandleBarSeperator!
    var sprubixHandleBarSeperator2:SprubixHandleBarSeperator!
    var sprubixHandleBarSeperator3:SprubixHandleBarSeperator!
    var sprubixHandleBarSeperator4:SprubixHandleBarSeperator!
    var sprubixHandleBarSeperator5:SprubixHandleBarSeperator!
    
    var boundingBox1:UIView!
    var boundingBox2:UIView!
    var boundingBoxHead:UIView!
    var boundingBoxTop:UIView!
    var boundingBoxBottom:UIView!
    var boundingBoxFeet:UIView!
    
    let dragLimit:CGFloat = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        // snap shot still
        snapshot.frame = CGRectMake(0, navigationHeaderAndStatusbarHeight, screenWidth, screenWidth / 0.75)
        handleBarView.frame = snapshot.frame
        boundingBoxView.frame = snapshot.frame
        
        snapshot.contentMode = UIViewContentMode.ScaleAspectFit
        snapshot.backgroundColor = sprubixColor

        self.view.addSubview(snapshot)
        
        // gesture recognizer to drag the handle bars
        var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handlePan:")
        longPressGestureRecognizer.minimumPressDuration = 0.0
        
        handleBarView.userInteractionEnabled = true
        handleBarView.addGestureRecognizer(longPressGestureRecognizer)

        initHandleBarSeperators()
        initBoundingBoxes()
        
        self.view.addSubview(boundingBoxView)
        self.view.addSubview(handleBarView)
    }
    
    func initHandleBarSeperators() {
        // handlebar seperator 1
        let sprubixHandleBarSeperatorHeight:CGFloat = 30
        sprubixHandleBarSeperator1 = SprubixHandleBarSeperator(frame: CGRectMake(0, 0, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 80.0, lineStroke: 2)
        
        handleBarView.addSubview(sprubixHandleBarSeperator1)
        
        // handlebar seperator 2
        sprubixHandleBarSeperator2 = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.20 * snapshot.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 50.0, lineStroke: 2)
        
        handleBarView.addSubview(sprubixHandleBarSeperator2)
        
        // handlebar seperator 3
        sprubixHandleBarSeperator3 = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.45 * snapshot.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 50.0, lineStroke: 2)
        
        handleBarView.addSubview(sprubixHandleBarSeperator3)
        
        // handlebar seperator 4
        sprubixHandleBarSeperator4 = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.85 * snapshot.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 50.0, lineStroke: 2)
        
        handleBarView.addSubview(sprubixHandleBarSeperator4)
        
        // handlebar seperator 5
        sprubixHandleBarSeperator5 = SprubixHandleBarSeperator(frame: CGRectMake(0, snapshot.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 80.0, lineStroke: 2)
        
        handleBarView.addSubview(sprubixHandleBarSeperator5)
    }
    
    func resetHandleBarSeperators() {
        sprubixHandleBarSeperator1.frame.origin.y = 0
        sprubixHandleBarSeperator2.frame.origin.y = 0.20 * snapshot.frame.height
        sprubixHandleBarSeperator3.frame.origin.y = 0.45 * snapshot.frame.height
        sprubixHandleBarSeperator4.frame.origin.y = 0.85 * snapshot.frame.height
        sprubixHandleBarSeperator5.frame.origin.y = snapshot.frame.height
    }
    
    func resetBoundingBoxes() {
        let boundingBox1Height:CGFloat = sprubixHandleBarSeperator1.frame.origin.y
        boundingBox1.frame.size.height = boundingBox1Height
        
        let boundingBoxHeadHeight:CGFloat = sprubixHandleBarSeperator2.frame.origin.y - sprubixHandleBarSeperator1.frame.origin.y
        boundingBoxHead.frame.size.height = boundingBoxHeadHeight
        
        let boundingBoxTopHeight:CGFloat = sprubixHandleBarSeperator3.frame.origin.y - sprubixHandleBarSeperator2.frame.origin.y
        boundingBoxTop.frame.size.height = boundingBoxTopHeight
        
        let boundingBoxBottomHeight:CGFloat = sprubixHandleBarSeperator4.frame.origin.y - sprubixHandleBarSeperator3.frame.origin.y
        boundingBoxBottom.frame.size.height = boundingBoxBottomHeight
        
        let boundingBoxFeetHeight:CGFloat = sprubixHandleBarSeperator5.frame.origin.y - sprubixHandleBarSeperator4.frame.origin.y
        boundingBoxFeet.frame.size.height = boundingBoxFeetHeight
        
        let boundingBox2Height:CGFloat = snapshot.frame.height - sprubixHandleBarSeperator5.frame.origin.y
        boundingBox2.frame.size.height = boundingBox2Height
    }
    
    func initBoundingBoxes() {
        // 6 bounding boxes
        // 4 invisible, 2 alpha-ed (first and last)
        
        // alpha-ed first
        let boundingBox1Height:CGFloat = sprubixHandleBarSeperator1.frame.origin.y
        boundingBox1 = UIView(frame: CGRectMake(0, 0, screenWidth, boundingBox1Height))
        boundingBox1.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
        
        boundingBoxView.addSubview(boundingBox1)
        
        // bounding box head
        let boundingBoxHeadHeight:CGFloat = sprubixHandleBarSeperator2.frame.origin.y - sprubixHandleBarSeperator1.frame.origin.y
        boundingBoxHead = UIView(frame: CGRectMake(0, 0, screenWidth, boundingBoxHeadHeight))
        boundingBoxHead.backgroundColor = sprubixColor.colorWithAlphaComponent(0)
        
        boundingBoxView.addSubview(boundingBoxHead)
        
        // bounding box top
        let boundingBoxTopHeight:CGFloat = sprubixHandleBarSeperator3.frame.origin.y - sprubixHandleBarSeperator2.frame.origin.y
        boundingBoxTop = UIView(frame: CGRectMake(0, boundingBoxHeadHeight, screenWidth, boundingBoxTopHeight))
        boundingBoxTop.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0)
        
        boundingBoxView.addSubview(boundingBoxTop)
        
        // bounding box bottom
        let boundingBoxBottomHeight:CGFloat = sprubixHandleBarSeperator4.frame.origin.y - sprubixHandleBarSeperator3.frame.origin.y
        boundingBoxBottom = UIView(frame: CGRectMake(0, boundingBoxHeadHeight + boundingBoxTopHeight, screenWidth, boundingBoxBottomHeight))
        boundingBoxBottom.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0)
        
        boundingBoxView.addSubview(boundingBoxBottom)
        
        // bounding box feet
        let boundingBoxFeetHeight:CGFloat = sprubixHandleBarSeperator5.frame.origin.y - sprubixHandleBarSeperator4.frame.origin.y
        boundingBoxFeet = UIView(frame: CGRectMake(0, boundingBoxHeadHeight + boundingBoxTopHeight + boundingBoxBottomHeight, screenWidth, boundingBoxFeetHeight))
        boundingBoxFeet.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0)
        
        boundingBoxView.addSubview(boundingBoxFeet)
        
        // alpha-ed last
        let boundingBox2Height:CGFloat = snapshot.frame.height - sprubixHandleBarSeperator5.frame.origin.y
        boundingBox2 = UIView(frame: CGRectMake(0, sprubixHandleBarSeperator5.frame.origin.y, screenWidth, boundingBox2Height))
        boundingBox2.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
        
        boundingBoxView.addSubview(boundingBox2)
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

        resetHandleBarSeperators()
        resetBoundingBoxes()
    }
    
    // Callback Handler: handlebar drag gesture recognizer
    func handlePan(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.Began {
            firstTouchPoint = gesture.locationInView(gesture.view)
            draggedHandle = findHandlesBeingDragged(gesture.view!, touchPoint: firstTouchPoint)
        } else if gesture.state == UIGestureRecognizerState.Changed {
            if draggedHandle != nil {
                let currentTouchPoint: CGPoint = gesture.locationInView(gesture.view)
                var translation:CGPoint = CGPointMake(currentTouchPoint.x - firstTouchPoint.x, currentTouchPoint.y - firstTouchPoint.y)

                draggedHandle?.frame.origin.y = firstTouchPoint.y + translation.y
                
                updatePiecesBoxes(draggedHandle!)
                updateTopAndBottomBoxes(draggedHandle!)
            }
        }
    }
    
    func findHandlesBeingDragged(view: UIView, touchPoint: CGPoint) -> UIView? {
        let tolerance: CGFloat = 20.0
        
        // loop through subviews to find colliding handles
        for subview in view.subviews {
            let frame: CGRect = subview.frame
            
            // check x
            if (touchPoint.x >= frame.origin.x - tolerance) && (touchPoint.x <= frame.origin.x + frame.size.width + tolerance) {
                // check y
                if (touchPoint.y >= frame.origin.y - tolerance) && (touchPoint.y <= frame.origin.y + tolerance) {
                    return subview as? UIView
                }
            }
        }
        
        return nil
    }
    
    func updateTopAndBottomBoxes(draggedHandle: UIView) {
        // check invisible rects and bounding boxesso we
        if draggedHandle == sprubixHandleBarSeperator1 {
            boundingBox1.frame.size.height = draggedHandle.frame.origin.y
        } else if draggedHandle == sprubixHandleBarSeperator5 {
            boundingBox2.frame.size.height = snapshot.frame.height - draggedHandle.frame.origin.y
            boundingBox2.frame.origin.y = draggedHandle.frame.origin.y
        }
    }
    
    func updatePiecesBoxes(draggedHandle: UIView) {
        // handle 1 = head
        // handle 2 = head and top
        // handle 3 = top and bottom
        // handle 4 = bottom and feet
        // handle 5 = feet
        
        switch draggedHandle {
        case sprubixHandleBarSeperator1:
            //println("head")
            
            // prevent going out of frame
            if draggedHandle.frame.origin.y < 0 {
                draggedHandle.frame.origin.y = 0
            }
            
            if draggedHandle.frame.origin.y > sprubixHandleBarSeperator2.frame.origin.y - dragLimit { // dragging down
                draggedHandle.frame.origin.y = sprubixHandleBarSeperator2.frame.origin.y - dragLimit
            }
            
            var boundingBoxHeadHeight:CGFloat = sprubixHandleBarSeperator2.frame.origin.y - draggedHandle.frame.origin.y
            
            // min size of "head" section is dragLimit
            if boundingBoxHeadHeight < dragLimit {
                boundingBoxHeadHeight = dragLimit
            }
            
            boundingBoxHead.frame.origin.y = draggedHandle.frame.origin.y
            boundingBoxHead.frame.size.height = boundingBoxHeadHeight
            
        case sprubixHandleBarSeperator2:
            //println("head and top")
            
            // boundingBoxHead
            if draggedHandle.frame.origin.y < sprubixHandleBarSeperator1.frame.origin.y + dragLimit { // dragging up
                draggedHandle.frame.origin.y = sprubixHandleBarSeperator1.frame.origin.y + dragLimit
            }
            
            // boundingBoxTop
            if draggedHandle.frame.origin.y > sprubixHandleBarSeperator3.frame.origin.y - dragLimit { // dragging down
                draggedHandle.frame.origin.y = sprubixHandleBarSeperator3.frame.origin.y - dragLimit
            }
            
            // get latest heights
            var boundingBoxHeadHeight:CGFloat = draggedHandle.frame.origin.y - sprubixHandleBarSeperator1.frame.origin.y
            var boundingBoxTopHeight:CGFloat = sprubixHandleBarSeperator3.frame.origin.y - draggedHandle.frame.origin.y
            
            // min size of "head" section if dragLimit
            if boundingBoxHeadHeight < dragLimit {
                boundingBoxHeadHeight = dragLimit
            }
            
            // min size of "top" section if dragLimit
            if boundingBoxTopHeight < dragLimit {
                boundingBoxTopHeight = dragLimit
            }
            
            boundingBoxHead.frame.size.height = boundingBoxHeadHeight
            boundingBoxTop.frame.origin.y = draggedHandle.frame.origin.y
            boundingBoxTop.frame.size.height = boundingBoxTopHeight
            
        case sprubixHandleBarSeperator3:
            //println("top and bottom")
            
            // boundingBoxTop
            if draggedHandle.frame.origin.y < sprubixHandleBarSeperator2.frame.origin.y + dragLimit { // dragging up
                draggedHandle.frame.origin.y = sprubixHandleBarSeperator2.frame.origin.y + dragLimit
            }
            
            // boundingBoxBottom
            if draggedHandle.frame.origin.y > sprubixHandleBarSeperator4.frame.origin.y - dragLimit { // dragging down
                draggedHandle.frame.origin.y = sprubixHandleBarSeperator4.frame.origin.y - dragLimit
            }
            
            // get latest heights
            var boundingBoxTopHeight:CGFloat = draggedHandle.frame.origin.y - sprubixHandleBarSeperator2.frame.origin.y
            var boundingBoxBottomHeight:CGFloat = sprubixHandleBarSeperator4.frame.origin.y - draggedHandle.frame.origin.y
            
            // min size of "top" section if dragLimit
            if boundingBoxTopHeight < dragLimit {
                boundingBoxTopHeight = dragLimit
            }
            
            // min size of "bottom" section if dragLimit
            if boundingBoxBottomHeight < dragLimit {
                boundingBoxBottomHeight = dragLimit
            }
            
            boundingBoxTop.frame.size.height = boundingBoxTopHeight
            boundingBoxBottom.frame.origin.y = draggedHandle.frame.origin.y
            boundingBoxBottom.frame.size.height = boundingBoxBottomHeight
            
        case sprubixHandleBarSeperator4:
            //println("bottom and feet")
            
            // boundingBoxBottom
            if draggedHandle.frame.origin.y < sprubixHandleBarSeperator3.frame.origin.y + dragLimit { // dragging up
                draggedHandle.frame.origin.y = sprubixHandleBarSeperator3.frame.origin.y + dragLimit
            }
            
            // boundingBoxFeet
            if draggedHandle.frame.origin.y > sprubixHandleBarSeperator5.frame.origin.y - dragLimit { // dragging down
                draggedHandle.frame.origin.y = sprubixHandleBarSeperator5.frame.origin.y - dragLimit
            }
            
            // get latest heights
            var boundingBoxBottomHeight:CGFloat = draggedHandle.frame.origin.y - sprubixHandleBarSeperator3.frame.origin.y
            var boundingBoxFeetHeight:CGFloat = sprubixHandleBarSeperator5.frame.origin.y - draggedHandle.frame.origin.y
            
            // min size of "bottom" section if dragLimit
            if boundingBoxBottomHeight < dragLimit {
                boundingBoxBottomHeight = dragLimit
            }
            
            // min size of "feet" section if dragLimit
            if boundingBoxFeetHeight < dragLimit {
                boundingBoxFeetHeight = dragLimit
            }
            
            boundingBoxBottom.frame.size.height = boundingBoxBottomHeight
            boundingBoxFeet.frame.origin.y = draggedHandle.frame.origin.y
            boundingBoxFeet.frame.size.height = boundingBoxFeetHeight
            
        case sprubixHandleBarSeperator5:
            //println("feet")
            
            // prevent going out of frame
            if draggedHandle.frame.origin.y > snapshot.frame.height {
                draggedHandle.frame.origin.y = snapshot.frame.height
            }
            
            if draggedHandle.frame.origin.y < sprubixHandleBarSeperator4.frame.origin.y + dragLimit { // dragging up
                draggedHandle.frame.origin.y = sprubixHandleBarSeperator4.frame.origin.y + dragLimit
            }
            
            var boundingBoxFeetHeight:CGFloat = draggedHandle.frame.origin.y - sprubixHandleBarSeperator4.frame.origin.y
            
            // min size of "feet" section is dragLimit
            if boundingBoxFeetHeight < dragLimit {
                boundingBoxFeetHeight = dragLimit
            }
            
            boundingBoxFeet.frame.size.height = boundingBoxFeetHeight
            
        default:
            fatalError("Unidentified SprubixHandleBarSeperator")
        }
    }
    
    // Callback Handler: navigation bar back button
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(false)
    }
}

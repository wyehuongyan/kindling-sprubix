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
    var firstTouchPoint: CGPoint!
    var draggedHandle: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        // snap shot still
        snapshot.frame = CGRectMake(0, navigationHeaderAndStatusbarHeight, screenWidth, screenWidth / 0.75)
        snapshot.contentMode = UIViewContentMode.ScaleAspectFit
        snapshot.backgroundColor = sprubixColor
        
        // handlebar seperator 1
        let sprubixHandleBarSeperatorHeight:CGFloat = 30
        let sprubixHandleBarSeperator1:SprubixHandleBarSeperator = SprubixHandleBarSeperator(frame: CGRectMake(0, 0, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 80.0, lineStroke: 2)
        
        snapshot.addSubview(sprubixHandleBarSeperator1)
        
        // handlebar seperator 2
        let sprubixHandleBarSeperator2:SprubixHandleBarSeperator = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.20 * snapshot.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 50.0, lineStroke: 2)
        
        snapshot.addSubview(sprubixHandleBarSeperator2)
        
        // handlebar seperator 3
        let sprubixHandleBarSeperator3:SprubixHandleBarSeperator = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.45 * snapshot.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 50.0, lineStroke: 2)
        
        snapshot.addSubview(sprubixHandleBarSeperator3)
        
        // handlebar seperator 4
        let sprubixHandleBarSeperator4:SprubixHandleBarSeperator = SprubixHandleBarSeperator(frame: CGRectMake(0, 0.85 * snapshot.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 50.0, lineStroke: 2)
        
        snapshot.addSubview(sprubixHandleBarSeperator4)
        
        // handlebar seperator 5
        let sprubixHandleBarSeperator5:SprubixHandleBarSeperator = SprubixHandleBarSeperator(frame: CGRectMake(0, snapshot.frame.height, screenWidth, sprubixHandleBarSeperatorHeight), handleWidth: 80.0, lineStroke: 2)
        
        snapshot.addSubview(sprubixHandleBarSeperator5)
        
        // gesture recognizer to drag the handle bars
        var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handlePan:")
        longPressGestureRecognizer.minimumPressDuration = 0.0
        
        snapshot.userInteractionEnabled = true
        snapshot.addGestureRecognizer(longPressGestureRecognizer)
        
        self.view.addSubview(snapshot)
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
            }
        }
    }
    
    func findHandlesBeingDragged(view: UIView, touchPoint: CGPoint) -> UIView? {
        let tolerance: CGFloat = 15.0
        
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
    
    // Callback Handler: navigation bar back button
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(false)
    }
}

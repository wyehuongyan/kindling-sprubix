//
//  CheckoutOrderViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 12/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import MRProgress

class CheckoutOrderViewController: UIViewController {

    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // MRCheckmarkIconView
        let checkmarkIconWidth = screenWidth / 2
        let checkmarkIcon = MRCheckmarkIconView(frame: CGRectMake(screenWidth / 4, checkmarkIconWidth / 2, checkmarkIconWidth, checkmarkIconWidth))
        
        view.addSubview(checkmarkIcon)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Thank You"
        
        // 4. create a custom back button
        var doneButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        doneButton.setTitle("close", forState: UIControlState.Normal)
        doneButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        doneButton.frame = CGRect(x: -10, y: 0, width: 50, height: 20)
        doneButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        doneButton.addTarget(self, action: "doneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        doneButton.exclusiveTouch = true
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var doneBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: doneButton)
        doneBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.rightBarButtonItem = doneBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    // nav bar button callbacks
    func doneTapped(sender: UIBarButtonItem) {
        // go back to main feed
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}

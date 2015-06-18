//
//  ShopFeedController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 18/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class ShopFeedController: UIViewController {
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Discover"
        
        // 4. go back to main feed buton
        var mainFeedButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "profile-community")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        mainFeedButton.setImage(image, forState: UIControlState.Normal)
        mainFeedButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        mainFeedButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        mainFeedButton.addTarget(self, action: "mainFeedTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var mainFeedBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: mainFeedButton)
        newNavItem.rightBarButtonItem = mainFeedBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }

    func mainFeedTapped(sender: UIBarButtonItem) {
        UIView.transitionWithView(self.navigationController!.view, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.popViewControllerAnimated(false)
            }, completion: nil)
    }
}

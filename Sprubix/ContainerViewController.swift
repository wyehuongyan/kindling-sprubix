//
//  ContainerViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

enum SlideOutState {
    case Collapsed
    case SidePanelExpanded
}

class ContainerViewController: UIViewController, SidePanelViewControllerDelegate {
    
    var currentState: SlideOutState = .Collapsed {
        didSet {
            let shouldShowShadow = currentState != .Collapsed
            //showShadowForSprubixFeedController(shouldShowShadow)
        }
    }
    
    // main feed
    var sprubixNavigationController: UINavigationController!
    var mainFeedController: MainFeedController!
    var sidePanelViewController: SidePanelViewController? // optional as it will be added/removed at times
    var darkenedOverlay:UIView? // darkened overlay over the view when sidemenu is toggled on
    
    let sprubixFeedExpandedOffset: CGFloat = 60 // how much of sprubix feed that is left after animating off screen
    
    // side panel
    var userProfileViewController: UserProfileViewController?
    var sprubixCameraViewController: SprubixCameraViewController?
    var favoritesViewController: FavoritesViewController?
    var settingsViewController: SettingsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // main feed
        mainFeedController = MainFeedController()
        mainFeedController.delegate = self
        sprubixNavigationController = UINavigationController(rootViewController: mainFeedController)
        sprubixNavigationController.view.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(sprubixNavigationController.view)
        addChildViewController(sprubixNavigationController)
        
        sprubixNavigationController.didMoveToParentViewController(self)
        
        //let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        //sprubixNavigationController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MainFeedControllerDelegate
    func showUserProfile(user: NSDictionary) {
        userProfileViewController = UIStoryboard.userProfileViewController()
        
        userProfileViewController?.user = user
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(userProfileViewController!, animated: true)
    }
    
    func showCreateOutfit() {
        sprubixCameraViewController = UIStoryboard.sprubixCameraViewController()
        
        self.closeSidePanel()
        
        sprubixNavigationController.pushViewController(sprubixCameraViewController!, animated: false)
    }
    
    func showNotifications() {
        if sprubixNotificationViewController == nil {
            sprubixNotificationViewController = UIStoryboard.notificationViewController()
        }
        
        self.closeSidePanel()
        
        sprubixNotificationViewController?.delegate = self
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(sprubixNotificationViewController!, animated: true)
    }
    
    func showFavorites() {
        favoritesViewController = FavoritesViewController()
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(favoritesViewController!, animated: true)
    }
    
    func showSettingsView() {
        settingsViewController = UIStoryboard.settingsViewController()
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(settingsViewController!, animated: true)
    }
    
    // SprubixFeedControllerDelegate
    func toggleSidePanel() {
        let notAlreadyExpanded = (currentState != .SidePanelExpanded)
        
        if notAlreadyExpanded {
            addSidePanelViewController()
            addDarkenedOverlay()
        }
        
        animateSidePanel(shouldExpand: notAlreadyExpanded)
    }
    
    func addSidePanelViewController() {
        if sidePanelViewController == nil {
            var rootViewController = (sprubixNavigationController.viewControllers.first) as! MainFeedController
            
            sidePanelViewController = UIStoryboard.sidePanelViewController()
            sidePanelViewController!.sidePanelOptions = SidePanelOption.userOptions()
            
            addChildSidePanelController(sidePanelViewController!)
        }
    }
    
    func closeSidePanel() {
        if currentState != .Collapsed {
            toggleSidePanel()
        }
    }
    
    func addDarkenedOverlay() {
        if darkenedOverlay == nil {            
            darkenedOverlay = UIView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight))
            darkenedOverlay!.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.3)
            darkenedOverlay!.userInteractionEnabled = true
            darkenedOverlay!.exclusiveTouch = true
            darkenedOverlay!.alpha = 0
            
            var singleTap = UITapGestureRecognizer(target: self, action: Selector("toggleSidePanel"))
            singleTap.numberOfTapsRequired = 1
            
            darkenedOverlay!.addGestureRecognizer(singleTap)
            
            sprubixNavigationController.view.addSubview(darkenedOverlay!)
            
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.darkenedOverlay!.alpha = 1.0
                }, completion: nil)
        }
    }
    
    func addChildSidePanelController(sidePanelVC: SidePanelViewController) {
        sidePanelVC.delegate = self
        
        view.insertSubview(sidePanelVC.view, atIndex: 0)
        
        addChildViewController(sidePanelVC)
        sidePanelVC.didMoveToParentViewController(self)
    }
    
    func animateSidePanel(#shouldExpand: Bool) {
        if shouldExpand {
            currentState = .SidePanelExpanded
            
            animateSprubixFeedXPosition(targetPosition: CGRectGetWidth(sprubixNavigationController.view.frame) - sprubixFeedExpandedOffset)
        } else {
            animateSprubixFeedXPosition(targetPosition: 0) { finished in
                self.currentState = .Collapsed
                
                self.sidePanelViewController!.view.removeFromSuperview()
                self.sidePanelViewController = nil;
            }
            
            // remove darkened overlay
            if darkenedOverlay != nil {
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    self.darkenedOverlay!.alpha = 0
                    
                    }, completion: { finished in
                        self.darkenedOverlay!.removeFromSuperview()
                        self.darkenedOverlay = nil
                })
            }
        }
    }
    
    func animateSprubixFeedXPosition(#targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.sprubixNavigationController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }
    
    func showShadowForSprubixFeedController(shouldShowShadow: Bool) {
        if shouldShowShadow {
            sprubixNavigationController.view.layer.shadowOpacity = 0.8
        } else {
            sprubixNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
    
    // MARK: Gesture recognizer
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)
        
        switch(recognizer.state) {
        case .Began:
            if (currentState == .Collapsed) {
                if (gestureIsDraggingFromLeftToRight) {
                    addSidePanelViewController()
                }
                
                //showShadowForSprubixFeedController(true)
            }
        case .Changed:
            if (gestureIsDraggingFromLeftToRight || currentState == .SidePanelExpanded) {
                recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
                recognizer.setTranslation(CGPointZero, inView: view)
            }
        case .Ended:
            if (sidePanelViewController != nil) {
                // animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
                animateSidePanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
        default:
            break
        }
    }
}

extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
    
    class func sidePanelViewController() -> SidePanelViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("SidePanel") as? SidePanelViewController
    }
    
    class func userProfileViewController() -> UserProfileViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("UserProfile") as? UserProfileViewController
    }
    
    class func sprubixCameraViewController() -> SprubixCameraViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("SprubixCamera") as? SprubixCameraViewController
    }
    
    class func notificationViewController() -> NotificationViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("NotificationView") as? NotificationViewController
    }
    
    class func settingsViewController() -> SettingsViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("SettingsView") as? SettingsViewController
    }
}
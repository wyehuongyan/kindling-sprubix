//
//  ContainerViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import TSMessages
import PermissionScope

enum SlideOutState {
    case Collapsed
    case SidePanelExpanded
}

class ContainerViewController: UIViewController, SidePanelViewControllerDelegate {
    
    var currentState: SlideOutState = .Collapsed {
        didSet {
            let shouldShowShadow = currentState != .Collapsed
            showShadowForSidePanelController(shouldShowShadow)
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
    var createOutfitViewController: CreateOutfitViewController?
    var sprubixCameraViewController: SprubixCameraViewController?
    var favoritesViewController: FavoritesViewController?
    var settingsViewController: SettingsViewController?
    var inventoryViewController: InventoryViewController?
    var deliveryOptionsViewController: DeliveryOptionsViewController?
    var cartViewController: CartViewController?
    var ordersViewController: OrdersViewController?
    var shopOrderRefundDetailsViewController: ShopOrderRefundDetailsViewController?
    var shopOrderRefundsViewController: ShopOrderRefundsViewController?
    
    var notificationScope = PermissionScope()
    var statusBarHidden = true
    var statusBarStyle = UIStatusBarStyle.Default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // main feed
        mainFeedController = MainFeedController()
        mainFeedController.delegate = self
        sprubixNavigationController = UINavigationController(rootViewController: mainFeedController)
        
        view.addSubview(sprubixNavigationController.view)
        addChildViewController(sprubixNavigationController)
        
        sprubixNavigationController.didMoveToParentViewController(self)
        
        // all notification overlays will be shown in this controller
        TSMessage.setDefaultViewController(sprubixNavigationController)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        sprubixNavigationController.view.addGestureRecognizer(panGestureRecognizer)
        
        registerNotifications()
    }
    
    func registerNotifications() {
        // register for push notifications (ios 8)
        
        // initialized permissions
        notificationScope.addPermission(PermissionConfig(type: .Notifications, demands: .Required, message: "We use this to send you\r\noutfit suggestions and order updates", notificationCategories: .None))
        
        notificationScope.tintColor = sprubixColor
        notificationScope.headerLabel.text = "Hey there,"
        notificationScope.headerLabel.textColor = UIColor.darkGrayColor()
        notificationScope.bodyLabel.textColor = UIColor.lightGrayColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            self.notificationScope.show(authChange: { (finished, results) -> Void in
                var settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Sound | UIUserNotificationType.Badge, categories: nil)
                
                UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                UIApplication.sharedApplication().registerForRemoteNotifications()
                
                self.mainFeedController.tooltipEnable = true
                self.mainFeedController.startTooltipOnboarding()
                
                }, cancelled: { (results) -> Void in
                    self.mainFeedController.tooltipEnable = true
                    self.mainFeedController.startTooltipOnboarding()
                    
                    println("Unable to register to push notifications, thing was cancelled")
            })
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return statusBarHidden;
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Slide
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusBarStyle
    }
    
    // SidePanelViewControllerDelegate
    func showMainFeed() {
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.popToRootViewControllerAnimated(true)
    }
    
    func showUserProfile(user: NSDictionary) {
        userProfileViewController = UIStoryboard.userProfileViewController()
        
        userProfileViewController?.user = user
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(userProfileViewController!, animated: true)
    }
    
    func showCreateOutfit() {
        if createOutfitViewController == nil {
            createOutfitViewController = CreateOutfitViewController()
        }
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(createOutfitViewController!, animated: true)
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
    
    func showSettings() {
        settingsViewController = UIStoryboard.settingsViewController()
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(settingsViewController!, animated: true)
    }
    
    func showInventory() {
        inventoryViewController = UIStoryboard.inventoryViewController()
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(inventoryViewController!, animated: true)
    }
    
    func showDeliveryOptions() {
        deliveryOptionsViewController = UIStoryboard.deliveryOptionsViewController()
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(deliveryOptionsViewController!, animated: true)
    }
    
    func showOrders() {
        ordersViewController = UIStoryboard.ordersViewController()
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(ordersViewController!, animated: true)

        /*
        let checkoutOrderViewController = CheckoutOrderViewController()
        
        checkoutOrderViewController.userOrderId = 8
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(checkoutOrderViewController, animated: true)
        */
    }
    
    func showShopOrderDetails(shopOrder: NSDictionary) {
        let shopOrderDetailsViewController = UIStoryboard.shopOrderDetailsViewController()
        
        shopOrderDetailsViewController!.orderNum = shopOrder["uid"] as! String
        shopOrderDetailsViewController!.shopOrder = shopOrder.mutableCopy() as! NSMutableDictionary
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(shopOrderDetailsViewController!, animated: true)
    }
    
    func showRefunds() {
        shopOrderRefundsViewController = UIStoryboard.shopOrderRefundsViewController()
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(shopOrderRefundsViewController!, animated: true)
    }
    
    func showRefundDetails(shopOrderRefund: NSDictionary) {
        var shopOrderRefundDetailsViewController = UIStoryboard.shopOrderRefundDetailsViewController()
        
        shopOrderRefundDetailsViewController?.shopOrder = shopOrderRefund["shop_order"] as! NSMutableDictionary
        shopOrderRefundDetailsViewController?.existingRefund = shopOrderRefund
        shopOrderRefundDetailsViewController?.fromRefundView = true
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(shopOrderRefundDetailsViewController!, animated: true)
    }
    
    func showCart() {
        cartViewController = UIStoryboard.cartViewController()
        cartViewController!.delegate = self
        
        self.closeSidePanel()
        
        sprubixNavigationController.delegate = nil
        sprubixNavigationController.pushViewController(cartViewController!, animated: true)
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
            sidePanelViewController = UIStoryboard.sidePanelViewController()
            
            let userData: NSDictionary? = defaults.dictionaryForKey("userData")
            
            if userData != nil {
                let userType = userData!["shoppable_type"] as! String
                
                if userType.lowercaseString.rangeOfString("shopper") != nil {
                    sidePanelViewController!.sidePanelOptions = SidePanelOption.userOptions()
                } else {
                    sidePanelViewController!.sidePanelOptions = SidePanelOption.shopOptions()
                }
            }
            
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
            darkenedOverlay = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
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
        sidePanelVC.view.frame.origin.x = -screenWidth
        
        view.insertSubview(sidePanelVC.view, atIndex: 1)
        
        addChildViewController(sidePanelVC)
        sidePanelVC.didMoveToParentViewController(self)
    }
    
    func animateSidePanel(#shouldExpand: Bool) {
        if shouldExpand {
            currentState = .SidePanelExpanded
            
            animateSideMenuXPosition(targetPosition: -sprubixFeedExpandedOffset)
            
            UIView.animateWithDuration(0.3, animations: {
                self.statusBarHidden = true
                self.setNeedsStatusBarAppearanceUpdate()
                })
            
        } else {
            animateSideMenuXPosition(targetPosition: -screenWidth) { finished in
                self.currentState = .Collapsed
                
                if self.sidePanelViewController != nil {
                    self.sidePanelViewController!.view.removeFromSuperview()
                    self.sidePanelViewController = nil
                }
            }
            
            // remove darkened overlay
            if darkenedOverlay != nil {
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    self.darkenedOverlay!.alpha = 0
                    
                    }, completion: { finished in
                        self.darkenedOverlay?.removeFromSuperview()
                        self.darkenedOverlay = nil
                })
            }
            
            UIView.animateWithDuration(0.3, animations: {
                self.statusBarHidden = false
                self.setNeedsStatusBarAppearanceUpdate()
            })
            
            sprubixNavigationController.setNavigationBarHidden(false, animated: true)
        }
    }
    
    func animateSideMenuXPosition(#targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.sidePanelViewController!.view.frame.origin.x = targetPosition
            
            }, completion: completion)
    }
    
    func showShadowForSidePanelController(shouldShowShadow: Bool) {
        if sidePanelViewController != nil {
            if shouldShowShadow {
                sidePanelViewController!.view.layer.shadowOpacity = 0.8
            } else {
                sidePanelViewController!.view.layer.shadowOpacity = 0.0
            }
        }
    }
    
    // MARK: Gesture recognizer
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        var currentViewController = sprubixNavigationController.childViewControllers[sprubixNavigationController.childViewControllers.count - 1] as! UIViewController
        
        if currentViewController.isKindOfClass(MainFeedController) || currentViewController.isKindOfClass(DiscoverFeedController) {
        
            let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)
            
            switch(recognizer.state) {
            case .Began:
                if (currentState == .Collapsed) {
                    if (gestureIsDraggingFromLeftToRight) {
                        addSidePanelViewController()
                        addDarkenedOverlay()
                    }
                    
                    showShadowForSidePanelController(true)
                }
            case .Changed:
                if (gestureIsDraggingFromLeftToRight || currentState == .SidePanelExpanded) {
                
                    addSidePanelViewController()
                    addDarkenedOverlay()
                
                    if self.sidePanelViewController != nil {
                        self.sidePanelViewController!.view.center.x = self.sidePanelViewController!.view.center.x + recognizer.translationInView(view).x
                    }
                    
                    recognizer.setTranslation(CGPointZero, inView: view)
                }
            case .Ended:
                if (sidePanelViewController != nil) {
                    // animate the side panel open or closed based on whether the view has moved more or less than halfway
                    let hasMovedGreaterThanHalfway = self.sidePanelViewController!.view.center.x > 0
                    animateSidePanel(shouldExpand: hasMovedGreaterThanHalfway)
                }
            default:
                break
            }
        }
    }
}

extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
    class func authStoryboard() -> UIStoryboard { return UIStoryboard(name: "Auth", bundle: NSBundle.mainBundle()) }
    class func shopStoryboard() -> UIStoryboard { return UIStoryboard(name: "Shop", bundle: NSBundle.mainBundle()) }
    class func menuStoryboard() -> UIStoryboard { return UIStoryboard(name: "Menu", bundle: NSBundle.mainBundle()) }
    class func settingsStoryboard() -> UIStoryboard { return UIStoryboard(name: "Settings", bundle: NSBundle.mainBundle()) }
    
    // Main storyboard
    class func sprubixCameraViewController() -> SprubixCameraViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("SprubixCamera") as? SprubixCameraViewController
    }
    
    // Auth storyboard
    class func signInViewController() -> SignInViewController? {
        return authStoryboard().instantiateViewControllerWithIdentifier("SignIn") as? SignInViewController
    }
    
    class func searchResultsUsersViewController() -> SearchResultsUsersViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("SearchResultsUsersView") as? SearchResultsUsersViewController
    }
    
    // Menu storyboard
    class func sidePanelViewController() -> SidePanelViewController? {
        return menuStoryboard().instantiateViewControllerWithIdentifier("SidePanel") as? SidePanelViewController
    }
    
    class func userProfileViewController() -> UserProfileViewController? {
        return menuStoryboard().instantiateViewControllerWithIdentifier("UserProfile") as? UserProfileViewController
    }
    
    class func notificationViewController() -> NotificationViewController? {
        return menuStoryboard().instantiateViewControllerWithIdentifier("NotificationView") as? NotificationViewController
    }
    
    class func userFollowListViewController() -> UserFollowListViewController? {
        return menuStoryboard().instantiateViewControllerWithIdentifier("UserFollowListView") as? UserFollowListViewController
    }
    
    // Shop storyboard
    class func inventoryViewController() -> InventoryViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("InventoryView") as? InventoryViewController
    }
    
    class func ordersViewController() -> OrdersViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("OrdersView") as? OrdersViewController
    }
    
    class func shopOrdersViewController() -> ShopOrdersViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("ShopOrdersView") as? ShopOrdersViewController
    }
    
    class func shopOrderDetailsViewController() -> ShopOrderDetailsViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("ShopOrderDetailsView") as? ShopOrderDetailsViewController
    }
    
    class func shopOrderRefundDetailsViewController() -> ShopOrderRefundDetailsViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("ShopOrderRefundDetailsView") as? ShopOrderRefundDetailsViewController
    }
    
    class func shopOrderRefundsViewController() -> ShopOrderRefundsViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("ShopOrderRefundsView") as? ShopOrderRefundsViewController
    }
    
    class func customerDetailsViewController() -> CustomerDetailsViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("CustomerDetailsView") as? CustomerDetailsViewController
    }
    
    class func deliveryOptionsViewController() -> DeliveryOptionsViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("DeliveryOptionsView") as? DeliveryOptionsViewController
    }
    
    class func cartViewController() -> CartViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("CartView") as? CartViewController
    }
    
    class func checkoutPointsViewController() -> CheckoutPointsViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("CheckoutPointsView") as? CheckoutPointsViewController
    }
    
    class func checkoutViewController() -> CheckoutViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("CheckoutView") as? CheckoutViewController
    }
    
    class func dashboardViewController() -> DashboardViewController? {
        return shopStoryboard().instantiateViewControllerWithIdentifier("DashboardView") as? DashboardViewController
    }
    
    // Settings storyboard
    class func settingsViewController() -> SettingsViewController? {
        return settingsStoryboard().instantiateViewControllerWithIdentifier("SettingsView") as? SettingsViewController
    }
    
    class func deliveryAddressesViewController() -> DeliveryAddressesViewController? {
        return settingsStoryboard().instantiateViewControllerWithIdentifier("DeliveryAddressesView") as? DeliveryAddressesViewController
    }
    
    class func paymentMethodsViewController() -> PaymentMethodsViewController? {
        return settingsStoryboard().instantiateViewControllerWithIdentifier("PaymentMethodsView") as? PaymentMethodsViewController
    }
    
    class func editProfileViewController() -> EditProfileViewController? {
        return settingsStoryboard().instantiateViewControllerWithIdentifier("EditProfileView") as? EditProfileViewController
    }
}
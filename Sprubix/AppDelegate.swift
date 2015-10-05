//
//  AppDelegate.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 26/2/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CoreData
import AFNetworking
import AFNetworkActivityLogger
import Mixpanel
import Fabric
import Crashlytics
import JLRoutes
import FBSDKCoreKit
import TSMessages

struct SprubixConfig {
    struct URL {
        //static let api: String = "http://192.168.1.1/~shion/kindling-core/public/index.php"
        //static let api: String = "http://sprubix-ch.ngrok.io/~shion/kindling-core/public/index.php"
        static let api: String = "http://sprubix-wh.ngrok.io/~wyehuongyan/kindling-core/public/index.php"
        static let firebase: String = "https://sprubixtest.firebaseio.com/"
        
        //static let api: String = "https://api.sprbx.com"
        //static let firebase: String = "https://sprubix.firebaseio.com/"
    }
    struct Token {
        static let mixpanel = ""
        //static let mixpanel = "7b1423643b7e52dad5680f5fdc390a88" // live
    }
}

let manager = AFHTTPRequestOperationManager()
let containerViewController = ContainerViewController()
let defaults = NSUserDefaults.standardUserDefaults()
let firebaseRef = Firebase(url: SprubixConfig.URL.firebase)
let mixpanel = Mixpanel.sharedInstanceWithToken(SprubixConfig.Token.mixpanel)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let defaults = NSUserDefaults.standardUserDefaults()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        AFNetworkActivityLogger.sharedLogger().startLogging()

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.rootViewController = containerViewController
        window!.makeKeyAndVisible()
        window!.backgroundColor = UIColor.whiteColor()
        window!.tintColor = sprubixColor
        
        configureSecurityPolicy()
        checkLoggedIn()
        
        // handle push notifications when app is not running
        var apnsBody: NSDictionary? = (launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary)
        
        if apnsBody != nil {
            // Do your code with apnsBody
            containerViewController.showMainFeed()
        }
        
        registerURLSchemes()
        
        // handle url schemes when app is not running
        var url: NSURL? = (launchOptions?[UIApplicationLaunchOptionsURLKey] as? NSURL)
        
        if url != nil {
            JLRoutes.routeURL(url)
        }
        
        // Mixpanel - App Launched
        MixpanelService.track("App Launched")
        // Mixpanel - End
        
        Fabric.with([Crashlytics()])
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        // don't run check if user is at signup page (and for FB's out-of-app's sign-in)
        var atSignupScreen: Bool = false

        if let viewControllers = self.window?.rootViewController {
            for viewController in viewControllers.childViewControllers {
                if viewController.isKindOfClass(UINavigationController) {
                    let vcClassName = NSStringFromClass((viewController as! UINavigationController).visibleViewController.classForCoder)
                    if vcClassName.rangeOfString("SignUpViewController") != nil || vcClassName.rangeOfString("SignInViewController") != nil {
                        atSignupScreen = true
                    }
                }
            }
        }
        
        if atSignupScreen == false {
            checkLoggedIn();
        }
    }
    
    func configureSecurityPolicy() {
        let securityPolicy = AFSecurityPolicy()
        let certificatePath = NSBundle.mainBundle().pathForResource("SprubixCA", ofType: "cer")!
        let certificateData = NSData(contentsOfFile: certificatePath)!
        
        securityPolicy.pinnedCertificates = [certificateData];
        securityPolicy.allowInvalidCertificates = true
        securityPolicy.validatesCertificateChain = false
        manager.securityPolicy = securityPolicy
    }
    
    func checkLoggedIn() {
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let signInVC = storyboard.instantiateViewControllerWithIdentifier("SignInNav") as! UIViewController
        
        var activeController:UIViewController = self.window!.rootViewController!
        
        if activeController.isKindOfClass(UINavigationController) {
            println("This active controller is a UINavigationController")
            activeController = (activeController as! UINavigationController).visibleViewController
        }
        
        manager.GET(SprubixConfig.URL.api + "/auth/check",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                var response = responseObject as! NSDictionary
                var user = response["user"] as? NSDictionary
                
                let localUserId:Int? = self.defaults.objectForKey("userId") as? Int
                
                if user != nil && localUserId != nil {
                    println("I am logged in!")
                    
                    // Mixpanel - Setup
                    MixpanelService.setup()
                    // Mixpanel - End
                    
                } else {
                    println("No, I am not logged in.")
                    self.defaults.removeObjectForKey("userId")
                    
                    if activeController.presentedViewController != nil {
                        println("dismiss \(activeController.presentedViewController) first")
                        
                        // dismiss any other view first
                        activeController.dismissViewControllerAnimated(false, completion: nil)
                        
                        // then present the login view
                        self.window!.makeKeyAndVisible()
                        activeController.presentViewController(signInVC, animated: false, completion: nil)

                    } else {
                        self.window!.makeKeyAndVisible()
                        
                        println("The current activeController is \(activeController)")
                        
                        activeController.presentViewController(signInVC, animated: true, completion: nil)
                        
                    }
                }
                
                //println(responseObject)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                SprubixReachability.handleError(error.code)
        })
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.sprubix.Sprubix" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Sprubix", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Sprubix.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as [NSObject : AnyObject])
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: Push Notifications
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
        var tokenString = ""
        
        for var i = 0; i < deviceToken.length; i++ {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        // send token to server for storage
        manager.POST(SprubixConfig.URL.api + "/auth/apns/token",
            parameters: [
                "device_token": tokenString
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                var status = responseObject["status"] as! String
                
                if status == "200" {
                    println("Device token set successfully")
                } else if status == "500" {
                    println("Error in setting device token: \(responseObject)")
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("Failed to get token. Error: \(error)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if application.applicationState == UIApplicationState.Active {
            // application already in foreground
            println("APNS received. Application in foreground.")
        } else {
            // app was brought from background to foreground
            println("APNS received. Application entering from bg to fg.")
            containerViewController.showMainFeed()
        }
    }
    
    // MARK: URL Schemes
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        
        if url.scheme == "sprubixapp" {
            
            return JLRoutes.routeURL(url)
            
        } else {
            return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
        }
    }
    
    func registerURLSchemes() {
        // route to shop order details
        JLRoutes.addRoute("/order/shop/:shopOrderId", handler: {
            parameters in
            
            // find shop order id for shop order details
            let shopOrderId = parameters["shopOrderId"] as! String
            
            // REST call to server to retrieve shop orders
            manager.POST(SprubixConfig.URL.api + "/orders/shop",
                parameters: [
                    "shop_order_ids": [shopOrderId.toInt()!]
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var shopOrder = (responseObject["data"] as! [NSDictionary])[0].mutableCopy() as! NSMutableDictionary
                    
                    // go to shop order details view
                    containerViewController.showShopOrderDetails(shopOrder)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
            
            return true
        })
        
        // route for user email verification
        JLRoutes.addRoute("/auth/:userId/verify/:verificationCode", handler: {
            parameters in
        
            // get user id
            let userId = parameters["userId"] as! String
            let verificationCode = parameters["verificationCode"] as! String
            
            // REST call to server to retrieve shop orders
            manager.POST(SprubixConfig.URL.api + "/auth/email/verify",
                parameters: [
                    "user_id": userId,
                    "verification_code": verificationCode
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var status = responseObject["status"] as! String
                    var automatic: NSTimeInterval = 0
                    
                    if status == "200" {
                        // success
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Account verified. Thank you!", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                    } else {
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Verification code did not match. Account not verified.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    var automatic: NSTimeInterval = 0
                    
                    // error exception
                    TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
            })
            
            return true
        })
        
        // route to shop order refund details
        JLRoutes.addRoute("/refund/:shopOrderRefundId", handler: {
            parameters in
            
            // find shop order id for shop order details
            let shopOrderRefundId = parameters["shopOrderRefundId"] as! String
            
            // REST call to server to retrieve shop orders
            manager.GET(SprubixConfig.URL.api + "/refund/\(shopOrderRefundId)",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    let shopOrderRefund = responseObject as! NSDictionary
                    
                    // go to shop order refund details view
                    containerViewController.showRefundDetails(shopOrderRefund)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
            
            return true
        })
    }
}


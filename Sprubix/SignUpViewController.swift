//
//  ViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 26/2/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CoreData
import AFNetworking
import TSMessages
import FBSDKLoginKit

class SignUpViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    let signInButtonWidth:CGFloat! = screenWidth * 0.9
    let signInButtonHeight:CGFloat! = 50
    let haveAccountButtonHeight:CGFloat = 20
    
    var signInView:UIView!
    var fbLoginButton: FBSDKLoginButton!
    var emailButton: UIButton!
    var haveAccountButton: UIButton!
    
    let emailIconWidth:CGFloat! = 40
    let sprubixLogoWidth:CGFloat! = 150
    var sprubixLogoView:UIImageView!
    
    var oldFrameRect: CGRect!
    
    var FBUserData: NSMutableDictionary = NSMutableDictionary()
    
    @IBAction func clickTermsOfService(sender: UIButton) {
        let webURL: NSURL = NSURL(string: "http://www.sprubix.com/terms-of-service")!
        UIApplication.sharedApplication().openURL(webURL)
    }
    
    @IBAction func clickPrivacyPolicy(sender: UIButton) {
        let webURL: NSURL = NSURL(string: "http://www.sprubix.com/privacy-policy")!
        UIApplication.sharedApplication().openURL(webURL)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let signInViewHeight = (signInButtonHeight + 10) * 2 + haveAccountButtonHeight
        signInView = UIView(frame: CGRect(x: screenWidth / 2 - signInButtonWidth / 2, y: screenHeight / 2, width: signInButtonWidth, height: signInViewHeight))
        
        view.addSubview(signInView)
        
        // Facebook login button
        fbLoginButton = FBSDKLoginButton(frame: CGRect(x: 0, y: 0, width: signInButtonWidth, height: signInButtonHeight))
        
        fbLoginButton.setTitle("Facebook", forState: UIControlState.Normal)
        fbLoginButton.titleLabel?.font = UIFont.systemFontOfSize(17.0)
        //fbLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.delegate = self
        signInView.addSubview(fbLoginButton)
        
        view.addSubview(signInView)
        
        // Email button
        let emailButtonY = signInButtonHeight + 10
        emailButton = UIButton(frame: CGRect(x: 0, y: emailButtonY, width: signInButtonWidth, height: signInButtonHeight))
        
        emailButton.backgroundColor = sprubixColor
        emailButton.setTitle("Sign up with Email", forState: UIControlState.Normal)
        emailButton.addTarget(self, action: "emailButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        let emailImage = UIImageView(image: UIImage(named: "sidemenu-messages"))
        emailImage.image = emailImage.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        emailImage.tintColor = UIColor.whiteColor()
        emailImage.frame = CGRect(x: 10, y: 5, width: emailIconWidth, height: emailIconWidth)
        emailButton.addSubview(emailImage)
        
        signInView.addSubview(emailButton)
        
        // Have account
        let haveAccountY = emailButtonY + signInButtonHeight + 5
        haveAccountButton = UIButton(frame: CGRect(x: 0, y: haveAccountY, width: signInButtonWidth, height: haveAccountButtonHeight))
        
        haveAccountButton.setTitle("Already have an account?", forState: UIControlState.Normal)
        haveAccountButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        haveAccountButton.titleLabel?.font = UIFont.systemFontOfSize(12.0)
        haveAccountButton.sizeToFit()
        haveAccountButton.frame.origin.x = signInButtonWidth/2 - haveAccountButton.frame.width/2
        haveAccountButton.addTarget(self, action: "haveAccountButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        signInView.addSubview(haveAccountButton)
        
        // Logo
        sprubixLogoView = UIImageView(image: UIImage(named: "logo-final-square.png"))
        
        sprubixLogoView.frame = CGRect(x: screenWidth / 2 - sprubixLogoWidth / 2, y: signInView.frame.origin.y - sprubixLogoWidth, width: sprubixLogoWidth, height: sprubixLogoWidth)
        
        view.addSubview(sprubixLogoView)
        
        oldFrameRect = signInView.frame
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func facebookButtonPressed(sender: UIButton) {
        performSegueWithIdentifier("EmailSegue", sender: sender)
    }
    
    func emailButtonPressed(sender: UIButton) {
        performSegueWithIdentifier("EmailSegue", sender: sender)
    }
    
    func haveAccountButtonPressed(sender: UIButton) {
        performSegueWithIdentifier("EmailSegue", sender: sender)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! SignInViewController
        
        if let senderButton = sender as? FBSDKLoginButton {
            // send to signup from FB, prefill info
            vc.currentCreateAccountState = .Signup
            
            if let facebook_id = self.FBUserData.valueForKey("facebook_id") as? String {
                vc.userSignupData.setValue(facebook_id, forKey: "facebook_id")
            }
            
            if let email = self.FBUserData.valueForKey("email") as? String {
                vc.userSignupData.setValue(email, forKey: "email")
            }
            
            if let firstName = self.FBUserData.valueForKey("first_name") as? String {
                vc.userSignupData.setValue(firstName, forKey: "first_name")
            }
            
            if let lastName = self.FBUserData.valueForKey("last_name") as? String {
                vc.userSignupData.setValue(lastName, forKey: "last_name")
            }
            
            if let gender = self.FBUserData.valueForKey("gender") as? String {
                vc.userSignupData.setValue(gender, forKey: "gender")
            }
        }
        else if let senderButton = sender as? UIButton {
            // send to signup
            if (sender as! UIButton) == emailButton {
                vc.currentCreateAccountState = .Signup
            }
                // send to login
            else {
                vc.currentCreateAccountState = .Login
            }
        }
    }
    
    func getFBUserData(sender: FBSDKLoginButton) {
        let params = [ "fields" : "email, first_name, last_name, gender"]
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: params)
        
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if (error != nil) {
                // Process error
                println("FBSDKGraphRequest Error: \(error)")
            } else {
                println("FBSDKGraphRequest fetched user: \(result)")
                
                let facebook_id = result.valueForKey("id") as! String
                self.FBUserData.setValue(facebook_id, forKey: "facebook_id")
                
                if let email = result.valueForKey("email") as? String {
                    self.FBUserData.setValue(email, forKey: "email")
                }
                
                if let firstName = result.valueForKey("first_name") as? String {
                    self.FBUserData.setValue(firstName, forKey: "first_name")
                }
                
                if let lastName = result.valueForKey("last_name") as? String {
                    self.FBUserData.setValue(lastName, forKey: "last_name")
                }
                
                if let gender = result.valueForKey("gender") as? String {
                    self.FBUserData.setValue(gender, forKey: "gender")
                }
                
                // authenticate with server with facebook
                let delay: NSTimeInterval = 3
                
                manager.POST(SprubixConfig.URL.api + "/auth/login/facebook",
                    parameters: [
                        "facebook_id" : facebook_id
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        var response = responseObject as! NSDictionary
                        var statusCode:String = response["status"] as! String
                        
                        if statusCode == "400" {
                            // error
                            var message = response["message"] as! String
                            var data = response["data"] as! String
                            
                            println(message)
                            println(data)
                            
                            var errorMessage:String = "Something went wrong.\nPlease try again."
                            
                            // error exception
                            TSMessage.showNotificationInViewController(
                                self,
                                title: "Error",
                                subtitle: errorMessage,
                                image: UIImage(named: "filter-cross"),
                                type: TSMessageNotificationType.Error,
                                duration: delay,
                                callback: nil,
                                buttonTitle: nil,
                                buttonCallback: nil,
                                atPosition: TSMessageNotificationPosition.Bottom,
                                canBeDismissedByUser: true)
                            
                        } else if statusCode == "200" {
                            // success
                            var message = response["message"] as! String
                            
                            println(message)
                            
                            // user exist
                            if message == "success" {
                                // return is user object
                                var data = response["data"] as! NSDictionary
                                println(data)
                                
                                var cleanData = self.cleanDictionary(data as! NSMutableDictionary)
                                
                                defaults.setObject(cleanData["id"], forKey: "userId")
                                defaults.setObject(cleanData, forKey: "userData")
                                defaults.synchronize()
                                
                                //self.saveCookies(userId);
                                FirebaseAuth.retrieveFirebaseToken()
                                
                                // Mixpanel - Setup
                                MixpanelService.setup()
                                
                                // redirect to containerViewController (not sprubixFeedController)
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                            // user don't exist, go create
                            else {
                                // return is string
                                var data = response["data"] as! String
                                println(data)
                                
                                // FB account dont exist, go Segue
                                self.performSegueWithIdentifier("EmailSegue", sender: sender)
                            }
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            }
        })
    }
    
    // MARK: Facebook Login Delegate
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        println("FBSDK: User logged in")
        
        if (error != nil) {
            // Process error
            println(error)
        } else if result.isCancelled {
            // Handle cancellations
            println(result)
        } else {
            // If you ask for multiple permissions at once, you should check if specific permissions missing
            println("FBSDK: Permission granted for: \(result.grantedPermissions)")
            
            getFBUserData(loginButton)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        println("FBSDK: User logged out")
    }
    
    func cleanDictionary(dict: NSMutableDictionary)->NSMutableDictionary {
        var mutableDict: NSMutableDictionary = dict.mutableCopy() as! NSMutableDictionary
        mutableDict.enumerateKeysAndObjectsUsingBlock { (key, obj, stop) -> Void in
            if (obj.isKindOfClass(NSNull.classForCoder())) {
                mutableDict.setObject("", forKey: (key as! NSString))
            } else if (obj.isKindOfClass(NSDictionary.classForCoder())) {
                mutableDict.setObject(self.cleanDictionary(obj as! NSMutableDictionary), forKey: (key as! NSString))
            }
        }
        return mutableDict
    }
}


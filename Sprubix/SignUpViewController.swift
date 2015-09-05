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

class SignUpViewController: UIViewController, FBSDKLoginButtonDelegate, UIScrollViewDelegate {
    
    let signInButtonWidth:CGFloat! = screenWidth * 0.8
    let signInButtonHeight:CGFloat! = 50
    let haveAccountButtonHeight:CGFloat! = 20
    let termsHeight: CGFloat! = 20
    
    var signInView:UIView!
    var fbLoginButton: FBSDKLoginButton!
    var emailButton: UIButton!
    var haveAccountButton: UIButton!
    
    let emailIconWidth:CGFloat! = 40
    let sprubixLogoWidth:CGFloat! = 150
    var sprubixLogoView:UIImageView!
    
    var oldFrameRect: CGRect!
    
    var FBUserData: NSMutableDictionary = NSMutableDictionary()
    
    var onboardingImageBackgroundView: UIView!
    var onboardingImageViews: [UIImageView] = [UIImageView]()
    var onboardingTextScrollView: UIScrollView!
    var onboardingPageControl: UIPageControl!
    var onboardingCurrentPage: Int = 0
    
    var termsOfServiceButton: UIButton!
    var privacyPolicyButton: UIButton!
    
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
        
        initOnboardingPages()
        
        // Sign In
        let signInViewHeight: CGFloat! = (signInButtonHeight + 10) * 2 + haveAccountButtonHeight
        let signInViewY: CGFloat! = screenHeight - signInViewHeight - termsHeight - 40
        signInView = UIView(frame: CGRect(x: screenWidth / 2 - signInButtonWidth / 2, y: signInViewY, width: signInButtonWidth, height: signInViewHeight))
        
        view.addSubview(signInView)
        
        // Facebook login button
        fbLoginButton = FBSDKLoginButton(frame: CGRect(x: 0, y: 0, width: signInButtonWidth, height: signInButtonHeight))
        
        fbLoginButton.setTitle("Facebook", forState: UIControlState.Normal)
        fbLoginButton.titleLabel?.font = UIFont.systemFontOfSize(17.0)
        //fbLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.delegate = self
        signInView.addSubview(fbLoginButton)
        
        //view.addSubview(signInView)
        
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
        let haveAccountY = emailButtonY + signInButtonHeight + 6
        haveAccountButton = UIButton(frame: CGRect(x: 0, y: haveAccountY, width: signInButtonWidth, height: haveAccountButtonHeight))
        
        haveAccountButton.setTitle("Already have an account?", forState: UIControlState.Normal)
        haveAccountButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        haveAccountButton.titleLabel?.font = UIFont.systemFontOfSize(14.0)
        haveAccountButton.sizeToFit()
        haveAccountButton.frame.origin.x = signInButtonWidth/2 - haveAccountButton.frame.width/2
        haveAccountButton.addTarget(self, action: "haveAccountButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        signInView.addSubview(haveAccountButton)
        
        // footer
        let footerLine1: String = "By signing up, you agree with Sprubix's"
        let footerLine2Join: String = "and"
        let footerLine2TOS: String = "Terms of Service"
        let footerLine2PP: String = "Privacy Policy"
        let footerFont: UIFont = UIFont.systemFontOfSize(12)
        let footerFontBold: UIFont = UIFont.boldSystemFontOfSize(12)
        
        let footerLine2JoinLabel = UILabel()
        footerLine2JoinLabel.text = footerLine2Join
        footerLine2JoinLabel.font = footerFont
        footerLine2JoinLabel.textColor = sprubixLightGray
        footerLine2JoinLabel.textAlignment = NSTextAlignment.Center
        footerLine2JoinLabel.sizeToFit()
        
        let footerLine2X: CGFloat = screenWidth / 2
        let footerLine2Y: CGFloat = screenHeight - footerLine2JoinLabel.frame.height / 2 - 15
        footerLine2JoinLabel.frame.origin.x = footerLine2X - footerLine2JoinLabel.frame.width / 2
        footerLine2JoinLabel.frame.origin.y = footerLine2Y
        
        view.addSubview(footerLine2JoinLabel)
        
        termsOfServiceButton = UIButton(frame: CGRect(x: 0, y: footerLine2Y, width: screenWidth, height: 10))
        termsOfServiceButton.setTitle(footerLine2TOS, forState: UIControlState.Normal)
        termsOfServiceButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        termsOfServiceButton.setTitleColor(sprubixColor, forState: UIControlState.Highlighted)
        termsOfServiceButton.addTarget(self, action: "clickedTermsOfService:", forControlEvents: UIControlEvents.TouchUpInside)
        termsOfServiceButton.titleLabel?.font = footerFontBold
        termsOfServiceButton.sizeToFit()
        termsOfServiceButton.frame.origin.x = footerLine2JoinLabel.frame.origin.x - termsOfServiceButton.frame.width - 3
        termsOfServiceButton.frame.origin.y = footerLine2Y - 7
        
        view.addSubview(termsOfServiceButton)
        
        privacyPolicyButton = UIButton(frame: CGRect(x: 0, y: footerLine2Y, width: screenWidth, height: 10))
        privacyPolicyButton.setTitle(footerLine2PP, forState: UIControlState.Normal)
        privacyPolicyButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        privacyPolicyButton.setTitleColor(sprubixColor, forState: UIControlState.Highlighted)
        privacyPolicyButton.addTarget(self, action: "clickedPrivacyPolicy:", forControlEvents: UIControlEvents.TouchUpInside)
        privacyPolicyButton.titleLabel?.font = footerFontBold
        privacyPolicyButton.sizeToFit()
        privacyPolicyButton.frame.origin.x = footerLine2JoinLabel.frame.origin.x + footerLine2JoinLabel.frame.width + 3
        privacyPolicyButton.frame.origin.y = footerLine2Y - 7
        
        view.addSubview(privacyPolicyButton)
        
        let footerLine1Label = UILabel()
        footerLine1Label.text = footerLine1
        footerLine1Label.font = footerFont
        footerLine1Label.textColor = sprubixLightGray
        footerLine1Label.textAlignment = NSTextAlignment.Center
        footerLine1Label.sizeToFit()
        
        let footerLine1X: CGFloat = screenWidth / 2 - footerLine1Label.frame.width / 2
        let footerLine1Y: CGFloat = footerLine2Y - 15
        footerLine1Label.frame.origin.x = footerLine1X
        footerLine1Label.frame.origin.y = footerLine1Y
        
        view.addSubview(footerLine1Label)
        
        /*
        // Logo
        sprubixLogoView = UIImageView(image: UIImage(named: "logo-final-square.png"))
        sprubixLogoView.frame = CGRect(x: screenWidth / 2 - sprubixLogoWidth / 2, y: signInView.frame.origin.y - sprubixLogoWidth, width: sprubixLogoWidth, height: sprubixLogoWidth)
        
        view.addSubview(sprubixLogoView)
        */
        
        let onboardingPageControlY: CGFloat = signInViewY - 30
        onboardingPageControl = UIPageControl(frame: CGRect(x: 0, y: onboardingPageControlY, width: screenWidth, height: 10))
        onboardingPageControl.currentPage = 0
        onboardingPageControl.numberOfPages = onboardingImageViews.count
        
        view.addSubview(onboardingPageControl)
        
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
        goSignInPage()
    }
    
    func emailButtonPressed(sender: UIButton) {
        goSignInPage()
    }
    
    func haveAccountButtonPressed(sender: UIButton) {
        goSignInPage()
    }
    
    func goSignInPage() {
        let signInViewController = UIStoryboard.signInViewController()
        
        self.navigationController?.pushViewController(signInViewController!, animated: true)
    }
    
    func clickedTermsOfService(sender: UIButton) {
        let webURL: NSURL = NSURL(string: "http://www.sprubix.com/terms-of-service")!
        UIApplication.sharedApplication().openURL(webURL)
    }
    
    func clickedPrivacyPolicy(sender: UIButton) {
        let webURL: NSURL = NSURL(string: "http://www.sprubix.com/privacy-policy")!
        UIApplication.sharedApplication().openURL(webURL)
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
    
    func initOnboardingPages() {
        
        // Images
        onboardingImageBackgroundView = UIView(frame: view.frame)
        
        view.addSubview(onboardingImageBackgroundView)
        
        let welcomeImage: UIImageView = UIImageView(image: UIImage(named: "onboarding-welcome"))
        let discoverImage: UIImageView = UIImageView(image: UIImage(named: "onboarding-discover"))
        let shareImage: UIImageView = UIImageView(image: UIImage(named: "onboarding-share"))
        let saveImage: UIImageView = UIImageView(image: UIImage(named: "onboarding-save"))
        let enjoyImage: UIImageView = UIImageView(image: UIImage(named: "onboarding-enjoy"))
        onboardingImageViews = [welcomeImage, discoverImage, shareImage, saveImage, enjoyImage]
        
        for var index = 0 ; index < onboardingImageViews.count ; index++ {
            onboardingImageViews[index].frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            onboardingImageViews[index].contentMode = UIViewContentMode.ScaleAspectFill
            onboardingImageViews[index].alpha = 0
            onboardingImageBackgroundView.addSubview(onboardingImageViews[index])
        }
        
        onboardingImageViews[0].alpha = 1
        
        // Dark overlay
        let blackOverlay = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        blackOverlay.backgroundColor = UIColor.blackColor()
        blackOverlay.layer.opacity = 0.2
        view.addSubview(blackOverlay)
        
        // Text
        onboardingTextScrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        onboardingTextScrollView.contentSize = CGSize(width: screenWidth * 5, height: screenHeight)
        onboardingTextScrollView.showsHorizontalScrollIndicator = false
        onboardingTextScrollView.alwaysBounceHorizontal = true
        onboardingTextScrollView.scrollEnabled = true
        onboardingTextScrollView.pagingEnabled = true
        onboardingTextScrollView.delegate = self
        
        let titleFont: UIFont = UIFont.boldSystemFontOfSize(30)
        let textFont: UIFont = UIFont.systemFontOfSize(20)
        let titleColor: UIColor = UIColor.whiteColor()
        
        let titleY: CGFloat = 80
        let titleHeight: CGFloat = 40
        let textY: CGFloat = 150
        let textHeight: CGFloat = 100
        let titleWidth: CGFloat = screenWidth * 0.9
        
        let welcomeTitle: String = "Welcome to Sprubix"
        let discoverTitle: String = "Discover"
        let shareTitle: String = "Share"
        let saveTitle: String = "Save"
        let enjoyTitle: String = "Enjoy"
        var titles: [String] = [welcomeTitle, discoverTitle, shareTitle, saveTitle, enjoyTitle]
        
        let welcomeText: String = "Never run out of oufit ideas again!"
        let discoverText: String = "Follow people and be inspired.\nExplore new ways to create outfits with items in your closet"
        let shareText: String = "Inspire others!\nExpress you style, by yourself."
        let saveText: String = "Save more then you shop more!\nWho complains about having more clothes?"
        let enjoyText: String = "Create outfits and earn points when people buy from it!"
        var texts: [String] = [welcomeText, discoverText, shareText, saveText, enjoyText]
        
        var titleLabels: [UILabel] = [UILabel]()
        var textLabels: [UILabel] = [UILabel]()
        
        for var index = 0 ; index < titles.count ; index++ {
            let titleLabel = UILabel(frame: CGRect(x: screenWidth * CGFloat(index), y: titleY, width: titleWidth, height: titleHeight))
            titleLabel.text = titles[index]
            titleLabel.font = titleFont
            titleLabel.textColor = titleColor
            titleLabel.textAlignment = NSTextAlignment.Center
            titleLabel.numberOfLines = 0
            titleLabel.sizeToFit()
            titleLabel.frame.origin.x = screenWidth / 2 - titleLabel.frame.width / 2 + screenWidth * CGFloat(index)
            titleLabel.frame.origin.y = titleY
            titleLabels.append(titleLabel)
            
            let textLabel = UILabel(frame: CGRect(x: screenWidth * CGFloat(index), y: textY, width: titleWidth, height: textHeight))
            textLabel.text = texts[index]
            textLabel.font = textFont
            textLabel.textColor = titleColor
            textLabel.textAlignment = NSTextAlignment.Center
            textLabel.numberOfLines = 0
            textLabel.sizeToFit()
            textLabel.frame.origin.x = screenWidth / 2 - textLabel.frame.width / 2 + screenWidth * CGFloat(index)
            textLabel.frame.origin.y = textY
            textLabels.append(textLabel)
            
            onboardingTextScrollView.addSubview(titleLabels[index])
            onboardingTextScrollView.addSubview(textLabels[index])
        }
        
        view.addSubview(onboardingTextScrollView)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let pageWidth = screenWidth
        let offsetX = onboardingTextScrollView.contentOffset.x
        let offset = offsetX / pageWidth
        let page = Int(floor(offset))
        
        if page + 1 < 5 && offsetX > 0 {
            onboardingImageViews[page+1].alpha = offset - CGFloat(page)
        }
        
        onboardingPageControl.currentPage = page
    }
    
}


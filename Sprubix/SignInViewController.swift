//
//  SignUpViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 27/2/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import TSMessages
import FBSDKLoginKit
import MRProgress

enum CreateAccountState {
    case Signup
    case Login
}

class SignInViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var makeKeyboardVisible = true
    
    // loading overlay
    var overlay: MRProgressOverlayView!
    
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    var signUpTable:UITableView!
    var continueButton:UIButton!
    
    var emailCell:UITableViewCell = UITableViewCell()
    var userNameCell:UITableViewCell = UITableViewCell()
    var passwordCell:UITableViewCell = UITableViewCell()
    
    var emailText:UITextField!
    var userNameText:UITextField!
    var passwordText:UITextField!
    var passwordString:String = ""
    
    let toolbarHeight:CGFloat = 50
    var signupToolbarButton: UIButton!
    var loginToolbarButton: UIButton!
    var buttonLine: UIView!
    let footerHeight: CGFloat = 50
    
    var currentCreateAccountState: CreateAccountState = CreateAccountState.Signup
    
    var userSignupData: NSMutableDictionary = NSMutableDictionary()
    
    var termsOfServiceButton: UIButton!
    var privacyPolicyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = sprubixGray
        
        let signUpTableHeight = screenHeight - navigationHeight - toolbarHeight - footerHeight
        signUpTable = UITableView(frame: CGRect(x: 0, y: navigationHeight*2, width: screenWidth, height: signUpTableHeight), style: UITableViewStyle.Grouped)
        
        signUpTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        signUpTable.scrollEnabled = false
        signUpTable.backgroundColor = sprubixGray
        signUpTable.dataSource = self
        signUpTable.delegate = self
        
        view.addSubview(signUpTable)
        
        // continue button
        let continueButtonX = screenWidth / 2 - screenWidth / 2
        let continueButtonY = navigationHeight + toolbarHeight + navigationHeight*4
        continueButton = UIButton(frame: CGRect(x: continueButtonX, y: continueButtonY, width: screenWidth, height: 50))
        
        continueButton.backgroundColor = sprubixColor
        continueButton.setTitle("Sign Up", forState: UIControlState.Normal)
        continueButton.addTarget(self, action: "continueButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(continueButton)
        
        // footer
        let footerLine1: String = "By signing up, you agree with Sprubix's"
        let footerLine2Join: String = "and"
        let footerLine2TOS: String = "Terms of Service"
        let footerLine2PP: String = "Privacy Policy"
        let footerFont: UIFont = UIFont.systemFontOfSize(12)
        
        let footerLine2JoinLabel = UILabel()
        footerLine2JoinLabel.text = footerLine2Join
        footerLine2JoinLabel.font = footerFont
        footerLine2JoinLabel.textColor = UIColor.darkGrayColor()
        footerLine2JoinLabel.textAlignment = NSTextAlignment.Center
        footerLine2JoinLabel.sizeToFit()
        
        let footerLine2X: CGFloat = screenWidth / 2
        let footerLine2Y: CGFloat = screenHeight - footerLine2JoinLabel.frame.height / 2 - 15
        footerLine2JoinLabel.frame.origin.x = footerLine2X - footerLine2JoinLabel.frame.width / 2
        footerLine2JoinLabel.frame.origin.y = footerLine2Y
        
        view.addSubview(footerLine2JoinLabel)
        
        termsOfServiceButton = UIButton(frame: CGRect(x: 0, y: footerLine2Y, width: screenWidth, height: 10))
        termsOfServiceButton.setTitle(footerLine2TOS, forState: UIControlState.Normal)
        termsOfServiceButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        termsOfServiceButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        termsOfServiceButton.addTarget(self, action: "clickedTermsOfService:", forControlEvents: UIControlEvents.TouchUpInside)
        termsOfServiceButton.titleLabel?.font = footerFont
        termsOfServiceButton.sizeToFit()
        termsOfServiceButton.frame.origin.x = footerLine2JoinLabel.frame.origin.x - termsOfServiceButton.frame.width - 3
        termsOfServiceButton.frame.origin.y = footerLine2Y - 7
        
        view.addSubview(termsOfServiceButton)
        
        privacyPolicyButton = UIButton(frame: CGRect(x: 0, y: footerLine2Y, width: screenWidth, height: 10))
        privacyPolicyButton.setTitle(footerLine2PP, forState: UIControlState.Normal)
        privacyPolicyButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        privacyPolicyButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        privacyPolicyButton.addTarget(self, action: "clickedPrivacyPolicy:", forControlEvents: UIControlEvents.TouchUpInside)
        privacyPolicyButton.titleLabel?.font = footerFont
        privacyPolicyButton.sizeToFit()
        privacyPolicyButton.frame.origin.x = footerLine2JoinLabel.frame.origin.x + footerLine2JoinLabel.frame.width + 3
        privacyPolicyButton.frame.origin.y = footerLine2Y - 7
        
        view.addSubview(privacyPolicyButton)
        
        let footerLine1Label = UILabel()
        footerLine1Label.text = footerLine1
        footerLine1Label.font = footerFont
        footerLine1Label.textColor = UIColor.darkGrayColor()
        footerLine1Label.textAlignment = NSTextAlignment.Center
        footerLine1Label.sizeToFit()
        
        let footerLine1X: CGFloat = screenWidth / 2 - footerLine1Label.frame.width / 2
        let footerLine1Y: CGFloat = footerLine2Y - 15
        footerLine1Label.frame.origin.x = footerLine1X
        footerLine1Label.frame.origin.y = footerLine1Y
        
        view.addSubview(footerLine1Label)
        
        // Toolbar layout
        initLayout()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        self.navigationController?.interactivePopGestureRecognizer.delegate = self;
        
        // Set seletected initial tab
        if currentCreateAccountState == CreateAccountState.Signup {
            signupToolbarButton.addSubview(buttonLine)
            signupToolbarButton.tintColor = sprubixColor
            signupToolbarButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            
            // if enter from FB login
            if userSignupData.count > 0 {
                continueButton.setTitle("Continue", forState: UIControlState.Normal)
            }
        }
        else {
            loginToolbarButton.addSubview(buttonLine)
            loginToolbarButton.tintColor = sprubixColor
            loginToolbarButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        
        // Mixpanel - Viewed Signup Page
        MixpanelService.track("Viewed Signup Page")
        // Mixpanel - End
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            FBSDKLoginManager().logOut()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Create an Account"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initLayout() {
        // create toolbar
        var toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: toolbarHeight))
        toolbar.clipsToBounds = true
        toolbar.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        
        // toolbar items
        var buttonWidth = screenWidth / 2
        
        signupToolbarButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        signupToolbarButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: toolbarHeight)
        signupToolbarButton.backgroundColor = UIColor.whiteColor()
        signupToolbarButton.setTitle("Sign up", forState: UIControlState.Normal)
        signupToolbarButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        signupToolbarButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        signupToolbarButton.tintColor = UIColor.lightGrayColor()
        signupToolbarButton.autoresizesSubviews = true
        signupToolbarButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        signupToolbarButton.exclusiveTouch = true
        signupToolbarButton.addTarget(self, action: "signupPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        loginToolbarButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        loginToolbarButton.frame = CGRect(x: buttonWidth, y: 0, width: buttonWidth, height: toolbarHeight)
        loginToolbarButton.backgroundColor = UIColor.whiteColor()
        loginToolbarButton.setTitle("Log in", forState: UIControlState.Normal)
        loginToolbarButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        loginToolbarButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        loginToolbarButton.tintColor = UIColor.lightGrayColor()
        loginToolbarButton.autoresizesSubviews = true
        loginToolbarButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        loginToolbarButton.exclusiveTouch = true
        loginToolbarButton.addTarget(self, action: "loginPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        toolbar.addSubview(signupToolbarButton)
        toolbar.addSubview(loginToolbarButton)
        
        // if not entering from FB login, show toolbar. Else hide it to prevent navigation
        if userSignupData.count == 0 {
            self.view.addSubview(toolbar)
        }
        
        // set when button is selected
        buttonLine = UIView(frame: CGRect(x: 0, y: signupToolbarButton.frame.height - 2.0, width: signupToolbarButton.frame.width, height: 2))
        buttonLine.backgroundColor = sprubixColor
    }
    
    func signupPressed(sender: UIButton) {
        currentCreateAccountState = CreateAccountState.Signup
        deselectAllButtons()

        sender.addSubview(buttonLine)
        sender.tintColor = sprubixColor
        
        newNavItem.title = "Create an Account"
        continueButton.setTitle("Sign Up", forState: UIControlState.Normal)
        
        resetForm()
        signUpTable.reloadData()
    }
    
    func loginPressed(sender: UIButton) {
        currentCreateAccountState = CreateAccountState.Login
        deselectAllButtons()
        
        sender.addSubview(buttonLine)
        sender.tintColor = sprubixColor
        
        newNavItem.title = "Sign in with Email"
        continueButton.setTitle("Log In", forState: UIControlState.Normal)
        
        resetForm()
        signUpTable.reloadData()
    }
    
    func continueButtonPressed(sender: UIButton) {
        if currentCreateAccountState == CreateAccountState.Signup {
            registerSprubix()
        } else {
            signInSprubix()
        }
    }
    
    private func deselectAllButtons() {
        buttonLine.removeFromSuperview()
        
        signupToolbarButton.tintColor = UIColor.lightGrayColor()
        loginToolbarButton.tintColor = UIColor.lightGrayColor()
    }
    
    private func resetForm() {
        if emailText != nil && emailText.superview != nil {
            emailText.removeFromSuperview()
        }
        
        if userNameText != nil && userNameText.superview != nil {
            userNameText.removeFromSuperview()
        }
        
        if passwordText != nil && passwordText.superview != nil {
            passwordText.removeFromSuperview()
        }
    }
    
    func clickedTermsOfService(sender: UIButton) {
        let webURL: NSURL = NSURL(string: "http://www.sprubix.com/terms-of-service")!
        UIApplication.sharedApplication().openURL(webURL)
    }
    
    func clickedPrivacyPolicy(sender: UIButton) {
        let webURL: NSURL = NSURL(string: "http://www.sprubix.com/privacy-policy")!
        UIApplication.sharedApplication().openURL(webURL)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // show login
        if currentCreateAccountState == CreateAccountState.Login {
            
            switch indexPath.row {
            case 0:
                userNameText = UITextField(frame: CGRectInset(userNameCell.contentView.bounds, 15, 0))
                
                userNameText.returnKeyType = UIReturnKeyType.Next
                userNameText.placeholder = "Username or Email"
                userNameText.delegate = self
                userNameText.text = "cameron"
                userNameCell.addSubview(userNameText)
                
                return userNameCell
            case 1:
                passwordText = UITextField(frame: CGRectInset(passwordCell.contentView.bounds, 15, 0))
                
                passwordText.secureTextEntry = true
                passwordText.returnKeyType = UIReturnKeyType.Done
                
                passwordText.delegate = self
                passwordText.placeholder = "Password"
                passwordText.text = "password"
                passwordCell.addSubview(passwordText)
                
                return passwordCell
            default:
                fatalError("Unknown row returned")
            }
            
        }
        // show signup
        else {
            switch indexPath.row {
            case 0:
                emailText = UITextField(frame: CGRectInset(emailCell.contentView.bounds, 15, 0))
                
                emailText.returnKeyType = UIReturnKeyType.Next
                emailText.keyboardType = UIKeyboardType.EmailAddress
                
                emailText.placeholder = "Email"
                emailText.delegate = self
                emailCell.addSubview(emailText)
                
                // if enter from FB login
                if userSignupData.count > 0 {
                    if let email = userSignupData.valueForKey("email") as? String {
                        emailText.text = email
                    }
                }
                
                return emailCell
            case 1:
                userNameText = UITextField(frame: CGRectInset(userNameCell.contentView.bounds, 15, 0))
                
                userNameText.returnKeyType = UIReturnKeyType.Next
                userNameText.placeholder = "Username"
                userNameText.delegate = self
                userNameCell.addSubview(userNameText)
                
                // if enter from FB login (don't set, its not intuitive from user POV at registration)
                /*
                if userSignupData.count > 0 {
                    if let firstName = userSignupData.valueForKey("first_name") as? String {
                        userNameText.text = firstName.lowercaseString
                    }
                }*/
                
                return userNameCell
            case 2:
                passwordText = UITextField(frame: CGRectInset(passwordCell.contentView.bounds, 15, 0))
                
                passwordText.secureTextEntry = true
                passwordText.returnKeyType = UIReturnKeyType.Done
                
                passwordText.delegate = self
                passwordText.placeholder = "Password"
                
                passwordCell.addSubview(passwordText)
                
                return passwordCell
            default:
                fatalError("Unknown row returned")
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentCreateAccountState == CreateAccountState.Signup {
            // if enter from FB login
            if userSignupData.count > 0 {
                // 2 rows for fb signup: email, username
                return 2
            }
            
            // 3 rows for email signup: email, username, password
            return 3
        }
        // 2 rows for signin: username, password
        return 2
    }
    
    /**
    * Called when the user click on the view (outside the UITextField).
    */
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    /**
    * Called when 'return' key pressed. return NO to ignore.
    */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if emailText != nil && textField == emailText {
            userNameText.becomeFirstResponder()
            
        } else if textField == userNameText && passwordText != nil {
            passwordText.becomeFirstResponder()
            
        } else {
            if currentCreateAccountState == CreateAccountState.Signup {
                registerSprubix()
                
            } else {
                signInSprubix()
            }
            
        }
        
        return true
    }
    
    func registerSprubix() {
        // Hide keyboard
        self.view.endEditing(true)
        
        let validateResult = self.validateInputs()
        let delay: NSTimeInterval = 3
        
        if validateResult.valid {
            // if enter from FB login, generate random string
            if userSignupData.count > 0 {
                passwordString = RandomString.generate(10)
            }
            else {
                passwordString = passwordText.text
            }
            
            // If register from Facebook, we may have these
            var facebook_id: String = ""
            var first_name: String = ""
            var last_name: String = ""
            var gender: String = ""
            
            if let fid = userSignupData.valueForKey("facebook_id") as? String {
                facebook_id = fid
            }
            
            if let firstName = userSignupData.valueForKey("first_name") as? String {
                first_name = firstName
            }
            
            if let lastName = userSignupData.valueForKey("last_name") as? String {
                last_name = lastName
            }
            
            if let genderTemp = userSignupData.valueForKey("gender") as? String {
                gender = genderTemp
            }
            
            // init overlay
            self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Signing up...", mode: MRProgressOverlayViewMode.Indeterminate, animated: true)
            
            self.overlay.tintColor = sprubixColor
            
            manager.POST(SprubixConfig.URL.api + "/auth/register",
                parameters: [
                    "username" : userNameText.text.lowercaseString,
                    "email" : emailText.text.lowercaseString,
                    "password" : passwordString,
                    "password_confirmation" : passwordString,
                    "facebook_id" : facebook_id,
                    "first_name" : first_name,
                    "last_name" : last_name,
                    "gender" : gender,
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    var response = responseObject as! NSDictionary
                    var statusCode:String = response["status"] as! String
                    
                    self.overlay.dismiss(true)
                    
                    if statusCode == "400" {
                        // error
                        var message = response["message"] as! String
                        var data = response["data"] as! NSDictionary
                        
                        println(message)
                        println(data)
                        
                        var errorMessage:String = ""
                        
                        if data.count > 0 {
                            for (key, value) in data {
                                errorMessage += (value as! [String])[0] + "\n"
                            }
                            
                        } else {
                            errorMessage = "Something went wrong.\nPlease try again."
                        }
                        
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
                        if self.passwordText != nil {
                            self.passwordText.resignFirstResponder()
                        }
                        var message = response["message"] as! String
                        var data = response["data"] as! NSDictionary
                        println(message)
                        println(data)
                        
                        // login
                        self.signInSprubix()
                        
                        // Mixpanel - Signed Up, Success
                        mixpanel.track("User Signed Up", properties: [
                            "User ID": data.objectForKey("id") as! Int,
                            "Status": "Success"
                        ])
                        // Mixpanel - Register
                        MixpanelService.register(data)
                        // Mixpanel - End
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    self.overlay.dismiss(true)
                    
                    // error exception
                    TSMessage.showNotificationInViewController(
                        self,
                        title: "Error",
                        subtitle: "Something went wrong.\nPlease try again.",
                        image: UIImage(named: "filter-cross"),
                        type: TSMessageNotificationType.Error,
                        duration: delay,
                        callback: nil,
                        buttonTitle: nil,
                        buttonCallback: nil,
                        atPosition: TSMessageNotificationPosition.Bottom,
                        canBeDismissedByUser: true)
                    
                    // Mixpanel - Signed Up, Fail
                    MixpanelService.track("User Signed Up", propertySet: ["Status" : "Fail"])
                    // Mixpanel - End
            })
            
        } else {
            // Validation failed
            TSMessage.showNotificationInViewController(
                self,
                title: "Error",
                subtitle: validateResult.message,
                image: UIImage(named: "filter-cross"),
                type: TSMessageNotificationType.Error,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
        }
    }
    
    func signInSprubix() {
        
        // Hide keyboard
        self.view.endEditing(true)
        
        let validateResult = self.validateInputs()
        let delay: NSTimeInterval = 3
        
        if validateResult.valid {
            var usernameString = ""
            var emailString = ""
            
            let userNameText = self.userNameText.text
            passwordString = self.passwordText.text
            
            // check if username or email was entered
            if userNameText.rangeOfString("@") != nil{
                emailString = userNameText
            } else {
                usernameString = userNameText
            }
            
            // init overlay
            self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Logging in...", mode: MRProgressOverlayViewMode.Indeterminate, animated: true)
            
            self.overlay.tintColor = sprubixColor
            
            // authenticate with server
            manager.POST(SprubixConfig.URL.api + "/auth/login",
                parameters: [
                    "username" : usernameString.lowercaseString,
                    "email" : emailString.lowercaseString,
                    "password" : passwordString
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    var response = responseObject as! NSDictionary
                    var statusCode:String = response["status"] as! String
                    
                    self.overlay.dismiss(true)
                    
                    if statusCode == "400" {
                        // error
                        var message = response["message"] as! String
                        var data = response["data"] as! String
                        
                        println(message)
                        println(data)
                        
                        // Validation failed
                        TSMessage.showNotificationInViewController(
                            self,
                            title: "Error",
                            subtitle: "Your username or password was incorrect",
                            image: UIImage(named: "filter-cross"),
                            type: TSMessageNotificationType.Error,
                            duration: 3,
                            callback: nil,
                            buttonTitle: nil,
                            buttonCallback: nil,
                            atPosition: TSMessageNotificationPosition.Bottom,
                            canBeDismissedByUser: true)
                        
                    } else if statusCode == "200" {
                        // success
                        self.view.endEditing(true)
                        var message = response["message"] as! String
                        var data = response["data"] as! NSDictionary
                        
                        println(message)
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
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)

                    self.overlay.dismiss(true)
            })
        
        } else {
            // Validation failed
            TSMessage.showNotificationInViewController(
                self,
                title: "Error",
                subtitle: validateResult.message,
                image: UIImage(named: "filter-cross"),
                type: TSMessageNotificationType.Error,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
        }
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
    
    func saveCookies(userId: Int) {
        // persisting cookies
        var cookies:NSData = NSKeyedArchiver.archivedDataWithRootObject(NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!)
        
        //defaults.setObject(cookies, forKey: "sessionCookies")
        defaults.setObject(userId, forKey: "userId")
        defaults.synchronize()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    /**
    * Returns true if all user inputs are correctly entered
    */
    func validateInputs() -> (valid: Bool, message: String) {
        var valid: Bool = true
        var message: String = ""
        
        if currentCreateAccountState == CreateAccountState.Signup && emailText != nil && emailText.text == "" {
            message += "Please enter an email\n"
            valid = false
        }
        else if currentCreateAccountState == CreateAccountState.Signup && emailText != nil && !self.isValidEmail(emailText.text) {
            message += "Please enter a valid email\n"
            valid = false
        }
        
        if userNameText.text == "" {
            message += "Please enter a username\n"
            valid = false
        }
        else if currentCreateAccountState == CreateAccountState.Signup && !self.isValidUsername(userNameText.text) {
            message += "Only alphabets, numbers, underscores and periods are allowed (max 30 characters)\n"
            valid = false
        }
        
        if passwordText != nil && passwordText.text == "" {
            message += "Please enter a password\n"
            valid = false
        }
        else if currentCreateAccountState == CreateAccountState.Signup && passwordText != nil && count(passwordText.text) < 6 {
            message += "The password must be at least 6 characters\n"
            valid = false
        }
        else if currentCreateAccountState == CreateAccountState.Signup && passwordText != nil && count(passwordText.text) > 30 {
            message += "The password must be under 30 characters\n"
            valid = false
        }
        
        if valid {
            println("Validation OK")
        }
        
        return (valid, message)
    }
    
    /**
    * To see if an email is valid
    */
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        if emailTest.evaluateWithObject(testStr) {
            return true
        }
        
        return false
    }
    
    func isValidUsername(testStr:String) -> Bool {
        let usernameRegEx = "^[A-Z0-9a-z._]{1,30}$"
        
        let usernameTest = NSPredicate(format:"SELF MATCHES %@", usernameRegEx)
        
        if usernameTest.evaluateWithObject(testStr) {
            return true
        }
        
        return false
    }
}

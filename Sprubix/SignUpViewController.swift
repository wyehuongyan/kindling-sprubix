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

protocol SignInDelegate {
    func signInSprubix(userNameText: String, passwordText: String)
}

class SignUpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {
    var signUpTable:UITableView!
    
    var emailCell:UITableViewCell = UITableViewCell()
    var userNameCell:UITableViewCell = UITableViewCell()
    var passwordCell:UITableViewCell = UITableViewCell()
    
    var emailText:UITextField!
    var userNameText:UITextField!
    var passwordText:UITextField!
    
    var delegate:SignInDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.backgroundColor = sprubixGray
        
        signUpTable = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Grouped)
        
        signUpTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        signUpTable.scrollEnabled = false
        signUpTable.backgroundColor = sprubixGray
        signUpTable.dataSource = self
        signUpTable.delegate = self
        
        view.addSubview(signUpTable)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        var newNavBar:UINavigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        var newNavItem:UINavigationItem = UINavigationItem()
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
        
        self.navigationController?.interactivePopGestureRecognizer.delegate = self;
        
        // Mixpanel - App Launched
        var currentUserId = -1  // New user (or not logged in)
        
        if let localUserId = NSUserDefaults.standardUserDefaults().objectForKey("userId") as? Int {
            currentUserId = localUserId
        }
        
        mixpanel.track("Viewed Signup Page", properties: [
            "User ID": currentUserId,
            "Timestamp": NSDate()
        ])
        // Mixpanel - End
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            emailText = UITextField(frame: CGRectInset(emailCell.contentView.bounds, 15, 0))
            
            emailText.returnKeyType = UIReturnKeyType.Next
            emailText.keyboardType = UIKeyboardType.EmailAddress
            
            emailText.placeholder = "Email"
            emailText.delegate = self
            emailCell.addSubview(emailText)
            
            return emailCell
        case 1:
            userNameText = UITextField(frame: CGRectInset(userNameCell.contentView.bounds, 15, 0))
            
            userNameText.returnKeyType = UIReturnKeyType.Next
            userNameText.placeholder = "Username"
            userNameText.delegate = self
            userNameCell.addSubview(userNameText)
            
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
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
        
        if textField == emailText {
            userNameText.becomeFirstResponder()
            
            if textField.text != "" && !self.isValidEmail(textField.text) {
                println("Please enter valid email")
            }
            
        } else if textField == userNameText {
            passwordText.becomeFirstResponder()
            
        } else {
            
            // Hide keyboard
            self.view.endEditing(true)
            
            let validateResult = self.validateInputs()
            let delay: NSTimeInterval = 3
            
            if validateResult.valid {
                
                let signupTime: NSDate = NSDate()
                
                manager.POST(SprubixConfig.URL.api + "/auth/register",
                    parameters: [
                        "username" : userNameText.text.lowercaseString,
                        "email" : emailText.text.lowercaseString,
                        "password" : passwordText.text,
                        "password_confirmation" : passwordText.text
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        var response = responseObject as! NSDictionary
                        var statusCode:String = response["status"] as! String
                        
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
                            textField.resignFirstResponder()
                            var message = response["message"] as! String
                            var data = response["data"] as! NSDictionary
                            println(message)
                            println(data)
                            
                            // Change AFNetworking to Html
                            manager.requestSerializer = AFHTTPRequestSerializer()
                            
                            // SignInDelegate, get SignInVC to do the login
                            self.delegate?.signInSprubix(self.userNameText.text.lowercaseString, passwordText: self.passwordText.text.lowercaseString)
                            
                            // Mixpanel - Signed Up, Success
                            mixpanel.track("User Signed Up", properties: [
                                "User ID": data.objectForKey("id") as! Int,
                                "Status": "Success",
                                "Timestamp": signupTime
                            ])
                            
                            mixpanel.createAlias(data.objectForKey("email") as! String, forDistinctID: mixpanel.distinctId)
                            mixpanel.identify(data.objectForKey("email") as! String)
                            
                            mixpanel.people.set([
                                "$email": data.objectForKey("email") as! String,
                                "ID": data.objectForKey("id") as! Int,
                                "Username": data.objectForKey("username") as! String,
                                "$first_name": data.objectForKey("username") as! String,
                                "$last_name": "",
                                "$created": signupTime,
                                "Exposed Outfits": 0,
                                "Liked Outfits": 0,
                                "Liked Pieces": 0,
                                "Outfits Created": 0,
                                "Spruce Outfit": 0,
                                "Spruce Outfit Swipe": 0,
                                "Viewed Outfit Details": 0,
                                "Viewed Piece Details": 0,
                                "Viewed Outfit Comments": 0,
                                "Viewed Piece Comments": 0
                            ])
                            // Mixpanel - End
                            
                            // Mandrill - Add subaccount
                            var dateFormatter: NSDateFormatter = NSDateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            let signupTimeStr = dateFormatter.stringFromDate(signupTime)
                            
                            manager.requestSerializer = AFJSONRequestSerializer()
                            
                            manager.POST(SprubixConfig.URL.mandrill + "/subaccounts/add",
                                parameters: [
                                    "key" : SprubixConfig.Token.mandrill,
                                    "id" : data.objectForKey("id") as! Int,
                                    "name" : data.objectForKey("username") as! String,
                                    "notes" : "Signed up on " + signupTimeStr,
                                ],
                                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                                    var data = responseObject as! NSDictionary
                                    
                                    // Print reply from server
                                    println(data)
                                    
                                },
                                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                                    println("Error: " + error.localizedDescription)
                                    
                            })
                            
                            // Change AFNetworking to Html
                            manager.requestSerializer = AFHTTPRequestSerializer()
                            // Mandrill - End
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
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
                        var currentUserId = -1  // New user (or not logged in)
                        
                        if let localUserId = NSUserDefaults.standardUserDefaults().objectForKey("userId") as? Int {
                            currentUserId = localUserId
                        }
                        
                        mixpanel.track("User Signed Up", properties: [
                            "User ID": currentUserId,
                            "Status": "Fail",
                            "Timestamp": signupTime
                        ])
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
        
        return true
    }
    
    /**
    * Returns true if all user inputs are correctly entered
    */
    func validateInputs() -> (valid: Bool, message: String) {
        var valid: Bool = true
        var message: String = ""
        
        if emailText.text == "" {
            message += "Please enter an email\n"
            valid = false
        }
        else if !self.isValidEmail(emailText.text) {
            message += "Please enter a valid email\n"
            valid = false
        }
        
        if userNameText.text == "" {
            message += "Please enter a username\n"
            valid = false
        }
        else if !self.isValidUsername(userNameText.text) {
            message += "Only alphabets, numbers, underscores and periods are allowed (max 30 characters)\n"
            valid = false
        }
        
        if passwordText.text == "" {
            message += "Please enter a password\n"
            valid = false
        }
        else if count(passwordText.text) < 6 {
            message += "The password must be at least 6 characters\n"
            valid = false
        }
        else if count(passwordText.text) > 30 {
            message += "The password must be under 30 characters\n"
            valid = false
        }
        
        if valid {
            println("Validation OK")
        }
        
        return (valid, message)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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

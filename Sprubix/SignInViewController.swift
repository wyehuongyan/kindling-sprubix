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

class SignInViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, SignInDelegate {
    
    var makeKeyboardVisible = true
    
    let signInTableHeight:CGFloat! = 100
    let signInTableWidth:CGFloat! = screenWidth * 0.9
    let signInButtonHeight:CGFloat! = 50
    
    var signInTable:UITableView!
    var userNameCell:UITableViewCell = UITableViewCell()
    var passwordCell:UITableViewCell = UITableViewCell()
    
    var userNameText:UITextField!
    var passwordText:UITextField!
    
    var signInButton:UIButton!
    var signInView:UIView!
    
    let sprubixLogoWidth:CGFloat! = 150
    var sprubixLogoView:UIImageView!
    
    var oldFrameRect: CGRect!
    
    var delegate:SignInDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        signInView = UIView(frame: CGRect(x: screenWidth / 2 - signInTableWidth / 2, y: screenHeight / 2 - signInTableHeight / 2, width: signInTableWidth, height: signInTableHeight + signInButtonHeight))
        
        signInTable = UITableView(frame: CGRect(x: 0, y: 0, width: signInTableWidth , height: signInTableHeight), style: UITableViewStyle.Plain)
        
        signInTable.separatorStyle = UITableViewCellSeparatorStyle.None
        signInTable.scrollEnabled = false
        signInTable.dataSource = self
        signInTable.delegate = self
        
        signInView.addSubview(signInTable)
        
        signInButton = UIButton(frame: CGRect(x: 0, y: signInTableHeight, width: signInTableWidth, height: 50))
        
        signInButton.backgroundColor = sprubixColor
        signInButton.setTitle("Log in", forState: UIControlState.Normal)
        signInButton.addTarget(self, action: "signInButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        signInView.addSubview(signInButton)
        
        view.addSubview(signInView)
        
        sprubixLogoView = UIImageView(image: UIImage(named: "logo-final-square.png"))
        
        sprubixLogoView.frame = CGRect(x: screenWidth / 2 - sprubixLogoWidth / 2, y: signInView.frame.origin.y - sprubixLogoWidth, width: sprubixLogoWidth, height: sprubixLogoWidth)
        
        view.addSubview(sprubixLogoView)
        
        oldFrameRect = signInView.frame
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            userNameText = UITextField(frame: CGRectInset(userNameCell.contentView.bounds, 15, 0))
            
            userNameText.tintColor = sprubixColor
            userNameText.placeholder = "Username or email"
            userNameText.text = "cameron" // tentative default for ease of use
            userNameCell.addSubview(userNameText)
            
            return userNameCell
        case 1:
            passwordText = UITextField(frame: CGRectInset(passwordCell.contentView.bounds, 15, 0))
            
            passwordText.tintColor = sprubixColor
            passwordText.secureTextEntry = true
            passwordText.placeholder = "Password"
            passwordText.text = "password" // tentative default for ease of use
            passwordCell.addSubview(passwordText)
            
            return passwordCell
        default:
            fatalError("Unknown row returned")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = true
        
        // keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil);
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func validateUserInfo(userNameText: String, passwordText: String) -> Bool {
        var errorMessage: String = "Please fill up the required field(s):\n"
        var noError = true
        
        if userNameText == "" {
            errorMessage += "\nUser Name"
            
            noError = false
        }
        
        if passwordText == "" {
            errorMessage += "\nPassword"
            
            noError = false
        }
        
        // pop up an alert view if there's an error
        if noError == false {
            let alert = UIAlertController(title: "Oops!", message: errorMessage, preferredStyle: UIAlertControllerStyle.Alert)
            alert.view.tintColor = sprubixColor
            
            // Ok
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        return noError
    }
    
    func signInButtonPressed(sender: UIButton) {
        signInSprubix(self.userNameText.text, passwordText: self.passwordText.text)
    }
    
    func signInSprubix(userNameText: String, passwordText: String) {
        
        // Hide keyboard
        self.view.endEditing(true)
        
        if validateUserInfo(userNameText, passwordText: passwordText) {
            var usernameString = ""
            var emailString = ""
            
            // check if username or email was entered
            if userNameText.rangeOfString("@") != nil{
                emailString = userNameText
            } else {
                usernameString = userNameText
            }
            
            // authenticate with server
            manager.POST(SprubixConfig.URL.api + "/auth/login",
                parameters: [
                    "username" : usernameString.lowercaseString,
                    "email" : emailString.lowercaseString,
                    "password" : passwordText
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
            })
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
    
    /**
    * Handler for keyboard change event
    */
    func keyboardWillChange(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        if makeKeyboardVisible {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.signInView.frame.origin.y = self.oldFrameRect.origin.y - 0.2 * keyboardFrame.height
                self.sprubixLogoView.frame.origin.y = self.signInView.frame.origin.y - self.sprubixLogoWidth
                
                }, completion: { finished in
                    if finished {
                    }
            })
        } else {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.signInView.frame.origin.y = self.oldFrameRect.origin.y
                self.sprubixLogoView.frame.origin.y = self.signInView.frame.origin.y - self.sprubixLogoWidth
                
                }, completion: { finished in
                    if finished {
                        self.makeKeyboardVisible = true
                    }
            })
        }
    }
    
    /**
    * Called when 'return' key pressed. return NO to ignore.
    */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        makeKeyboardVisible = false
        
        textField.resignFirstResponder()

        return true
    }
    
    /**
    * Called when the user click on the view (outside the UITextField).
    */
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! SignUpViewController
        vc.delegate = self
    }
}


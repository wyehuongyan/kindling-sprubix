//
//  ViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 26/2/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CoreData

class SignInViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil);
        
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
        signInButton.addTarget(self, action: "signIn:", forControlEvents: UIControlEvents.TouchUpInside)
        
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
            userNameText.text = "jasmine" // tentative default for ease of use
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
        self.navigationController?.navigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func signIn(sender: AnyObject) {
        if self.userNameText.text == "" {
            println("Please enter username or email")
        } else if self.passwordText.text == "" {
            println("Please enter password")
        } else {
            var usernameString = ""
            var emailString = ""
            
            // check if username or email was entered
            if userNameText.text.rangeOfString("@") != nil{
                emailString = userNameText.text
            } else {
                usernameString = userNameText.text
            }
            
            // authenticate with server
            manager.POST(SprubixConfig.URL.api + "/auth/login",
                parameters: [
                    "username" : usernameString,
                    "email" : emailString,
                    "password" : passwordText.text
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
                        
                    } else if statusCode == "200" {
                        // success
                        self.view.endEditing(true)
                        var message = response["message"] as! String
                        var data = response["data"] as! NSDictionary
                        
                        println(message)
                        println(data)
                        
                        defaults.setObject(data["id"], forKey: "userId")
                        defaults.setObject(data, forKey: "userData")
                        defaults.synchronize()
                        
                        //self.saveCookies(userId);
                        self.retrieveFirebaseToken()
                        
                        // redirect to containerViewController (not sprubixFeedController)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
            
        }
    }
    
    func saveCookies(userId: Int) {
        // persisting cookies
        
        var cookies:NSData = NSKeyedArchiver.archivedDataWithRootObject(NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!)
        
        //defaults.setObject(cookies, forKey: "sessionCookies")
        defaults.setObject(userId, forKey: "userId")
        defaults.synchronize()
        
    }
    
    // Firebase
    func retrieveFirebaseToken() {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            let username = userData!["username"] as! String
            let firebaseToken: String? = SSKeychain.passwordForService("firebase", account: username)
            
            if firebaseToken != nil {
                authenticateFirebase()
            } else {
                manager.GET(SprubixConfig.URL.api + "/auth/firebase/token",
                    parameters: nil,
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        var data = responseObject as! NSDictionary
                        let token = data["token"] as! String
                        
                        SSKeychain.setPassword(token, forService: "firebase", account: username)
                        
                        //println(SSKeychain.passwordForService("firebase", account: username))
                        
                        self.authenticateFirebase()
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            }
            
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    func authenticateFirebase() {
        // handle token expiration gracefully
        let handle = firebaseRef.observeAuthEventWithBlock { authData in
            if authData != nil {
                // user authenticated with Firebase
                println("User already authenticated with Firebase! \(authData)")
            } else {
                let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                
                // user is logged in
                if userData != nil {
                    let username = userData!["username"] as! String
                    let firebaseToken: String? = SSKeychain.passwordForService("firebase", account: username)
                    
                    // auth with firebase
                    firebaseRef.authWithCustomToken(firebaseToken, withCompletionBlock: { error, authData in
                        if error != nil {
                            println("Firebase Login failed! \(error)")
                        } else {
                            println("Firebase Login succeeded! \(authData)")
                            
                            // check if firebase has user data, if not, write it to firebase
                            var userRef = firebaseRef.childByAppendingPath("users/\(username)")
                            
                            userRef.observeSingleEventOfType(.Value, withBlock: {
                                snapshot in
                                
                                var result = ((snapshot.value as? NSNull) != nil) ? "is not" : "is"
                                println("\(username.capitalizeFirst) \(result) an entry in Users firebase.")
                                
                                if (snapshot.value as? NSNull) != nil {
                                    // does not exist, add it
                                    var userInfo = ["username": userData!["username"] as! String,
                                        "id": userData!["id"] as! Int,
                                        "image": userData!["image"] as! String]
                                    
                                    userRef.setValue(userInfo)
                                    println("userInfo added to firebase")
                                }
                            })
                        }
                    })
                    
                } else {
                    println("userData not found, please login or create an account")
                }
            }
        }
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
}


//
//  SignUpViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 27/2/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class SignUpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {
    var signUpTable:UITableView!
    
    var emailCell:UITableViewCell = UITableViewCell()
    var userNameCell:UITableViewCell = UITableViewCell()
    var passwordCell:UITableViewCell = UITableViewCell()
    
    var emailText:UITextField!
    var userNameText:UITextField!
    var passwordText:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        signUpTable = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Grouped)
        
        signUpTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        signUpTable.scrollEnabled = false
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
            if self.validateInputs() {
                
                manager.POST(SprubixConfig.URL.api + "/auth/register",
                    parameters: [
                        "username" : userNameText.text,
                        "email" : emailText.text,
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
                            
                        } else if statusCode == "200" {
                            // success
                            textField.resignFirstResponder()
                            var message = response["message"] as! String
                            var data = response["data"] as! NSDictionary
                            
                            println(message)
                            println(data)
                            println("\noff we go to the land of segue")
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            }
        }
        
        return true
    }
    
    /**
    * Returns true if all user inputs are correctly entered
    */
    func validateInputs() -> Bool {
        var validated = true
        
        if emailText.text == "" {
            validated = false
            
            println("Please enter an email")
            
        } else if !self.isValidEmail(emailText.text) {
            validated = false
            
            println("Please enter valid email")
            
        } else if userNameText.text == "" {
            validated = false
            
            println("Please enter an username")
            
        } else if passwordText.text == "" {
            validated = false
            
            println("Please enter a password")

        } else if count(passwordText.text) < 6 {
            validated = false
            
            println("The password must be at least 6 characters.")
        }
        else {
            println("Validation OK")
        }
        
        return validated
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
}

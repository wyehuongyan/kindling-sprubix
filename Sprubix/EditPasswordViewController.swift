//
//  EditPasswordViewController.swift
//  Sprubix
//
//  Created by Shion Wah on 16/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import TSMessages

class EditPasswordViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var editPasswordTable: UITableView!
    var oldFrameRect: CGRect!
    
    // table view cells
    var currentPasswordCell: UITableViewCell = UITableViewCell()
    var newPasswordCell: UITableViewCell = UITableViewCell()
    var repeatPasswordCell: UITableViewCell = UITableViewCell()
    
    var currentPasswordText: UITextField!
    var newPasswordText: UITextField!
    var repeatPasswordText: UITextField!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var tableTapGestureRecognizer: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = sprubixGray
        
        editPasswordTable = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Grouped)
        
        editPasswordTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        editPasswordTable.backgroundColor = sprubixGray
        editPasswordTable.dataSource = self
        editPasswordTable.delegate = self
        oldFrameRect = editPasswordTable.frame
        
        view.addSubview(editPasswordTable)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Edit Password"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.exclusiveTouch = true
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("save", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "saveTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        // Current Password
        case 0:
            currentPasswordText = UITextField(frame: CGRectInset(currentPasswordCell.contentView.bounds, 15, 0))
            currentPasswordText.secureTextEntry = true
            currentPasswordText.returnKeyType = UIReturnKeyType.Next
            currentPasswordText.placeholder = "Current Password"
            currentPasswordText.delegate = self
            currentPasswordCell.addSubview(currentPasswordText)
            currentPasswordCell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return currentPasswordCell
            
        // New Password
        case 1:
            newPasswordText = UITextField(frame: CGRectInset(newPasswordCell.contentView.bounds, 15, 0))
            newPasswordText.secureTextEntry = true
            newPasswordText.returnKeyType = UIReturnKeyType.Next
            newPasswordText.placeholder = "New Password"
            newPasswordText.delegate = self
            newPasswordCell.addSubview(newPasswordText)
            newPasswordCell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return newPasswordCell
            
        // Repeat Password
        case 2:
            repeatPasswordText = UITextField(frame: CGRectInset(repeatPasswordCell.contentView.bounds, 15, 0))
            repeatPasswordText.secureTextEntry = true
            repeatPasswordText.returnKeyType = UIReturnKeyType.Done
            repeatPasswordText.placeholder = "New Password (again)"
            repeatPasswordText.delegate = self
            repeatPasswordCell.addSubview(repeatPasswordText)
            repeatPasswordCell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return repeatPasswordCell
            
        default:
            fatalError("Unknown row returned")
        }
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func saveTapped(sender: UIBarButtonItem) {
        
        // Hide keyboard
        self.view.endEditing(true)
        
        let validateResult = validateInputs()
        let delay: NSTimeInterval = 2
        let viewDelay: Double = 2.5
        
        if validateResult.valid {
            
            manager.POST(SprubixConfig.URL.api + "/update/password",
                parameters: [
                    "current_password" : currentPasswordText.text,
                    "new_password" : newPasswordText.text,
                    "new_password_confirmation" : repeatPasswordText.text
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    var response = responseObject as! NSDictionary
                    var status = response["status"] as! String
                    var message = response["message"] as! String
                    var data = response["data"] as! NSDictionary
                    
                    if status == "200" {
                        // Password match
                        if message == "success" {
                            // success
                            TSMessage.showNotificationInViewController(
                                TSMessage.defaultViewController(),
                                title: "Success!",
                                subtitle: "Password updated",
                                image: UIImage(named: "filter-check"),
                                type: TSMessageNotificationType.Success,
                                duration: delay,
                                callback: nil,
                                buttonTitle: nil,
                                buttonCallback: nil,
                                atPosition: TSMessageNotificationPosition.Bottom,
                                canBeDismissedByUser: true)
                            
                            Delay.delay(viewDelay) {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                            
                        } else {
                            // Password mismatch
                            // error exception
                            TSMessage.showNotificationInViewController(
                                TSMessage.defaultViewController(),
                                title: "Error",
                                subtitle: "Old password incorrect",
                                image: UIImage(named: "filter-cross"),
                                type: TSMessageNotificationType.Error,
                                duration: delay,
                                callback: nil,
                                buttonTitle: nil,
                                buttonCallback: nil,
                                atPosition: TSMessageNotificationPosition.Bottom,
                                canBeDismissedByUser: true)
                        }
                        
                    } else {
                        // error exception
                        TSMessage.showNotificationInViewController(
                            TSMessage.defaultViewController(),
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
                    }
                    
                    // Print reply from server
                    println(message + " " + status)
                    println(data)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    // error exception
                    TSMessage.showNotificationInViewController(
                        TSMessage.defaultViewController(),
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
            })
            
        } else {
            // error exception
            TSMessage.showNotificationInViewController(
                TSMessage.defaultViewController(),
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
    
    func validateInputs() -> (valid: Bool, message: String) {
        var valid: Bool = true
        var message: String = ""
        
        if currentPasswordText.text == "" {
            message += "Please enter the current password\n"
            valid = false
        }
        
        if newPasswordText.text == "" {
            message += "Please enter a new password\n"
            valid = false
        }
        else if count(newPasswordText.text) < 6 {
            message += "The new password must be at least 6 characters\n"
            valid = false
        }
        else if count(newPasswordText.text) > 30 {
            message += "The new password must be under 30 characters\n"
            valid = false
        }
        
        if repeatPasswordText.text == "" || newPasswordText.text != repeatPasswordText.text {
            message += "The passwords do not match\n"
            valid = false
        }
        
        return (valid, message)
    }
}

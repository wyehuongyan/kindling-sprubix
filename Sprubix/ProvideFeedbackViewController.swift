//
//  ProvideFeedbackViewController.swift
//  Sprubix
//
//  Created by Shion Wah on 17/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import TSMessages

class ProvideFeedbackViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UITextFieldDelegate {

    // email details
    let emailSubject: String = "User Feedback"
    let emailSprubixSupport: String = "support@sprubix.com"
    let emailTag: String = "feedback"
    
    // table view cells
    var emailTable: UITableView!
    
    var titleCell: UITableViewCell = UITableViewCell()
    var contentCell: UITableViewCell = UITableViewCell()
    
    var titleText:UITextField!
    var contentText:UITextView!
    
    let contentTextHeight: CGFloat = screenHeight - navigationHeight - 300
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        emailTable = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Grouped)
        
        emailTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        emailTable.backgroundColor = sprubixGray
        emailTable.dataSource = self
        emailTable.delegate = self
        
        view.addSubview(emailTable)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Provide Feedback"
        
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
        nextButton.setTitle("send", forState: UIControlState.Normal)
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
        return 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return contentTextHeight
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Tell us what you love, or what could improve"
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let headerView: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        headerView.textLabel.text = "Tell us what you love, or what could improve"
        headerView.textLabel.textColor = UIColor.grayColor()
        headerView.textLabel.font = UIFont.systemFontOfSize(16)
        headerView.textLabel.textAlignment = NSTextAlignment.Left
        headerView.textLabel.frame = headerView.frame
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        contentText = UITextView(frame: CGRectInset(CGRect(x: 0, y: 0, width: screenWidth, height: contentTextHeight), 15, 0))
        contentText.tintColor = UIColor.blackColor()
        contentText.font = UIFont.systemFontOfSize(16)
        contentText.delegate = self
        contentCell.addSubview(contentText)
        contentCell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return contentCell
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
            
            let userData: NSDictionary = defaults.dictionaryForKey("userData")!
            
            manager.POST(SprubixConfig.URL.api + "/mail/feedback",
                parameters: [
                    "content" : contentText.text
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    var data = responseObject as! NSDictionary
                    var status = data.objectForKey("status") as! String
                    
                    if status == "200" {
                        // email sent
                        // success
                        TSMessage.showNotificationInViewController(
                            TSMessage.defaultViewController(),
                            title: "Feedback sent!",
                            subtitle: "We'll get back to you in a jiffy",
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
        
        if contentText.text == "" {
            message = "Please enter something\n"
            valid = false
        }
        
        return (valid, message)
    }
}

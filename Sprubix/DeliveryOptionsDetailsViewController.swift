//
//  DeliveryOptionsDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 24/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import TSMessages

class DeliveryOptionsDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var deliveryOption: NSDictionary?
    
    var deliveryOptionTable: UITableView!
    var deliveryNameCell: UITableViewCell = UITableViewCell()
    var deliveryPriceCell: UITableViewCell = UITableViewCell()
    var deliveryEstimatedTimeCell: UITableViewCell = UITableViewCell()
    
    var deliveryNameText: UITextField!
    var deliveryPriceText: UITextField!
    var deliveryEstimatedTimeText: UITextField!
    
    let deliveryNamePlaceholderText = "What is this delivery option called?"
    let deliveryPricePlaceholderText = "How much does it cost?"
    let deliveryEstimatedTimePlaceholderText = "Estimated duration (days)"
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        deliveryOptionTable = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Grouped)
        
        deliveryOptionTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        deliveryOptionTable.scrollEnabled = false
        deliveryOptionTable.backgroundColor = sprubixGray
        deliveryOptionTable.dataSource = self
        deliveryOptionTable.delegate = self
        
        view.addSubview(deliveryOptionTable)
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
        newNavItem.title = deliveryOption != nil ? "Edit Delivery Option" : "Add Delivery Option"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.exclusiveTouch = true
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
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
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var sectionName: String!
        
        switch section
        {
        case 0:
            sectionName = "Details"
        default:
            fatalError("Unknown section in table view.")
        }
        
        return sectionName
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var sectionName: String!
        
        switch section
        {
        case 0:
            sectionName = "i.e. Local non-registered mail, $3.00"
        default:
            fatalError("Unknown section in table view.")
        }
        
        return sectionName
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            deliveryNameText = UITextField(frame: CGRectInset(deliveryNameCell.contentView.bounds, 15, 0))
            
            deliveryNameText.returnKeyType = UIReturnKeyType.Next
            deliveryNameText.placeholder = deliveryNamePlaceholderText
            deliveryNameText.delegate = self
            deliveryNameCell.addSubview(deliveryNameText)
            
            if deliveryOption != nil {
                deliveryNameText.text = deliveryOption!["name"] as! String
            }
            
            return deliveryNameCell
        case 1:
            deliveryPriceText = UITextField(frame: CGRectInset(deliveryPriceCell.contentView.bounds, 15, 0))
            
            deliveryPriceText.returnKeyType = UIReturnKeyType.Next
            deliveryPriceText.placeholder = deliveryPricePlaceholderText
            deliveryPriceText.keyboardType = UIKeyboardType.DecimalPad
            deliveryPriceText.delegate = self
            deliveryPriceCell.addSubview(deliveryPriceText)
            
            if deliveryOption != nil {
                addTextLeftView()
                deliveryPriceText.text = deliveryOption!["price"] as! String
            }
            
            return deliveryPriceCell
        case 2:
            deliveryEstimatedTimeText = UITextField(frame: CGRectInset(deliveryEstimatedTimeCell.contentView.bounds, 15, 0))
            
            deliveryEstimatedTimeText.returnKeyType = UIReturnKeyType.Next
            deliveryEstimatedTimeText.placeholder = deliveryEstimatedTimePlaceholderText
            deliveryEstimatedTimeText.keyboardType = UIKeyboardType.NumberPad
            deliveryEstimatedTimeText.delegate = self
            deliveryEstimatedTimeCell.addSubview(deliveryEstimatedTimeText)
            
            if deliveryOption != nil {
                deliveryEstimatedTimeText.text = deliveryOption!["estimated_time"] as? String
            }
            
            return deliveryEstimatedTimeCell
            
        default:
            fatalError("Unknown row returned")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    // TextFieldViewDelegate
    func textFieldDidBeginEditing(textField: UITextField) {
        
        if textField == deliveryPriceText && deliveryPriceText.text == "" {
            addTextLeftView()
        }
    }
    
    private func addTextLeftView() {
        var dollarLabel: UILabel = UILabel(frame: CGRectMake(0, -1.0, 10, deliveryPriceText.frame.height))
        dollarLabel.text = "$"
        dollarLabel.textColor = UIColor.lightGrayColor()
        dollarLabel.textAlignment = NSTextAlignment.Left
        
        var offsetView: UIView = UIView(frame: dollarLabel.bounds)
        offsetView.addSubview(dollarLabel)
        
        deliveryPriceText.leftView = offsetView
        deliveryPriceText.leftViewMode = UITextFieldViewMode.Always
        
        deliveryPriceText.placeholder = ""
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == deliveryPriceText {
            if deliveryPriceText.text != "" {
                formatPrice()
            } else {
                deliveryPriceText.leftView = nil
                deliveryPriceText.placeholder = deliveryPricePlaceholderText
                deliveryPriceText.leftViewMode = UITextFieldViewMode.Never
            }
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if textField == deliveryPriceText {
            // Prevent double decimal point
            if string == "." && contains(deliveryPriceText.text, ".") {
                return false
            }
        }
        
        return true
    }
    
    // nav bar button callbacks
    func saveTapped(sender: UIBarButtonItem) {
        
        self.view.endEditing(true)
        
        let validateResult = self.validateInputs()
        let delay: NSTimeInterval = 3
        
        // validate
        if validateResult.valid {
            
            if deliveryOption != nil {
                let deliveryOptionId = deliveryOption!["id"] as! Int
                
                manager.POST(SprubixConfig.URL.api + "/delivery/option/edit/\(deliveryOptionId)",
                    parameters: [
                        "name": deliveryNameText.text,
                        "price": deliveryPriceText.text,
                        "estimated_time": deliveryEstimatedTimeText.text
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject:
                        AnyObject!) in
                        
                        // add notification for success
                        self.navigationController?.popViewControllerAnimated(true)
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            } else {
                let userId:Int? = defaults.objectForKey("userId") as? Int
                
                if userId != nil {
                    manager.POST(SprubixConfig.URL.api + "/delivery/option/create",
                        parameters: [
                            "name": deliveryNameText.text,
                            "price": deliveryPriceText.text,
                            "estimated_time": deliveryEstimatedTimeText.text,
                            "user_id": userId!
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject:
                            AnyObject!) in
                            
                            var response = responseObject as! NSDictionary
                            var status = response["status"] as! String
                            var data = response["data"] as! NSDictionary
                            
                            // success
                            if status == "200" {
                                // add notification for success
                                let viewDelay: Double = 2.0
                                
                                // success
                                TSMessage.showNotificationInViewController(
                                    TSMessage.defaultViewController(),
                                    title: "Success!",
                                    subtitle: "Delivery option added",
                                    image: UIImage(named: "filter-check"),
                                    type: TSMessageNotificationType.Success,
                                    duration: delay,
                                    callback: nil,
                                    buttonTitle: nil,
                                    buttonCallback: nil,
                                    atPosition: TSMessageNotificationPosition.Bottom,
                                    canBeDismissedByUser: true)
                                
                                Delay.delay(viewDelay) {
                                    // add notification for success
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
                                
                                println(data)
                            }
                            
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
                    println("userId not found, please login or create an account")
                }
            }
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
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func validateInputs() -> (valid: Bool, message: String) {
        var valid: Bool = true
        var message: String = ""
        
        formatPrice()
        
        if deliveryNameText.text == "" {
            message += "Please enter a delivery option name\n"
            valid = false
        } else if count(deliveryNameText.text) > 255 {
            message += "The delivery option name is too long\n"
            valid = false
        }
        
        if deliveryPriceText.text == "" {
            message += "Please enter the delivery option price\n"
            valid = false
        }
        
        if deliveryEstimatedTimeText.text == "" {
            message += "Please enter the estimated duration for the delivery option\n"
            valid = false
        }
        
        return (valid, message)
    }
    
    func formatPrice() {
        if contains(deliveryPriceText.text, ".") {
            let priceArray = deliveryPriceText.text.componentsSeparatedByString(".")
            var digit = priceArray[0] as String
            var decimal = priceArray[1] as String
            
            // if .XX , make it 0.XX
            if digit == "" {
                digit = "0"
            }
            
            // truncate decimal
            if count(decimal) == 0 {
                decimal = "00"
            } else if count(decimal) == 1 {
                decimal = "\(decimal)0"
            } else {
                decimal = decimal.substringWithRange(Range(start: decimal.startIndex, end: advance(decimal.startIndex, 2)))
            }
            
            deliveryPriceText.text = "\(digit).\(decimal)"
            
        } else if deliveryPriceText.text != "" {
            deliveryPriceText.text = "\(deliveryPriceText.text).00"
        }
    }
}

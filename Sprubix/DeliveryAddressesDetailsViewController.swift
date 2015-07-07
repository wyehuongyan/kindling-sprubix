//
//  DeliveryAddressesDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 5/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import ActionSheetPicker_3_0
import TSMessages

class DeliveryAddressesDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var deliveryAddressDetailsTable: UITableView!
    var oldFrameRect: CGRect!
    var makeKeyboardVisible = true
    
    // table view cells
    var firstNameCell: UITableViewCell = UITableViewCell()
    var lastNameCell: UITableViewCell = UITableViewCell()
    var companyCell: UITableViewCell = UITableViewCell()
    var contactCell: UITableViewCell = UITableViewCell()
    
    var address1Cell: UITableViewCell = UITableViewCell()
    var address2Cell: UITableViewCell = UITableViewCell()
    var postalCodeCell: UITableViewCell = UITableViewCell()
    var cityCell: UITableViewCell = UITableViewCell()
    var stateCell: UITableViewCell = UITableViewCell()
    var countryCell: UITableViewCell = UITableViewCell()
    
    var firstNameText: UITextField!
    var lastNameText: UITextField!
    var companyText: UITextField!
    var contactText: UITextField!
    
    var address1Text: UITextField!
    var address2Text: UITextField!
    var postalCodeText: UITextField!
    var cityText: UITextField!
    var stateText: UITextField!
    var countryText: UITextField!
    var countryCode: String?
    
    var tableTapGestureRecognizer: UITapGestureRecognizer!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        deliveryAddressDetailsTable = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Grouped)
        
        deliveryAddressDetailsTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        deliveryAddressDetailsTable.backgroundColor = sprubixGray
        deliveryAddressDetailsTable.dataSource = self
        deliveryAddressDetailsTable.delegate = self
        oldFrameRect = deliveryAddressDetailsTable.frame
        
        // register method when tapped to hide keyboard
        tableTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tableTapped:")
        deliveryAddressDetailsTable.addGestureRecognizer(tableTapGestureRecognizer)
        tableTapGestureRecognizer.enabled = false
        
        view.addSubview(deliveryAddressDetailsTable)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil);
        
        initNavBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Add Delivery Address"
        
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
        case 1:
            return 6
        default:
            return 0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Personal"
        case 1:
            return "Deliver to"
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // personal
            switch indexPath.row {
            case 0:
                if firstNameText == nil {
                    firstNameText = UITextField(frame: CGRectInset(firstNameCell.contentView.bounds, 15, 0))
                    
                    firstNameText.returnKeyType = UIReturnKeyType.Default

                    firstNameText.placeholder = "First Name"
                    firstNameText.delegate = self
                    firstNameCell.addSubview(firstNameText)
                }
                
                return firstNameCell

            case 1:
                if lastNameText == nil {
                    lastNameText = UITextField(frame: CGRectInset(lastNameCell.contentView.bounds, 15, 0))
                    
                    lastNameText.returnKeyType = UIReturnKeyType.Default
                    
                    lastNameText.placeholder = "Last Name"
                    lastNameText.delegate = self
                    lastNameCell.addSubview(lastNameText)
                }
                
                return lastNameCell
            case 2:
                if companyText == nil {
                    companyText = UITextField(frame: CGRectInset(companyCell.contentView.bounds, 15, 0))
                    
                    companyText.returnKeyType = UIReturnKeyType.Default
                    
                    companyText.placeholder = "Company (Optional)"
                    companyText.delegate = self
                    companyCell.addSubview(companyText)
                }
                
                return companyCell
            case 3:
                if contactText == nil {
                    contactText = UITextField(frame: CGRectInset(contactCell.contentView.bounds, 15, 0))
                    
                    contactText.returnKeyType = UIReturnKeyType.Default
                    contactText.keyboardType = UIKeyboardType.NumberPad
                    contactText.placeholder = "Contact Number"
                    contactText.delegate = self
                    contactCell.addSubview(contactText)
                }
                
                return contactCell
            default:
                fatalError("Unknown row returned")
            }
            
        case 1:
            // deliver to
            switch indexPath.row {
            case 0:
                if address1Text == nil {
                    address1Text = UITextField(frame: CGRectInset(address1Cell.contentView.bounds, 15, 0))
                    
                    address1Text.returnKeyType = UIReturnKeyType.Default
                    
                    address1Text.placeholder = "Address Line 1"
                    address1Text.delegate = self
                    address1Cell.addSubview(address1Text)
                }
                    
                return address1Cell
            case 1:
                if address2Text == nil {
                    address2Text = UITextField(frame: CGRectInset(address2Cell.contentView.bounds, 15, 0))
                    
                    address2Text.returnKeyType = UIReturnKeyType.Default
                    
                    address2Text.placeholder = "Address Line 2 (Optional)"
                    address2Text.delegate = self
                    address2Cell.addSubview(address2Text)
                }
                
                return address2Cell
            case 2:
                if postalCodeText == nil {
                    postalCodeText = UITextField(frame: CGRectInset(postalCodeCell.contentView.bounds, 15, 0))
                    
                    postalCodeText.returnKeyType = UIReturnKeyType.Default
                    postalCodeText.keyboardType = UIKeyboardType.NumberPad
                    postalCodeText.placeholder = "Postal Code"
                    postalCodeText.delegate = self
                    postalCodeCell.addSubview(postalCodeText)
                }
                
                return postalCodeCell
            case 3:
                if cityText == nil {
                    cityText = UITextField(frame: CGRectInset(cityCell.contentView.bounds, 15, 0))
                    
                    cityText.returnKeyType = UIReturnKeyType.Default
                    
                    cityText.placeholder = "City"
                    cityText.delegate = self
                    cityCell.addSubview(cityText)
                }
                
                return cityCell
            case 4:
                if stateText == nil {
                    stateText = UITextField(frame: CGRectInset(stateCell.contentView.bounds, 15, 0))
                    
                    stateText.returnKeyType = UIReturnKeyType.Default
                    
                    stateText.placeholder = "State"
                    stateText.delegate = self
                    stateCell.addSubview(stateText)
                }
                    
                return stateCell
            case 5:
                if countryText == nil {
                    countryText = UITextField(frame: CGRectInset(countryCell.contentView.bounds, 15, 0))
                    
                    countryText.returnKeyType = UIReturnKeyType.Default
                    
                    countryText.placeholder = "Country"
                    countryText.delegate = self
                    countryCell.addSubview(countryText)
                }
                
                return countryCell
            default:
                fatalError("Unknown row returned")
            }
        default:
            fatalError("Unknown section returned")
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == countryText {
            showCountryPicker()
            
            return false
        }
        
        return true
    }
    
    private func showCountryPicker() {
        let locale = NSLocale.currentLocale()
        let countryArray = NSLocale.ISOCountryCodes()
        var unsortedCountryArray:[String] = []
        
        for countryCode in countryArray {
            let displayNameString = locale.displayNameForKey(NSLocaleCountryCode, value: countryCode)
            
            if displayNameString != nil {
                unsortedCountryArray.append(displayNameString!)
            }
        }
        
        let codeForCountryDictionary: NSDictionary = NSDictionary(objects: countryArray, forKeys: unsortedCountryArray)
        
        let sortedCountryArray = sorted(unsortedCountryArray, <)
        
        let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Country", rows: sortedCountryArray as [String], initialSelection: 197,
        doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
        
            self.countryCode = codeForCountryDictionary[selectedValue as! String] as? String
            
            self.countryText.text = selectedValue as! String
            
        }, cancelBlock: nil, origin: view)
        
        // custom done button
        let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        doneButton.setTitleTextAttributes([
        NSForegroundColorAttributeName: sprubixColor,
        ], forState: UIControlState.Normal)
        
        picker.setDoneButton(doneButton)
        
        // custom cancel button
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        cancelButton.setTitle("X", forState: UIControlState.Normal)
        cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
        
        picker.showActionSheetPicker()

    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func saveTapped(sender: UIBarButtonItem) {
        println("save tapped")
        
        if validateShippingAddressInfo() {
            let shippingAddressInfo: NSMutableDictionary = NSMutableDictionary()
            
            shippingAddressInfo.setObject(firstNameText.text, forKey: "first_name")
            shippingAddressInfo.setObject(lastNameText.text, forKey: "last_name")
            
            if companyText.text != "" {
                shippingAddressInfo.setObject(companyText.text, forKey: "company")
            }
            
            shippingAddressInfo.setObject(contactText.text, forKey: "contact_number")
            shippingAddressInfo.setObject(address1Text.text, forKey: "address_1")
            
            if address2Text.text != "" {
                shippingAddressInfo.setObject(address2Text.text, forKey: "address_2")
            }
            
            shippingAddressInfo.setObject(postalCodeText.text, forKey: "postal_code")
            shippingAddressInfo.setObject(cityText.text, forKey: "city")
            shippingAddressInfo.setObject(stateText.text, forKey: "state")
            shippingAddressInfo.setObject(countryText.text, forKey: "country")
            shippingAddressInfo.setObject(countryCode!, forKey: "country_code")
            
            println(shippingAddressInfo)
            
            // hide keyboard
            makeKeyboardVisible = false
            self.view.endEditing(true)
            
            // REST call to server to create user shipping address 
            manager.POST(SprubixConfig.URL.api + "/shipping/address/create",
                parameters: shippingAddressInfo,
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    var status = responseObject["status"] as! String
                    var automatic: NSTimeInterval = 0
                    
                    if status == "200" {
                        // success
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Delivery address added", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                        self.navigationController?.popViewControllerAnimated(true)
                    } else {
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
    
    private func validateShippingAddressInfo() -> Bool {
        var errorMessage: String = "Please fill up the required field(s):\n"
        var noError = true
        
        // check if all fields except the optional ones are filled
        if firstNameText.text == "" {
            errorMessage += "\nFirst Name"
            
            noError = false
        }
        
        if lastNameText.text == "" {
            errorMessage += "\nLast Name"
            
            noError = false
        }

        if contactText.text == "" {
            errorMessage += "\nContact Number"
            
            noError = false
        }
        
        if address1Text.text == "" {
            errorMessage += "\nAddress Line 1"
            
            noError = false
        }
        
        if postalCodeText.text == "" {
            errorMessage += "\nPostal Code"
            
            noError = false
        }
        
        if cityText.text == "" {
            errorMessage += "\nCity"
            
            noError = false
        }
        
        if stateText.text == "" {
            errorMessage += "\nState"
            
            noError = false
        }
        
        if countryText.text == "" {
            errorMessage += "\nCountry"
            
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
    
    func keyboardWillChange(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        if makeKeyboardVisible {
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.deliveryAddressDetailsTable.frame.size.height = self.oldFrameRect.size.height - keyboardFrame.height
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                        self.tableTapGestureRecognizer.enabled = true
                    }
            })
        } else {
            view.layoutIfNeeded()
            
            self.tableTapGestureRecognizer.enabled = false
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.deliveryAddressDetailsTable.frame.size.height = self.oldFrameRect.size.height
                
                self.view.layoutIfNeeded()
                
                }, completion: { finished in
                    if finished {
                        self.makeKeyboardVisible = true
                    }
            })
        }
    }
    
    /**
    * Called when the user click on the view (outside the UITextField).
    */
    func tableTapped(gesture: UITapGestureRecognizer) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
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
}

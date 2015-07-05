//
//  DeliveryAddressesDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 5/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class DeliveryAddressesDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var deliveryAddressDetailsTable:UITableView!
    
    // table view cells
    var firstNameCell:UITableViewCell = UITableViewCell()
    var lastNameCell:UITableViewCell = UITableViewCell()
    var companyCell:UITableViewCell = UITableViewCell()
    var contactCell:UITableViewCell = UITableViewCell()
    
    var address1Cell:UITableViewCell = UITableViewCell()
    var address2Cell:UITableViewCell = UITableViewCell()
    var postalCodeCell:UITableViewCell = UITableViewCell()
    var cityCell:UITableViewCell = UITableViewCell()
    var stateCell:UITableViewCell = UITableViewCell()
    var countryCell:UITableViewCell = UITableViewCell()
    
    var firstNameText:UITextField!
    var lastNameText:UITextField!
    var companyText:UITextField!
    var contactText:UITextField!
    
    var address1Text:UITextField!
    var address2Text:UITextField!
    var postalCodeText:UITextField!
    var cityText:UITextField!
    var stateText:UITextField!
    var countryText:UITextField!
    
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
        
        view.addSubview(deliveryAddressDetailsTable)
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
                    
                    firstNameText.returnKeyType = UIReturnKeyType.Next
                    
                    firstNameText.placeholder = "First Name"
                    firstNameText.delegate = self
                    firstNameCell.addSubview(firstNameText)
                }
                
                return firstNameCell

            case 1:
                if lastNameText == nil {
                    lastNameText = UITextField(frame: CGRectInset(lastNameCell.contentView.bounds, 15, 0))
                    
                    lastNameText.returnKeyType = UIReturnKeyType.Next
                    
                    lastNameText.placeholder = "Last Name"
                    lastNameText.delegate = self
                    lastNameCell.addSubview(lastNameText)
                }
                
                return lastNameCell
            case 2:
                if companyText == nil {
                    companyText = UITextField(frame: CGRectInset(companyCell.contentView.bounds, 15, 0))
                    
                    companyText.returnKeyType = UIReturnKeyType.Next
                    
                    companyText.placeholder = "Company (Optional)"
                    companyText.delegate = self
                    companyCell.addSubview(companyText)
                }
                
                return companyCell
            case 3:
                if contactText == nil {
                    contactText = UITextField(frame: CGRectInset(contactCell.contentView.bounds, 15, 0))
                    
                    contactText.returnKeyType = UIReturnKeyType.Next
                    
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
                    
                    address1Text.returnKeyType = UIReturnKeyType.Next
                    
                    address1Text.placeholder = "Address Line 1"
                    address1Text.delegate = self
                    address1Cell.addSubview(address1Text)
                }
                    
                return address1Cell
            case 1:
                if address2Text == nil {
                    address2Text = UITextField(frame: CGRectInset(address2Cell.contentView.bounds, 15, 0))
                    
                    address2Text.returnKeyType = UIReturnKeyType.Next
                    
                    address2Text.placeholder = "Address Line 2 (Optional)"
                    address2Text.delegate = self
                    address2Cell.addSubview(address2Text)
                }
                
                return address2Cell
            case 2:
                if postalCodeText == nil {
                    postalCodeText = UITextField(frame: CGRectInset(postalCodeCell.contentView.bounds, 15, 0))
                    
                    postalCodeText.returnKeyType = UIReturnKeyType.Next
                    
                    postalCodeText.placeholder = "Postal Code"
                    postalCodeText.delegate = self
                    postalCodeCell.addSubview(postalCodeText)
                }
                
                return postalCodeCell
            case 3:
                if cityText == nil {
                    cityText = UITextField(frame: CGRectInset(cityCell.contentView.bounds, 15, 0))
                    
                    cityText.returnKeyType = UIReturnKeyType.Next
                    
                    cityText.placeholder = "City"
                    cityText.delegate = self
                    cityCell.addSubview(cityText)
                }
                
                return cityCell
            case 4:
                if stateText == nil {
                    stateText = UITextField(frame: CGRectInset(stateCell.contentView.bounds, 15, 0))
                    
                    stateText.returnKeyType = UIReturnKeyType.Next
                    
                    stateText.placeholder = "State"
                    stateText.delegate = self
                    stateCell.addSubview(stateText)
                }
                    
                return stateCell
            case 5:
                if countryText == nil {
                    countryText = UITextField(frame: CGRectInset(countryCell.contentView.bounds, 15, 0))
                    
                    countryText.returnKeyType = UIReturnKeyType.Next
                    
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

    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

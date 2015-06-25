//
//  DeliveryOptionsDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 24/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class DeliveryOptionsDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var deliveryOptionTable: UITableView!
    var deliveryNameCell: UITableViewCell = UITableViewCell()
    var deliveryPriceCell: UITableViewCell = UITableViewCell()
    
    var deliveryNameText: UITextField!
    var deliveryPriceText: UITextField!
    
    let deliveryNamePlaceholderText = "What is this delivery option called?"
    
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
        newNavItem.title = "Add Delivery Option"
        
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
            
            return deliveryNameCell
        case 1:
            deliveryPriceText = UITextField(frame: CGRectInset(deliveryPriceCell.contentView.bounds, 20, 0))
            
            deliveryPriceText.returnKeyType = UIReturnKeyType.Next
            deliveryPriceText.placeholder = "How much does it cost?"
            deliveryPriceText.keyboardType = UIKeyboardType.DecimalPad
            deliveryPriceText.delegate = self
            deliveryPriceCell.addSubview(deliveryPriceText)
            
            return deliveryPriceCell
        default:
            fatalError("Unknown row returned")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    // TextFieldViewDelegate
    func textFieldDidBeginEditing(textField: UITextField) {
        
        if textField == deliveryPriceText && deliveryPriceText.text == "" {
            var dollarLabel: UILabel = UILabel(frame: CGRectMake(0, -1, 10, deliveryPriceText.frame.height))
            dollarLabel.text = "$"
            dollarLabel.textColor = UIColor.lightGrayColor()
            dollarLabel.textAlignment = NSTextAlignment.Left
            
            var offsetView: UIView = UIView(frame: dollarLabel.bounds)
            offsetView.addSubview(dollarLabel)
            
            deliveryPriceText.leftView = offsetView
            deliveryPriceText.leftViewMode = UITextFieldViewMode.Always
            
            deliveryPriceText.placeholder = ""
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == deliveryPriceText && deliveryPriceText.text == "" {
            deliveryPriceText.leftView = nil
            deliveryPriceText.placeholder = deliveryNamePlaceholderText
            deliveryPriceText.leftViewMode = UITextFieldViewMode.Never
        }
    }
    
    // nav bar button callbacks
    func saveTapped(sender: UIBarButtonItem) {
        // validate
        if deliveryPriceText.text != "" && deliveryNameText.text != "" {
            
            let userId:Int? = defaults.objectForKey("userId") as? Int
            
            if userId != nil {
                manager.POST(SprubixConfig.URL.api + "/delivery/option/create",
                    parameters: [
                        "name": deliveryNameText.text,
                        "price": deliveryPriceText.text,
                        "user_id": userId!
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
                println("userId not found, please login or create an account")
            }
        }
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

//
//  InventoryOptionsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 10/9/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import TSMessages

class InventoryOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var inventoryOptionsTableView: UITableView!
    var lowStockLimitCell: UITableViewCell = UITableViewCell()
    var lowStockLimitText: UITextField!
    var lowStockLimit: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let userData: NSDictionary! = defaults.dictionaryForKey("userData")
        let shoppable = userData["shoppable"] as! NSDictionary
        
        lowStockLimit = shoppable["low_stock_limit"] as! String
        
        initNavBar()
        initTableView()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Options"
        
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
        
        // 5. create a options button
        var saveButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        saveButton.setTitle("save", forState: UIControlState.Normal)
        saveButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        saveButton.frame = CGRect(x: 0, y: 0, width: 70, height: 20)
        saveButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        saveButton.addTarget(self, action: "saveTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var saveBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: saveButton)
        newNavItem.rightBarButtonItem = saveBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initTableView() {
        inventoryOptionsTableView = UITableView(frame: CGRectMake(0, navigationHeight, screenWidth, screenHeight - navigationHeight), style: UITableViewStyle.Grouped)
        
        inventoryOptionsTableView.backgroundColor = sprubixGray
        inventoryOptionsTableView.dataSource = self
        inventoryOptionsTableView.delegate = self
        inventoryOptionsTableView.tableFooterView = UIView(frame: CGRectZero)
        
        view.addSubview(inventoryOptionsTableView)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Low stock warning limit"
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            lowStockLimitText = UITextField(frame: CGRectInset(lowStockLimitCell.contentView.bounds, 15, 0))
            
            lowStockLimitText.placeholder = "e.g 5"
            
            if lowStockLimit != "0" {
                lowStockLimitText.text = lowStockLimit
            }
            
            lowStockLimitText.keyboardType = UIKeyboardType.NumberPad
            lowStockLimitCell.addSubview(lowStockLimitText)
            
            return lowStockLimitCell
        default:
            fatalError("Unknown row returned")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func saveTapped(sender: UIBarButtonItem) {
        if lowStockLimitText.text != "" {
            let delay: NSTimeInterval = 2
            let userId:Int? = defaults.objectForKey("userId") as? Int
            
            self.view.endEditing(true)
            
            if userId != nil {
                // REST call to update user shoppable's stock limit property
                manager.POST(SprubixConfig.URL.api + "/user/\(userId!)/low/limit",
                    parameters: [
                        "low_stock_limit": lowStockLimitText.text
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject:
                        AnyObject!) in
                        
                        var data = responseObject as! NSDictionary
                        
                        println(data)
                        
                        // add notification for success
                        let viewDelay: Double = 2.0
                        
                        // success
                        TSMessage.showNotificationInViewController(
                            TSMessage.defaultViewController(),
                            title: "Success!",
                            subtitle: "Profile updated",
                            image: UIImage(named: "filter-check"),
                            type: TSMessageNotificationType.Success,
                            duration: delay,
                            callback: nil,
                            buttonTitle: nil,
                            buttonCallback: nil,
                            atPosition: TSMessageNotificationPosition.Bottom,
                            canBeDismissedByUser: true)
                        
                        // update cache
                        var cleanData = self.cleanDictionary(data as! NSMutableDictionary)
                        defaults.setObject(cleanData["id"], forKey: "userId")
                        defaults.setObject(cleanData, forKey: "userData")
                        defaults.synchronize()
                        
                        Delay.delay(viewDelay) {
                            self.navigationController?.popViewControllerAnimated(true)
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
            }
        } else {
            // alert
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
}

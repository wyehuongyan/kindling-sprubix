//
//  PaymentMethodsDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import SSKeychain
import TSMessages
import Braintree

class PaymentMethodsDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BTUICardFormViewDelegate {
    
    var paymentMethodsCount: Int?
    
    // table view cells
    var numberCell: UITableViewCell = UITableViewCell()
    var expirationMonthCell: UITableViewCell = UITableViewCell()
    var expirationYearCell: UITableViewCell = UITableViewCell()
    var contactCell: UITableViewCell = UITableViewCell()
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    // cardform
    var cardFormView: BTUICardFormView?
    let cardFormViewHeight: CGFloat = 160.0
    
    var activityView: UIActivityIndicatorView!
    
    // tableview
    var paymentMethodTableView: UITableView!
    var cardFormCell: UITableViewCell = UITableViewCell()
    var isDefaultCell: UITableViewCell = UITableViewCell()
    var isDefaultSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        retrieveBTClientToken()
        initTableView()
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: ((screenHeight - screenHeight / 3) - activityViewWidth / 2), width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
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
        newNavItem.title = "Add Payment Method"
        
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
    
    func initTableView() {
        paymentMethodTableView = UITableView(frame: CGRectMake(0, navigationHeight, screenWidth, screenHeight - navigationHeight), style: UITableViewStyle.Grouped)
     
        paymentMethodTableView.backgroundColor = sprubixGray
        paymentMethodTableView.scrollEnabled = false
        
        paymentMethodTableView.dataSource = self
        paymentMethodTableView.delegate = self
        
        view.addSubview(paymentMethodTableView)
    }
    
    func retrieveBTClientToken() {
        // REST call to server 
        manager.GET(SprubixConfig.URL.api + "/auth/braintree/token",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                var status = responseObject["status"] as? String
                
                if status != nil {
                    
                    if status == "200" {
                        var token = responseObject["token"] as? String
                        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                        
                        let username = userData!["username"] as! String
                        
                        SSKeychain.setPassword(token, forService: "braintree", account: username)
                        
                        // init braintree
                        braintreeRef = Braintree(clientToken: token)
                        
                        println("Braintree instance initialized")
                        
                    } else {
                        var automatic: NSTimeInterval = 0
                        
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Braintree token retrieval failed.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                    
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return paymentMethodsCount > 0 ? 2 : 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        default:
            fatalError("Unknown section in PaymentMethodsDetailsViewController")
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Card Details"
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return cardFormViewHeight
        case 1:
            return cardFormViewHeight / 3
        default:
            fatalError("Unknown section in PaymentMethodsDetailsViewController")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if cardFormView == nil {
                cardFormView = BTUICardFormView(frame: CGRectMake(0, 0, screenWidth, cardFormViewHeight))
                cardFormView?.optionalFields = cardFormView!.optionalFields ^ BTUICardFormOptionalFields.PostalCode
                cardFormView?.delegate = self
                cardFormCell.selectionStyle = UITableViewCellSelectionStyle.None

                cardFormCell.addSubview(cardFormView!)
            }
            
            return cardFormCell
            
        case 1:
            isDefaultCell.textLabel?.text = "Set as default?"
            isDefaultCell.textLabel?.textColor = UIColor.grayColor()
            isDefaultCell.selectionStyle = UITableViewCellSelectionStyle.None
            
            if isDefaultSwitch == nil {
                let isDefaultSwitchWidth: CGFloat = 60
                isDefaultSwitch = UISwitch()
                
                isDefaultCell.accessoryView = isDefaultSwitch
                
                if paymentMethodsCount > 0 {
                    isDefaultSwitch.enabled = true
                } else {
                    isDefaultSwitch.enabled = false
                    isDefaultSwitch.setOn(true, animated: true)
                }
            }
            
            return isDefaultCell
        default:
            fatalError("Unknown section in PaymentMethodsDetailsViewController")
        }
    }
    
    // MARK: BTUICardFormViewDelegate
    func cardFormViewDidChange(cardFormView: BTUICardFormView!) {
        if cardFormView.valid {
            println("card information valid")
        } else {
            println("card information invalid, please re enter")
        }
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func saveTapped(sender: UIBarButtonItem) {
        if cardFormView!.valid {
            // hide keyboard
            self.view.endEditing(true)
            
            // processing
            // // display loading indicator
            activityView.startAnimating()
            
            // 1. REST call to BT to tokenize card information
            let request = BTClientCardRequest.new()
            request.number = cardFormView!.number
            request.expirationMonth = cardFormView!.expirationMonth
            request.expirationYear = cardFormView!.expirationYear
            
            braintreeRef?.tokenizeCard(request, completion: { (nonce, error) -> Void in
                if (error != nil) {
                    println("Error in tokenizing card: \(error)")
                } else {
                    println("Success \nNonce: \(nonce)")

                    // 2. REST call to server to save payment nonce and card info
                    manager.POST(SprubixConfig.URL.api + "/billing/payment/create",
                        parameters: [
                            "nonce": nonce,
                            "is_default": self.isDefaultSwitch != nil ? self.isDefaultSwitch.on : true
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject:
                            AnyObject!) in
                            
                            self.activityView.stopAnimating()
                            
                            var status = responseObject["status"] as! String
                            var automatic: NSTimeInterval = 0
                            
                            if status == "200" {
                                // success
                                TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Payment method added", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                                
                                self.navigationController?.popViewControllerAnimated(true)
                            } else {
                                // error exception
                                TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                            }
                            
                        },
                        failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                            println("Error: " + error.localizedDescription)
                            
                            self.activityView.stopAnimating()
                            
                            var automatic: NSTimeInterval = 0
                            
                            // error exception
                            TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Server is experiencing some issues.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    })
                }
            })
            
        } else {
            let errorMessage = "Some fields are entered incorrectly. Please try again."
            let alert = UIAlertController(title: "Oops!", message: errorMessage, preferredStyle: UIAlertControllerStyle.Alert)
            alert.view.tintColor = sprubixColor
            
            // Ok
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

//
//  SettingsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 8/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import SSKeychain

class SettingsViewController: UITableViewController {
    
    @IBOutlet var editProfileCell: UITableViewCell!
    @IBOutlet var changePasswordCell: UITableViewCell!
    @IBOutlet var paymentMethodsCell: UITableViewCell!
    @IBOutlet var deliveryAddressesCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        editProfileCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        changePasswordCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        deliveryAddressesCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        paymentMethodsCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        self.navigationItem.title = "Settings"
        
        // create a custom back button
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

        self.navigationItem.setLeftBarButtonItem(backBarButtonItem, animated: false)
        self.navigationController?.navigationBar.tintColor = UIColor.lightGrayColor()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        
        switch indexPath.section {
        case 0:
            // account
            switch indexPath.row {
            case 0:
                println("Edit Profile")
                
                let editProfileViewController = UIStoryboard.editProfileViewController()
                
                self.navigationController?.pushViewController(editProfileViewController!, animated: true)
                
            case 1:
                println("Change Password")
                
                let editPasswordViewController = EditPasswordViewController()
                
                self.navigationController?.pushViewController(editPasswordViewController, animated: true)
            default:
                fatalError("Unknown static cell for settings.")
            }
        case 1:
            // biling & delivery
            switch indexPath.row {
            case 0:
                println("Payment Methods")

                let paymentMethodsViewController = UIStoryboard.paymentMethodsViewController()
                
                self.navigationController?.pushViewController(paymentMethodsViewController!, animated: true)
                
            case 1:
                println("Delivery Addresses")
                
                let deliveryAddressesViewController = UIStoryboard.deliveryAddressesViewController()
                
                self.navigationController?.pushViewController(deliveryAddressesViewController!, animated: true)
            default:
                fatalError("Unknown static cell for settings.")
            }
        case 2:
            // support
            switch indexPath.row {
            case 0:
                println("Help Center")
            case 1:
                println("Provide Feedback")
            default:
                fatalError("Unknown static cell for settings.")
            }
        case 3:
            // logout
            switch indexPath.row {
            case 0:
                println("Logout")
                // remove firebase sskeychain
                // remove userData and userId from defaults
                let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                let username = userData!["username"] as! String
                
                firebaseRef.unauth()
                SSKeychain.deletePasswordForService("firebase", account: username)
                defaults.removeObjectForKey("userData")
                defaults.removeObjectForKey("userId")
                
                // show signin controller
                let storyboard = UIStoryboard(name: "Auth", bundle: nil)
                let signInVC = storyboard.instantiateViewControllerWithIdentifier("SignInNav") as! UIViewController

                sprubixNotificationViewController?.removeFirebaseListeners()
                sprubixNotificationViewController?.removeFromParentViewController()
                sprubixNotificationViewController = nil
                SidePanelOption.alerts.counter[SidePanelOption.Option.Notifications.toString()] = 0
                
                self.navigationController?.presentViewController(signInVC, animated: true, completion: nil)
                self.navigationController?.popViewControllerAnimated(true) // pop settings view controller
                
            default:
                fatalError("Unknown static cell for settings.")
            }
        default:
            fatalError("Unknown section for settings.")
        }
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

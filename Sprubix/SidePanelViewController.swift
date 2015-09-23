//
//  SidePanelViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

@objc
protocol SidePanelViewControllerDelegate {
    optional func toggleSidePanel()
    func showUserProfile(user: NSDictionary)
    func showCreateOutfit()
    func showNotifications()
    func showFavorites()
    func showSettings()
    func showInventory()
    func showCart()
    func showOrders()
    func showRefunds()
    func showDeliveryOptions()
}

class SidePanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var sidePanelTableView: UITableView!
    @IBOutlet var sidePanelTopView: UIView!
    
    var profileImage:UIImageView = UIImageView()
    var profileName:UILabel = UILabel()
    
    var sidePanelOptions:[SidePanelOption]!
    var delegate: SidePanelViewControllerDelegate?
    
    var userPoints: NSDictionary!
    var pointsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        initUserInfo()
        
        sidePanelTableView.separatorColor = UIColor.clearColor()
        sidePanelTableView.scrollEnabled = true
        sidePanelTopView.backgroundColor = sprubixLightGray
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        retrieveUserPoints()
    }
    
    func initUserInfo() {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            // create profile UIImageView programmatically
            let userThumbnailURL = NSURL(string: userData!["image"] as! String)
            
            profileImage.setImageWithURL(userThumbnailURL)
            let profileImageLength:CGFloat = 90
            
            // 30 is the sprubixfeed offset of 60 divided by 2. 50 is arbitary value, but should convert to constraint
            profileImage.frame = CGRect(x: (view.bounds.width / 2) - (profileImageLength / 2) + 30, y: 25, width: profileImageLength, height: profileImageLength)
            
            // circle mask
            profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
            profileImage.clipsToBounds = true
            profileImage.layer.borderWidth = 1.0
            profileImage.layer.borderColor = UIColor.lightGrayColor().CGColor
            profileImage.userInteractionEnabled = true
            
            // create username UILabel
            let profileNameLength:CGFloat = 200
            profileName.frame = CGRect(x: (view.bounds.width / 2) - (profileNameLength / 2) + 30, y: profileImage.center.y + 50, width: profileNameLength, height: 21)
            //profileName.font = UIFont(name: profileName.font.fontName, size: 17)
            profileName.textColor = UIColor.darkGrayColor()
            profileName.text = userData!["username"] as? String
            profileName.textAlignment = NSTextAlignment.Center
            profileName.userInteractionEnabled = true
            
            let viewProfileLabel = UILabel(frame: CGRectMake(0, 20, profileName.frame.size.width, profileName.frame.size.height))
            
            viewProfileLabel.font = UIFont(name: viewProfileLabel.font.fontName, size: 12)
            viewProfileLabel.textColor = UIColor.grayColor()
            viewProfileLabel.text = "View Profile"
            viewProfileLabel.textAlignment = NSTextAlignment.Center
            
            profileName.addSubview(viewProfileLabel)
            
            sidePanelTopView.addSubview(profileImage)
            sidePanelTopView.addSubview(profileName)
            
            // add gesture recognizers
            var profileImageTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
            profileImageTap.numberOfTapsRequired = 1
            profileImage.addGestureRecognizer(profileImageTap)
            
            var profileNameTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
            profileNameTap.numberOfTapsRequired = 1
            profileName.addGestureRecognizer(profileNameTap)
            
            // points text view
            let pointsTextViewHeight: CGFloat = 30.0
            pointsTextView = UITextView(frame: CGRectMake(0, 10, screenWidth / 2.75, pointsTextViewHeight))
            
            pointsTextView.backgroundColor = UIColor.whiteColor()
            pointsTextView.textAlignment = NSTextAlignment.Right
            pointsTextView.text = "loading..."
            pointsTextView.textColor = sprubixColor
            pointsTextView.font = UIFont.systemFontOfSize(14.0)
            pointsTextView.layer.cornerRadius = pointsTextViewHeight / 2
            pointsTextView.layer.borderColor = sprubixColor.CGColor
            pointsTextView.layer.borderWidth = 2.0
            pointsTextView.textContainerInset = UIEdgeInsetsMake(6, 0, 6, 6);
            pointsTextView.clipsToBounds = true
            pointsTextView.editable = false
            pointsTextView.selectable = false
            
            sidePanelTopView.addSubview(pointsTextView)
        }
    }
    
    func retrieveUserPoints() {
        // REST call to retrieve latest points
        manager.GET(SprubixConfig.URL.api + "/user/points",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                
                self.userPoints = responseObject as! NSDictionary
                
                var points: Int? = self.userPoints["amount"] as? Int
                
                if points != nil {
                    self.pointsTextView.text = "\(points!) pts"
                } else {
                    self.pointsTextView.text = "0 pts"
                }
                
                self.pointsTextView.setNeedsDisplay()
                
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func wasSingleTapped(gesture: UITapGestureRecognizer) {
        let userData:NSDictionary! = defaults.dictionaryForKey("userData")
        
        delegate?.showUserProfile(userData)
        
        // Mixpanel - Viewed User Profile, Side Panel
        mixpanel.track("Viewed User Profile", properties: [
            "Source": "Side Panel",
            "Tab": "Outfit",
            "Target User ID": userData.objectForKey("id") as! Int
        ])
        // Mixpanel - End
    }
    
    // MARK: Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sidePanelOptions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SidePanelCell", forIndexPath: indexPath) as! SidePanelCell
        
        cell.configureForSidePanelOption(sidePanelOptions[indexPath.row])
        
        return cell
    }
    
    // Mark: Table View Delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let option = sidePanelOptions[indexPath.row].option!
        
        switch option {
        case .Messages:
            break
        case .Activity:
            delegate?.showNotifications()
            
            // Mixpanel - Viewed Notifications, Side Panel
            mixpanel.track("Viewed Notifications", properties: [
                "Source": "Side Panel"
            ])
            // Mixpanel - End
        case .CreateOutfit:
            delegate?.showCreateOutfit()
            
            // Mixpanel - Viewed Create Outfit, Side Panel
            mixpanel.track("Viewed Create Outfit", properties: [
                "Source": "Side Panel"
            ])
            // Mixpanel - End
        case .Favorites:
            delegate?.showFavorites()
            
            // Mixpanel - Viewed Favorites, Side Panel, Outfit
            mixpanel.track("Viewed Favorites", properties: [
                "Source": "Side Panel",
                "Tab": "Outfit"
            ])
            // Mixpanel - End
            break
        case .Settings:
            delegate?.showSettings()
            
            // Mixpanel - Viewed Settings, Side Panel
            mixpanel.track("Viewed Settings", properties: [
                "Source": "Side Panel"
            ])
            // Mixpanel - End
            break
        case .Inventory:
            delegate?.showInventory()
            
            // Mixpanel - Viewed Inventory, Side Panel
            mixpanel.track("Viewed Inventory", properties: [
                "Source": "Side Panel",
                "Tab": "All"
            ])
            // Mixpanel - End
            break
        case .Cart:
            delegate?.showCart()
            
            // Mixpanel - Viewed Carts, Side Panel
            mixpanel.track("Viewed Cart", properties: [
                "Source": "Side Panel"
            ])
            // Mixpanel - End
            break
        case .Orders:
            delegate?.showOrders()
            
            // Mixpanel - Viewed Orders, Side Panel
            mixpanel.track("Viewed Orders", properties: [
                "Source": "Side Panel",
                "Tab": "Active"
            ])
            // Mixpanel - End
            break
        case .Refunds:
            delegate?.showRefunds()
            
            // Mixpanel - Viewed Orders, Side Panel
            mixpanel.track("Viewed Refunds", properties: [
                "Source": "Side Panel"
            ])
            // Mixpanel - End
            break
        case .DeliveryOptions:
            delegate?.showDeliveryOptions()
            
            // Mixpanel - Viewed Delivery Options, Side Panel
            mixpanel.track("Viewed Delivery Options", properties: [
                "Source": "Side Panel"
            ])
            // Mixpanel - End
            break
        }
    }
    
}

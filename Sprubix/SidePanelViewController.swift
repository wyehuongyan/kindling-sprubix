//
//  SidePanelViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

@objc
protocol SidePanelViewControllerDelegate {
    optional func toggleSidePanel()
    func showUserProfile(user: NSDictionary)
    func showCreateOutfit()
    func showNotifications()
    func showFavorites()
    func showSettingsView()
}

class SidePanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var sidePanelTableView: UITableView!
    
    var profileImage:UIImageView = UIImageView()
    var profileName:UILabel = UILabel()
    
    var sidePanelOptions:[SidePanelOption]!
    var delegate: SidePanelViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUserInfo()
        
        sidePanelTableView.separatorColor = UIColor.clearColor()
        sidePanelTableView.scrollEnabled = false
    }
    
    func initUserInfo() {
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            // create profile UIImageView programmatically
            let userThumbnailURL = NSURL(string: userData!["image"] as! String)
            
            profileImage.setImageWithURL(userThumbnailURL)
            let profileImageLength:CGFloat = 100
            
            // 30 is the sprubixfeed offset of 60 divided by 2. 50 is arbitary value, but should convert to constraint
            profileImage.frame = CGRect(x: (view.bounds.width / 2) - (profileImageLength / 2) - 30, y: 50, width: profileImageLength, height: profileImageLength)
            
            // circle mask
            profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
            profileImage.clipsToBounds = true
            profileImage.layer.borderWidth = 1.0
            profileImage.layer.borderColor = UIColor.lightGrayColor().CGColor
            profileImage.userInteractionEnabled = true
            
            // create username UILabel
            let profileNameLength:CGFloat = 200
            profileName.frame = CGRect(x: (view.bounds.width / 2) - (profileNameLength / 2) - 30, y: profileImage.center.y + 60, width: profileNameLength, height: 21)
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
            
            view.addSubview(profileImage)
            view.addSubview(profileName)
            
            // add gesture recognizers
            var profileImageTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
            profileImageTap.numberOfTapsRequired = 1
            profileImage.addGestureRecognizer(profileImageTap)
            
            var profileNameTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
            profileNameTap.numberOfTapsRequired = 1
            profileName.addGestureRecognizer(profileNameTap)
        }
    }
    
    func wasSingleTapped(gesture: UITapGestureRecognizer) {
        let userData:NSDictionary! = defaults.dictionaryForKey("userData")
        
        delegate?.showUserProfile(userData)
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
        case .Notifications:
            delegate?.showNotifications()
        case .CreateOutfit:
            delegate?.showCreateOutfit()
        case .Favorites:
            delegate?.showFavorites()
            break
        case .Settings:
            delegate?.showSettingsView()
            break
        }
    }
    
}

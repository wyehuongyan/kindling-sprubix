//
//  SidePanelViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol SidePanelViewControllerDelegate {
    func showUserProfile(user: NSDictionary)
    func showCreateOutfit()
    func showNotifications()
    //func sidePanelCellSelected(sidePanelOption: SidePanelOption)
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
            profileName.text = userData!["username"] as? String
            profileName.textAlignment = NSTextAlignment.Center
            
            view.addSubview(profileImage)
            //view.addSubview(profileName)
            
            // add gesture recognizers
            var singleTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
            singleTap.numberOfTapsRequired = 1
            profileImage.addGestureRecognizer(singleTap)
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
        
        let badgeWidth: CGFloat = 20
        //var badge: UILabel = UILabel(frame: CGRectMake(2 * screenWidth / 3, cell.frame.size.height / 2 - badgeWidth / 2, badgeWidth, badgeWidth))
        var badge: UILabel = UILabel(frame: CGRectMake(10, 5, badgeWidth, badgeWidth))
        badge.backgroundColor = sprubixColor
        badge.layer.cornerRadius = badgeWidth / 2
        badge.layer.borderWidth = 1.0
        badge.layer.borderColor = sprubixGray.CGColor
        badge.clipsToBounds = true
        badge.textColor = UIColor.whiteColor()
        badge.textAlignment = NSTextAlignment.Center
        badge.font = UIFont(name: mainBadge.font.fontName, size: 10)
        badge.text = "\(sprubixNotificationsCount)"
        
        cell.contentView.addSubview(badge)
        
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
        case .LikedOutfits:
            break
        case .Settings:
            break
        }
        
        println(option.toString())
    }
    
}

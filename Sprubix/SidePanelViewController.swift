//
//  SidePanelViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 7/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol SidePanelViewControllerDelegate {
    func sidePanelUserProfileSelected()
    //func sidePanelCellSelected(sidePanelOption: SidePanelOption)
}

class SidePanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var sidePanelTableView: UITableView!
    
    var sidePanelOptions:[SidePanelOption]!
    var delegate: SidePanelViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUserInfo()
        
        sidePanelTableView.separatorColor = UIColor.clearColor()
        sidePanelTableView.scrollEnabled = false
    }
    
    func initUserInfo() {
        // create profile UIImageView programmatically
        var profileImage:UIImageView = UIImageView(image: UIImage(named: "person-placeholder.jpg"))
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
        var profileName:UILabel = UILabel()
        let profileNameLength:CGFloat = 200
        profileName.frame = CGRect(x: (view.bounds.width / 2) - (profileNameLength / 2) - 30, y: profileImage.center.y + 60, width: profileNameLength, height: 21)
        profileName.text = "User Name"
        profileName.textAlignment = NSTextAlignment.Center
        
        view.addSubview(profileImage)
        view.addSubview(profileName)
        
        // add gesture recognizers
        var singleTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
        singleTap.numberOfTapsRequired = 1
        profileImage.addGestureRecognizer(singleTap)
    }
    
    func wasSingleTapped(gesture: UITapGestureRecognizer) {
        delegate?.sidePanelUserProfileSelected()
    }
    
    // MARK: Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sidePanelOptions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SidePanelCell", forIndexPath: indexPath) as SidePanelCell
        cell.configureForSidePanelOption(sidePanelOptions[indexPath.row])
        
        return cell
    }
    
    // Mark: Table View Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let selectedSidePanelCell = sidePanelOptions[indexPath.row]
        //delegate?.sidePanelCellSelected(selectedSidePanelCell)
        println(sidePanelOptions[indexPath.row].title)
    }
    
}

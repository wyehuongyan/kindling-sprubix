//
//  UserFollowListViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 9/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class UserFollowListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let userFollowListIdentifier: String = "UserFollowListCell"
    let userFollowListUNIdentifier: String = "UserFollowListUNCell"
    
    var following: Bool!
    var followListUsers: [NSDictionary] = [NSDictionary]()
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    @IBOutlet weak var followListTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // get rid of line seperator for empty cells
        followListTable.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        retrieveFollowList()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = following != true ? "Followers" : "Following"
        
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
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func retrieveFollowList() {
        if following != nil && following == true {
            // retrieve following
            retrieveFollowing()
        } else {
            // retrieve followers
            retrieveFollowers()
        }
    }
    
    private func retrieveFollowing() {
        // REST call to server to retrieve following
        manager.POST(SprubixConfig.URL.api + "/user/following",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.followListUsers = responseObject["data"] as! [NSDictionary]
                
                self.followListTable.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    private func retrieveFollowers() {
        // REST call to server to retrieve followers
        manager.GET(SprubixConfig.URL.api + "/user/followers",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.followListUsers = responseObject["data"] as! [NSDictionary]
                
                self.followListTable.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followListUsers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let user: NSDictionary = followListUsers[indexPath.row]
        
        let name = user["name"] as! String
        let username = user["username"] as! String
        let userImageURL = NSURL(string: user["image"] as! String)
        
        var cell: UITableViewCell!
        
        if name != "" {
            // use UserFollowListCell
            cell = tableView.dequeueReusableCellWithIdentifier(userFollowListIdentifier, forIndexPath: indexPath) as! UserFollowListCell
            
            (cell as! UserFollowListCell).realname.text = name
            (cell as! UserFollowListCell).username.text = username
            (cell as! UserFollowListCell).userImageView.setImageWithURL(userImageURL)
            
        } else {
            // use UserFollowListUNCell
            cell = tableView.dequeueReusableCellWithIdentifier(userFollowListUNIdentifier, forIndexPath: indexPath) as! UserFollowListUNCell
            
            (cell as! UserFollowListCell).username.text = username
            (cell as! UserFollowListCell).userImageView.setImageWithURL(userImageURL)
        }
        
        return cell
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

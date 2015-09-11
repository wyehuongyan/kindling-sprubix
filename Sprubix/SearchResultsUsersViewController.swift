//
//  SearchResultsUsersViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 3/9/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class SearchResultsUsersViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    let resultUserCellIdentifier = "UserFollowListCell"
    let resultUserUNCellIdentifier = "UserFollowListUNCell"
    
    var results: [NSDictionary] = [NSDictionary]()
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    var searchBar: UISearchBar?
    
    var currentPage: Int?
    var lastPage: Int?
    
    var searchString: String!
    var searchURL: String!
    
    @IBOutlet var resultsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        // get rid of line seperator for empty cells
        resultsTableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        containerViewController.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        initNavBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        containerViewController.statusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // infinite scrolling
        resultsTableView.addInfiniteScrollingWithActionHandler({
            self.insertMoreResults()
        })
    }
    
    func insertMoreResults() {
        if lastPage == nil || currentPage < lastPage {
            var params = NSMutableDictionary()
            
            params.setObject(searchString, forKey: "full_text")
            
            let nextPage = currentPage! + 1
            
            // REST call to server to refresh the results
            manager.POST(SprubixConfig.URL.api + searchURL + "?page=\(nextPage)",
                parameters: params,
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    var results = responseObject["data"] as! [NSDictionary]
                    
                    self.currentPage = nextPage
                    
                    for result in results {
                        self.results.append(result)
                        
                        self.resultsTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.results.count - 1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                        
                        if self.resultsTableView.infiniteScrollingView != nil {
                            self.resultsTableView.infiniteScrollingView.stopAnimating()
                        }
                    }
                    
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    if self.resultsTableView.infiniteScrollingView != nil {
                        self.resultsTableView.infiniteScrollingView.stopAnimating()
                    }
            })
        } else {
            if self.resultsTableView.infiniteScrollingView != nil {
                self.resultsTableView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    func initNavBar() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeaderAndStatusbarHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        newNavBar.backgroundColor = UIColor.whiteColor()
        newNavBar.translucent = false
        
        // 3. add a new navigation item w/title to the new nav bar
        let searchBarContainer = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight))
        searchBarContainer.backgroundColor = UIColor.whiteColor()
        searchBar = UISearchBar(frame: CGRectMake(0, 0, screenWidth - 50, navigationHeight))
        searchBar?.barTintColor = UIColor.whiteColor()
        searchBar?.backgroundColor = UIColor.whiteColor()
        searchBar?.setBackgroundImage(UIImage(), forBarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
        searchBar?.delegate = self
        searchBar?.text = searchString
        
        searchBarContainer.addSubview(searchBar!)
        
        newNavItem = UINavigationItem()
        newNavItem.titleView = searchBarContainer
        newNavItem.titleView?.userInteractionEnabled = true
        
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
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let user: NSDictionary = results[indexPath.row]
        
        let name = user["name"] as! String
        let username = user["username"] as! String
        let userImageURL = NSURL(string: user["image"] as! String)
        let userId = user["id"] as! Int
        
        var cell: UITableViewCell!
        
        if name != "" {
            // use UserFollowListCell
            cell = tableView.dequeueReusableCellWithIdentifier(resultUserCellIdentifier, forIndexPath: indexPath) as! UserFollowListCell
            
            (cell as! UserFollowListCell).user = user
            (cell as! UserFollowListCell).realname.text = name
            (cell as! UserFollowListCell).username.text = username
            (cell as! UserFollowListCell).userImageView.setImageWithURL(userImageURL)
            
            (cell as! UserFollowListCell).followed = user["followed"] as! Bool
            (cell as! UserFollowListCell).followButton.alpha = 0.0
            
        } else {
            // use UserFollowListUNCell
            cell = tableView.dequeueReusableCellWithIdentifier(resultUserUNCellIdentifier, forIndexPath: indexPath) as! UserFollowListUNCell
            
            (cell as! UserFollowListUNCell).user = user
            (cell as! UserFollowListUNCell).username.text = username
            (cell as! UserFollowListUNCell).userImageView.setImageWithURL(userImageURL)
            
            (cell as! UserFollowListUNCell).followed = user["followed"] as! Bool
            (cell as! UserFollowListUNCell).followButton.alpha = 0.0
        }
        
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let user: NSDictionary = results[indexPath.row]
        
        containerViewController.showUserProfile(user)
        
        // Mixpanel - Viewed User Profile, Search Results
        mixpanel.track("Viewed User Profile", properties: [
            "Source": "Search Results",
            "Target User ID": user.objectForKey("id") as! Int
        ])
        // Mixpanel - End
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    // UISearchBarDelegate
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        self.navigationController?.popViewControllerAnimated(false)
        
        return true
    }
    
    func backTapped(sender: UIBarButtonItem) {
        var childrenCount = self.navigationController!.viewControllers.count
        var feedChild: AnyObject = self.navigationController!.viewControllers[childrenCount-3]
        
        UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.popToViewController(feedChild as! UIViewController, animated: false)
            }, completion: nil)
    }
}

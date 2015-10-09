//
//  SearchViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 3/9/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class SearchViewController: UIViewController, UISearchBarDelegate {

    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    var searchBar: UISearchBar?
    var searchString: String = ""
    
    var activityView: UIActivityIndicatorView!
    
    var scopeButtonTitles = ["Outfits", "Items", "People"]
    var currentScope = 0
    var fromRecommendSimilar = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
	}

    override func viewWillAppear(animated: Bool) {
	    super.viewWillAppear(animated)
        
        containerViewController.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        initNavBar()
        
        if fromRecommendSimilar {
            searchBar?.userInteractionEnabled = false
            searchBarSearchButtonClicked(searchBar!)
        }
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	}
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeaderAndStatusbarHeight + navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        newNavBar.backgroundColor = UIColor.whiteColor()
        newNavBar.translucent = false
        
        // 3. add a new navigation item w/title to the new nav bar
        let searchBarContainer = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight * 2))
        searchBarContainer.backgroundColor = UIColor.whiteColor()
        searchBarContainer.userInteractionEnabled = true
        
        searchBar = UISearchBar(frame: CGRectMake(0, 0, screenWidth - 10, navigationHeight))
        searchBar?.barTintColor = UIColor.whiteColor()
        searchBar?.backgroundColor = UIColor.whiteColor()
        searchBar?.setBackgroundImage(UIImage(), forBarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
        searchBar?.delegate = self

        searchBar?.text = searchString
        searchBar?.scopeButtonTitles = scopeButtonTitles
        searchBar?.showsScopeBar = true
        searchBar?.selectedScopeButtonIndex = currentScope
        searchBar?.showsCancelButton = true

        searchBar?.becomeFirstResponder()
        searchBar?.sizeToFit()
        
        searchBarContainer.addSubview(searchBar!)
        
        newNavItem = UINavigationItem()
        newNavItem.titleView = searchBarContainer
        newNavItem.titleView?.userInteractionEnabled = true
        newNavBar.setTitleVerticalPositionAdjustment(-statusbarHeight - 2, forBarMetrics: UIBarMetrics.Default)
        
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
        
        //newNavItem.leftBarButtonItem = backBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: screenHeight / 2 - activityViewWidth / 2, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
    }

    // UISearchBarDelegate
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {

        currentScope = selectedScope
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismissSearchViewController()
	}
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchString = searchBar.text
        
        var searchURL: String!
        var params: NSMutableDictionary = NSMutableDictionary()
        
        switch currentScope {
        case 0:
            // Outfits
            searchURL = "/outfits/search"
        case 1:
            // Pieces
            searchURL = "/pieces/search"
        case 2:
            // Users
            searchURL = "/users/search"
        default:
            fatalError("Unknown scope in SearchViewController")
        }
        
        params.setObject(searchString, forKey: "full_text")
        
        activityView.startAnimating()
        
        // REST call to server to retrieve results
        manager.POST(SprubixConfig.URL.api + searchURL,
            parameters: params,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.activityView.stopAnimating()
                
                println(responseObject)
                
                if self.currentScope != 2 {
                    // instantiate results view controller
                    let searchResultsViewController = SearchResultsViewController()
                    
                    searchResultsViewController.searchString = self.searchString
                    searchResultsViewController.searchURL = searchURL
                    searchResultsViewController.currentScope = self.currentScope
                    searchResultsViewController.results = responseObject["data"] as! [NSDictionary]
                    searchResultsViewController.currentPage = responseObject["current_page"] as? Int
                    searchResultsViewController.lastPage = responseObject["last_page"] as? Int
                    
                    self.navigationController?.delegate = nil
                    self.navigationController?.pushViewController(searchResultsViewController, animated: true)
                } else {
                    // instantiate users results view controller
                    let searchResultsUsersViewController = UIStoryboard.searchResultsUsersViewController()
                    
                    searchResultsUsersViewController!.searchString = self.searchString
                    searchResultsUsersViewController!.searchURL = searchURL
                    searchResultsUsersViewController!.results = responseObject["data"] as! [NSDictionary]
                    searchResultsUsersViewController!.currentPage = responseObject["current_page"] as? Int
                    searchResultsUsersViewController!.lastPage = responseObject["last_page"] as? Int
                    
                    self.navigationController?.delegate = nil
                    self.navigationController?.pushViewController(searchResultsUsersViewController!, animated: true)
                }
                
                self.searchBar?.userInteractionEnabled = true
                self.fromRecommendSimilar = false
                
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                self.activityView.stopAnimating()
        })
        
        // Mixpanel - Search
        var searchType = ""
        
        switch currentScope {
        case 0:
            searchType = "Outfit"
        case 1:
            searchType = "Piece"
        case 2:
            searchType = "People"
        default:
            searchType = ""
        }
        
        mixpanel.track("Search", properties: [
            "Type": searchType,
            "Keyword": searchString
        ])
        // Mixpanel - End
    }

    private func dismissSearchViewController() {
	    UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
	        self.navigationController?.popViewControllerAnimated(false)
	        }, completion: nil)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        dismissSearchViewController()
    }
}
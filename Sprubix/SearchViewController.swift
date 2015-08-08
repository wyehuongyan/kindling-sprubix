//
//  SearchViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 3/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController,  UISearchResultsUpdating, UISearchBarDelegate {
    
    var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        if searchController == nil {
            searchController = UISearchController()
            
            searchController = UISearchController(searchResultsController: nil)
            searchController!.searchBar.delegate = self
            searchController?.searchBar.barTintColor = sprubixLightGray
            searchController!.searchResultsUpdater = self
            searchController!.dimsBackgroundDuringPresentation = true
            searchController!.hidesNavigationBarDuringPresentation = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        containerViewController.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.presentViewController(searchController!, animated: true, completion: nil)
    }
    
    // UISearchResultsUpdating Protocol
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        var searchString = searchController.searchBar.text
        
        println(searchString)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.popViewControllerAnimated(false)
            }, completion: nil)
    }
}

//
//  SearchViewController.swift
//  Sprubix
//
//  Created by Shion Wah on 1/9/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    var searchController: UISearchController!
    var filterTableView: UITableView!
    let searchCellIdentifier: String = "searchCell"
    
    let scopeTitles: [String] = ["Outfits", "Items", "People"]
    var filteredData: [String]!
    
    var outfitData: [String] = ["Red", "Blue", "Denim", "Summer", "Party"]
    var pieceData: [String] = ["Hats", "Top", "Crop Top", "Skirts", "Shorts", "Shoes", "Black"]
    var peopleData: [String] = ["sprubixshop", "cameron", "tingzhi", "cecilia"]
    
    var selectedScopeIndex: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        filteredData = outfitData

        if searchController == nil {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false
            
            searchController.searchBar.delegate = self
            searchController.searchBar.barTintColor = sprubixLightGray
            
            // adjust searchbar
            searchController.searchBar.scopeButtonTitles = scopeTitles
            searchController.searchBar.selectedScopeButtonIndex = 0
            searchController.searchBar.sizeToFit()
        }
        
        let filterTableViewY: CGFloat = 44
        filterTableView = UITableView(frame: CGRect(x: 0, y: filterTableViewY, width: screenWidth, height: screenHeight))
        filterTableView.dataSource = self
        filterTableView.delegate = self
        filterTableView.backgroundColor = UIColor.whiteColor()
        filterTableView.tableFooterView = UIView(frame: CGRectZero)
        filterTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: searchCellIdentifier)
        
        view.addSubview(filterTableView)
        
        self.definesPresentationContext = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        searchController.searchBar.becomeFirstResponder()
        containerViewController.statusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        println(self.navigationController?.viewControllers)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // adjust searchbar
        searchController.searchBar.scopeButtonTitles = scopeTitles
        searchController.searchBar.selectedScopeButtonIndex = 0
        searchController.searchBar.sizeToFit()
        
        if !searchController.active {
            self.presentViewController(searchController!, animated: true, completion: nil)
        }
    }
    
    // UISearchResultsUpdating Protocol
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        var searchString = searchController.searchBar.text
        
        switch (searchController.searchBar.selectedScopeButtonIndex) {
        case 0:
            filteredData = searchString.isEmpty ? outfitData : outfitData.filter({(dataString: String) -> Bool in
                return dataString.rangeOfString(searchString, options: .CaseInsensitiveSearch) != nil
            })
            
        case 1:
            filteredData = searchString.isEmpty ? pieceData : pieceData.filter({(dataString: String) -> Bool in
                return dataString.rangeOfString(searchString, options: .CaseInsensitiveSearch) != nil
            })
            
        case 2:
            filteredData = searchString.isEmpty ? peopleData : peopleData.filter({(dataString: String) -> Bool in
                return dataString.rangeOfString(searchString, options: .CaseInsensitiveSearch) != nil
            })
            
        default:
            break
        }
        
        filterTableView.reloadData()
    }
    
    // UISearchBarDelegate
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        
        dismissSearchViewController()
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0:
            filteredData = outfitData
        case 1:
            filteredData = pieceData
        case 2:
            filteredData = peopleData
        default:
            break
        }
        
        filterTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        search()
    }
    
    private func dismissSearchViewController() {
        searchController.searchBar.scopeButtonTitles = nil
        
        UIView.transitionWithView(self.navigationController!.view, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.navigationController?.popViewControllerAnimated(false)
            }, completion: nil)
    }
    
    // UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(searchCellIdentifier) as! UITableViewCell
        cell.textLabel?.text = filteredData[indexPath.row]
        cell.textLabel?.textColor = UIColor.darkGrayColor()
        cell.backgroundColor = UIColor.whiteColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        searchController.searchBar.text = filteredData[indexPath.row]
        
        search()
    }
    
    func search() {
        selectedScopeIndex = searchController.searchBar.selectedScopeButtonIndex
        
        println("Search Scope: \(scopeTitles[selectedScopeIndex]) , Text: \(searchController.searchBar.text)")
        showSearchResultsView()
    }
    
    func showSearchResultsView() {
        // adjust searchbar
        searchController.searchBar.scopeButtonTitles = nil
        searchController.searchBar.sizeToFit()
        searchController.searchBar.resignFirstResponder()
        
        var searchResultsViewController = SearchResultsViewController()
        
        switch (selectedScopeIndex) {
        case 0:
            searchResultsViewController.currentScopeState = ScopeState.Outfits
        case 1:
            searchResultsViewController.currentScopeState = ScopeState.Pieces
        case 2:
            searchResultsViewController.currentScopeState = ScopeState.People
        default:
            break
        }
        
        searchResultsViewController.fullTextSearchString = searchController.searchBar.text
        self.navigationController?.pushViewController(searchResultsViewController, animated: true)
    }
}

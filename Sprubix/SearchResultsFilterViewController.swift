//
//  SearchResultsFilterViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 4/9/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol CategoryFilterProtocol {
    func categorySelected(category: NSDictionary?)
}

class SearchResultsFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var delegate: CategoryFilterProtocol?
    var categories: [NSDictionary] = [NSDictionary]()
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var filterCategoriesTableView: UITableView!
    var selectedIndexPath: NSIndexPath?
    var selectedCategory: NSDictionary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        view.backgroundColor = sprubixColor
        
        initTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    func initTableView() {
        filterCategoriesTableView = UITableView(frame: CGRectMake(0, navigationHeaderAndStatusbarHeight, screenWidth, screenHeight - navigationHeaderAndStatusbarHeight))
        
        filterCategoriesTableView.backgroundColor = UIColor.whiteColor()
        filterCategoriesTableView.dataSource = self
        filterCategoriesTableView.delegate = self
        
        filterCategoriesTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(filterCategoriesTableView)
    }
    
    func initNavBar() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeaderAndStatusbarHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Filter Categories"
        
        // 4. create a custom back button
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        cancelButton.frame = CGRect(x: -10, y: 0, width: 60, height: 20)
        cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
        cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: "cancelTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.exclusiveTouch = true
        
        var cancelBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: cancelButton)
        cancelBarButtonItem.tintColor = sprubixColor
        
        newNavItem.rightBarButtonItem = cancelBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        
        var category = categories[indexPath.row]
        
        cell.textLabel?.text = category["name"] as? String
        
        if selectedIndexPath != nil && indexPath == selectedIndexPath {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // update to latest selected indexpath
        selectedIndexPath = indexPath
        selectedCategory = categories[indexPath.row]
    
        delegate?.categorySelected(selectedCategory)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func cancelTapped(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

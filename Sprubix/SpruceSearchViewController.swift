//
//  SpruceSearchViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 16/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AMTagListView

class SpruceSearchViewController: UIViewController, UITextFieldDelegate {
    
    let searchBarViewHeight: CGFloat = 34
    let searchBarTextFieldHeight: CGFloat = 24
    let toolBarHeight: CGFloat = 70
    
    var searchBarTextField: UITextField!
    var searchBarPlaceholderText: String = "Hi! What are you looking for?"
    
    // tag list view
    var tagListView: AMTagListView!
    
    var pieceTypes: [String] = ["HEAD", "TOP", "BOTTOM", "FEET"]
    var pieceTypeButtons: [UIButton] = [UIButton]()
    
    // selected
    var selectedPieceTypes: [String: Bool] = ["HEAD": false, "TOP": false, "BOTTOM": false, "FEET": false]
    
    var selectedPieces: [NSDictionary] = [NSDictionary]()
    var selectedPieceIds: NSMutableArray = NSMutableArray()
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        initToolbar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        searchBarTextField.becomeFirstResponder()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Search"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        //var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        //backButton.setImage(image, forState: UIControlState.Normal)
        backButton.setTitle("X", forState: UIControlState.Normal)
        backButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("search", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "searchTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initToolbar() {
        // search bar
        let searchBarView = UIView(frame: CGRectMake(0, navigationHeight, screenWidth, searchBarViewHeight))
        
        searchBarView.backgroundColor = sprubixLightGray
        
        searchBarTextField = UITextField(frame: CGRectMake(10, 10, screenWidth - 20, searchBarTextFieldHeight))
        
        searchBarTextField.placeholder = searchBarPlaceholderText
        searchBarTextField.backgroundColor = UIColor.whiteColor()
        searchBarTextField.layer.cornerRadius = 3.0
        searchBarTextField.textColor = UIColor.darkGrayColor()
        searchBarTextField.tintColor = sprubixColor
        searchBarTextField.font = UIFont.systemFontOfSize(15.0)
        //searchBarTextField.textContainerInset = UIEdgeInsetsMake(3, 3, 0, 0);
        searchBarTextField.delegate = self
        searchBarTextField.textAlignment = NSTextAlignment.Center
        
        searchBarView.addSubview(searchBarTextField)
        
        view.addSubview(searchBarView)
        
        // tool bar
        let pieceTypeFilterScrollView = UIScrollView(frame: CGRectMake(0, navigationHeight + searchBarViewHeight, screenWidth, toolBarHeight))
        pieceTypeFilterScrollView.backgroundColor = sprubixLightGray
        
        var prevButtonPos: CGFloat = 0
        let pieceTypeButtonWidth: CGFloat = 50
        let buttonPadding: CGFloat = (screenWidth - (CGFloat(pieceTypes.count) * pieceTypeButtonWidth)) / (CGFloat(pieceTypes.count) + 1)
        
        // create buttons for each piece type
        for var i = 0; i < pieceTypes.count; i++ {
            var pieceType = pieceTypes[i]
            
            let pieceTypeButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            
            let image: UIImage = UIImage(named: getButtonImage(pieceType))!
            pieceTypeButton.frame = CGRectMake(buttonPadding + prevButtonPos, 10, pieceTypeButtonWidth, pieceTypeButtonWidth)
            pieceTypeButton.setImage(image, forState: UIControlState.Normal)
            pieceTypeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            pieceTypeButton.backgroundColor = UIColor.lightGrayColor()
            pieceTypeButton.layer.cornerRadius = pieceTypeButtonWidth / 2
            pieceTypeButton.exclusiveTouch = true
            pieceTypeButton.addTarget(self, action: "pieceTypeButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            
            prevButtonPos = pieceTypeButton.frame.origin.x + pieceTypeButton.frame.size.width
            
            pieceTypeFilterScrollView.addSubview(pieceTypeButton)
            pieceTypeButtons.append(pieceTypeButton)
        }
        
        view.addSubview(pieceTypeFilterScrollView)
        
        // AMTagListView
        tagListView = AMTagListView(frame: CGRectMake(0, navigationHeight + toolBarHeight + searchBarViewHeight, screenWidth, screenHeight - navigationHeight - toolBarHeight - searchBarViewHeight))
        
        tagListView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        
        AMTagView.appearance().tagLength = 10
        AMTagView.appearance().textPadding = 14
        AMTagView.appearance().textFont = UIFont.boldSystemFontOfSize(17)
        AMTagView.appearance().tagColor = sprubixColor
        
        tagListView.backgroundColor = UIColor.whiteColor()
        
        tagListView.setTapHandler { (amTagView) -> Void in
            self.tagListView.removeTag(amTagView)
        }
        
        view.addSubview(tagListView)
    }
    
    private func getButtonImage(pieceType: String) -> String {
        switch(pieceType) {
        case "HEAD":
            return "view-item-cat-head"
        case "TOP":
            return "view-item-cat-top"
        case "BOTTOM":
            return "view-item-cat-bot"
        case "FEET":
            return "view-item-cat-feet"
        default:
            fatalError("Error: Unknown piece type, unable to return button image string.")
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
            var textData = split(textField.text) {$0 == " "}
            
            if textData.count > 1 {
                for text in textData {
                    self.tagListView.addTag(text)
                }
            } else {
                self.tagListView.addTag(textField.text)
            }
            
            textField.text = ""
        }
        
        return false;
    }
    
    // nav bar button callbacks
    func searchTapped(sender: UIBarButtonItem) {
        textFieldShouldReturn(searchBarTextField) // flush any text in the textfield into tagListView
        
        if tagListView.tags.count > 0 {
            let searchTags = tagListView.tags
            
            let spruceSearchResultsViewController = SpruceSearchResultsViewController()
            
            for searchTag in searchTags {
                spruceSearchResultsViewController.searchTagStrings.append(searchTag.tagText())
            }
            
            for (key, value) in selectedPieceTypes {
                if value == true {
                    spruceSearchResultsViewController.types.append(key)
                }
            }
            
            // get spruceViewController
            let spruceViewController: SpruceViewController = self.navigationController?.viewControllers[self.navigationController!.viewControllers.count - 2] as! SpruceViewController
            
            spruceSearchResultsViewController.delegate = spruceViewController
            
            self.navigationController?.pushViewController(spruceSearchResultsViewController, animated: true)
        } else {
            println("Please enter one or more search terms")
        }
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.delegate = nil
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromBottom
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
        self.navigationController?.popViewControllerAnimated(false)
    }
    
    // piece type filter button callback
    func pieceTypeButtonTapped(sender: UIButton) {
        let pos = find(pieceTypeButtons, sender)
        
        let pieceType = pieceTypes[pos!]
        
        if sender.selected != true {
            sender.backgroundColor = sprubixColor
            sender.selected = true
            selectedPieceTypes[pieceType] = true
        } else {
            sender.backgroundColor = UIColor.lightGrayColor()
            sender.selected = false
            selectedPieceTypes[pieceType] = false
        }
    }
}

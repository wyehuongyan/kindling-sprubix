//
//  SnapshotDetailsSizeController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 29/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AMTagListView

protocol AddMoreSizesProtocol {
    func setMoreSizes(sizes: NSArray)
}

class SnapshotDetailsSizeController: UIViewController, UITextFieldDelegate {

    var pieceSizesArray: NSArray?
    var delegate: AddMoreSizesProtocol?
    
    let addSizeViewHeight: CGFloat = 44
    let addSizeTextFieldHeight: CGFloat = 24
    var addSizeTextField: UITextField!
    
    // tag list view
    var tagListView: AMTagListView!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initToolBar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        
        self.tagListView.removeAllTags()
        
        if pieceSizesArray != nil {
            self.tagListView.addTags(pieceSizesArray as! [String])
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        addSizeTextField.becomeFirstResponder()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Add Size"
        
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
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("done", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "doneTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func initToolBar() {
        // search bar
        let addSizeView = UIView(frame: CGRectMake(0, navigationHeight, screenWidth, addSizeViewHeight))
        
        addSizeView.backgroundColor = sprubixLightGray
        
        addSizeTextField = UITextField(frame: CGRectMake(10, 10, screenWidth - 20, addSizeTextFieldHeight))
        
        addSizeTextField.placeholder = "Press return to add another!"
        addSizeTextField.backgroundColor = UIColor.whiteColor()
        addSizeTextField.layer.cornerRadius = 3.0
        addSizeTextField.textColor = UIColor.darkGrayColor()
        addSizeTextField.tintColor = sprubixColor
        addSizeTextField.font = UIFont.systemFontOfSize(15.0)
        //searchBarTextField.textContainerInset = UIEdgeInsetsMake(3, 3, 0, 0);
        addSizeTextField.delegate = self
        addSizeTextField.textAlignment = NSTextAlignment.Center
        
        addSizeView.addSubview(addSizeTextField)
        
        view.addSubview(addSizeView)
        
        // AMTagListView
        tagListView = AMTagListView(frame: CGRectMake(0, navigationHeight + addSizeViewHeight, screenWidth, screenHeight - navigationHeight - addSizeViewHeight))
        
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
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
            
            self.tagListView.addTag(textField.text)
            
            textField.text = ""
        }
        
        return false;
    }
    
    // nav bar button callbacks
    func doneTapped(sender: UIBarButtonItem) {
        textFieldShouldReturn(addSizeTextField) // flush any text in the textfield into tagListView
        
        let searchTags = tagListView.tags
        var sizes = NSMutableArray()
        
        for searchTag in searchTags {
            sizes.addObject(searchTag.tagText())
        }
        
        delegate?.setMoreSizes(sizes)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

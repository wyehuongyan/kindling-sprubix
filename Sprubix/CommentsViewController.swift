//
//  CommentsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 29/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CommentsViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var prevViewIsOutfit: Bool = false
    var makeKeyboardVisible = true
    var showKeyboard = false
    var placeholderText: String = "Add a comment..."
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    let commentCellIdentifier: String = "CommentCell"
    var comments: [NSDictionary] = [NSDictionary]()
    
    @IBAction func sendComment(sender: AnyObject) {
    }
    
    @IBOutlet var commentTextView: UITextView!
    @IBOutlet var commentView: UIView!
    @IBOutlet var commentsTableView: UITableView!
    
    // constraints
    @IBOutlet var commentsTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var commentViewBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        commentTextView.delegate = self
        commentTextView.tintColor = sprubixColor
        commentTextView.textContainerInset = UIEdgeInsetsMake(3, 3, 0, 0);
        
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.rowHeight = UITableViewAutomaticDimension
        
        // gesture recognizer on tableview to dismiss keyboard on tap
        var dismissKeyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        
        dismissKeyboardTap.numberOfTapsRequired = 1
        dismissKeyboardTap.cancelsTouchesInView = false
        
        commentsTableView.addGestureRecognizer(dismissKeyboardTap)
        
        // keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChange:"), name:UIKeyboardWillChangeFrameNotification, object: nil);
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if showKeyboard == true {
            commentTextView.becomeFirstResponder()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if prevViewIsOutfit == true {
            self.navigationController?.delegate = transitionDelegateHolder
        }
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Comments"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(commentCellIdentifier, forIndexPath: indexPath) as! CommentCell
        
        return cell
    }
    
    /**
    * Handler for keyboard change event
    */
    func keyboardWillChange(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        if makeKeyboardVisible {
            println("keyboard will change \(keyboardFrame.height)")
            
            commentsTableViewBottomConstraint.constant = keyboardFrame.height
            commentViewBottomConstraint.constant = keyboardFrame.height
            
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: { finished in
                    if finished {
                    }
            })
        } else {
            println("keyboard will hide")
            
            commentsTableViewBottomConstraint.constant -= keyboardFrame.height
            commentViewBottomConstraint.constant -= keyboardFrame.height
            
            view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: { finished in
                    if finished {
                        self.makeKeyboardVisible = true
                    }
            })
        }
    }
    
    // gesture recognizer callbacks
    func dismissKeyboard(gesture: UITapGestureRecognizer) {
        makeKeyboardVisible = false
        
        self.view.endEditing(true)
    }
    
    // UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView.text == placeholderText {
            commentTextView.text = ""
            commentTextView.textColor = UIColor.darkGrayColor()
        }
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            commentTextView.text = placeholderText
            commentTextView.textColor = UIColor.lightGrayColor()
            commentTextView.resignFirstResponder()
        }
    }

    // button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

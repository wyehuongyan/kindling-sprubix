//
//  SpruceShareViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 29/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SpruceShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let creditsViewHeight:CGFloat = 80
    
    var spruceShareTableView:UITableView!
    var outfitImageView:UIImageView! = UIImageView()
    var descriptionCellText: String = ""
    
    var outfitImageCell: UITableViewCell = UITableViewCell()
    var creditsCell: UITableViewCell = UITableViewCell()
    var descriptionCell: UITableViewCell = UITableViewCell()
    var socialCell: UITableViewCell = UITableViewCell()
    
    var shareButton: UIButton!
    
    var lastContentOffset:CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        
        spruceShareTableView = UITableView(frame: CGRect(x: 0, y: navigationHeight, width: screenWidth, height: screenHeight - navigationHeight), style: UITableViewStyle.Plain)
        spruceShareTableView.delegate = self
        spruceShareTableView.dataSource = self
        spruceShareTableView.showsVerticalScrollIndicator = false
        spruceShareTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        view.addSubview(spruceShareTableView)
        
        shareButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
        shareButton.backgroundColor = sprubixColor
        shareButton.setTitle("Spruce it!", forState: UIControlState.Normal)
        
        view.addSubview(shareButton)
    }
    
    override func viewWillAppear(animated: Bool) {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        var newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        var newNavItem = UINavigationItem()
        newNavItem.title = "Good to go?"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        backButton.setImage(UIImage(named: "spruce-arrow-back"), forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        Glow.addGlow(backButton)
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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var currentDistanceMoved:CGFloat = 0
        
        if lastContentOffset > scrollView.contentOffset.y {
            // up
            currentDistanceMoved = lastContentOffset - scrollView.contentOffset.y
            
            outfitImageView.frame.origin.y -= currentDistanceMoved * 0.8
            
        } else if lastContentOffset < scrollView.contentOffset.y {
            // down
            currentDistanceMoved = scrollView.contentOffset.y - lastContentOffset

            outfitImageView.frame.origin.y += currentDistanceMoved * 0.8
        }

        lastContentOffset = scrollView.contentOffset.y
        
        // if image gets covered by bottom cells it goes haywire, 400 = imageheight - 100
        if scrollView.contentOffset.y >= outfitImageView.frame.size.height {
            scrollView.contentOffset.y = outfitImageView.frame.size.height
        } else if scrollView.contentOffset.y <= 0 {
            scrollView.contentOffset.y = 0
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight : CGFloat!
        
        switch(indexPath.row)
        {
        case 0:
            cellHeight = outfitImageView.frame.size.height
        case 1:
            cellHeight = creditsViewHeight // creditsViewHeight
        case 2:
            if descriptionCellText != "" {
                cellHeight = heightForTextLabel(descriptionCellText, width: screenWidth, padding: 20) // description height
            } else {
                cellHeight = 0
            }
        case 3:
            cellHeight = 200 // social share
        default:
            cellHeight = 300
        }
        
        return cellHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch(indexPath.row)
        {
        case 0:
            //outfitImageView = UIImageView(image: UIImage(named: "person-placeholder.jpg"))
            //outfitImageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 500)
            outfitImageView.clipsToBounds = true
            outfitImageView.contentMode = UIViewContentMode.ScaleAspectFill
            
            outfitImageCell.addSubview(outfitImageView)
            outfitImageCell.clipsToBounds = true
            
            return outfitImageCell
        case 1:
            // init 'posted by' and 'from' credits
            var creditsView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: creditsViewHeight))
            
            var postedByButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "posted by", username: "user name")
            var fromButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "from", username: "user name")
            
            creditsView.addSubview(postedByButton)
            creditsView.addSubview(fromButton)
            
            creditsCell.addSubview(creditsView)
            
            return creditsCell
        case 2:
            descriptionCell.textLabel?.text = descriptionCellText
            
            descriptionCell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
            descriptionCell.textLabel?.numberOfLines = 0
            descriptionCell.userInteractionEnabled = false
            
            return descriptionCell
        case 3:
            // Facebook
            var socialButtonRow1:UIView = UIView(frame: CGRect(x: 0, y: 10, width: screenWidth, height: 44))
            
            var socialButtonFacebook = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
            socialButtonFacebook.setImage(UIImage(named: "spruce-share-fb"), forState: UIControlState.Normal)
            socialButtonFacebook.setTitle("Facebook", forState: UIControlState.Normal)
            socialButtonFacebook.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            socialButtonFacebook.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonFacebook.frame = CGRect(x: 0, y: 0, width: screenWidth / 2, height: 44)
            socialButtonFacebook.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonFacebook.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonFacebook.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)
        
            socialButtonRow1.addSubview(socialButtonFacebook)
            
            // Twitter
            var socialButtonTwitter = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
            socialButtonTwitter.setImage(UIImage(named: "spruce-share-twitter"), forState: UIControlState.Normal)
            socialButtonTwitter.setTitle("Twitter", forState: UIControlState.Normal)
            socialButtonTwitter.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            socialButtonTwitter.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonTwitter.frame = CGRect(x: screenWidth / 2, y: 0, width: screenWidth / 2, height: 44)
            socialButtonTwitter.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonTwitter.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonTwitter.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)
        
            socialButtonRow1.addSubview(socialButtonTwitter)
            
            socialCell.addSubview(socialButtonRow1)
            
            // Tumblr
            var socialButtonRow2:UIView = UIView(frame: CGRect(x: 0, y: 54, width: screenWidth, height: 44))
            
            var socialButtonTumblr = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
            socialButtonTumblr.setImage(UIImage(named: "spruce-share-tumblr"), forState: UIControlState.Normal)
            socialButtonTumblr.setTitle("Tumblr", forState: UIControlState.Normal)
            socialButtonTumblr.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            socialButtonTumblr.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonTumblr.frame = CGRect(x: 0, y: 0, width: screenWidth / 2, height: 44)
            socialButtonTumblr.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonTumblr.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonTumblr.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)

            socialButtonRow2.addSubview(socialButtonTumblr)
        
            // Pinterest
            var socialButtonPinterest = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
            socialButtonPinterest.setImage(UIImage(named: "spruce-share-pinterest"), forState: UIControlState.Normal)
            socialButtonPinterest.setTitle("Pinterest", forState: UIControlState.Normal)
            socialButtonPinterest.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            socialButtonPinterest.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonPinterest.frame = CGRect(x: screenWidth / 2, y: 0, width: screenWidth / 2, height: 44)
            socialButtonPinterest.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonPinterest.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
            socialButtonPinterest.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)
            
            socialButtonRow2.addSubview(socialButtonPinterest)
            
            socialCell.addSubview(socialButtonRow2)
        
            var socialButtonsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
            socialButtonsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            socialCell.addSubview(socialButtonsLineTop)
            
            return socialCell
        default: fatalError("Unknown row in section")
        }
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
        //delegate?.dismissSpruceView()
    }
    
    func heightForTextLabel(text:String, width:CGFloat, padding: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.text = text
        
        label.sizeToFit()
        return label.frame.height + padding
    }
}

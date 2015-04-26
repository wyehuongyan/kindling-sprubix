//
//  Subclasses.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 19/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate{
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let transition = Transition()
        transition.presenting = operation == .Pop
        
        return transition
    }
}

let transitionDelegateHolder = NavigationControllerDelegate()

class SprubixItemCommentRow: UIView {
    var commentRowHeight:CGFloat!
    var postCommentButton:UIButton!
    
    let commentRowPaddingBottom:CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(username:String, commentString:String, y: CGFloat, button: Bool, userThumbnail:String = "person-placeholder.jpg") {
        self.init()
        
        var commentRowView = self
        
        self.backgroundColor = UIColor.whiteColor()
        let commentImageViewWidth:CGFloat = 35
        
        // commenter's image
        var commentImageView:UIImageView = UIImageView(frame: CGRect(x: 20, y: 0, width: commentImageViewWidth, height: commentImageViewWidth))

        if userThumbnail != "sprubix-user" {
            commentImageView.image = UIImage(named: userThumbnail)
        } else {
            let userData:NSDictionary! = defaults.dictionaryForKey("userData")
            
            // create profile UIImageView programmatically
            let userThumbnailURL = NSURL(string: userData["image"] as! String)
            
            commentImageView.setImageWithURL(userThumbnailURL)
        }
        
        // circle mask
        commentImageView.layer.cornerRadius = commentImageView.frame.size.width / 2
        commentImageView.clipsToBounds = true
        commentImageView.layer.borderWidth = 1.0
        commentImageView.layer.borderColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1).CGColor
        
        commentRowView.addSubview(commentImageView)
        
        if button {
            postCommentButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
            postCommentButton.frame = CGRect(x: commentImageViewWidth + 28, y: 0, width: screenWidth - (commentImageViewWidth + 50), height: commentImageViewWidth)
            postCommentButton.setTitle("Add a comment", forState: UIControlState.Normal)
            postCommentButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            postCommentButton.backgroundColor = sprubixColor
            postCommentButton.exclusiveTouch = true
            
            commentRowView.addSubview(postCommentButton)
            
            commentRowHeight = postCommentButton.frame.height + commentRowPaddingBottom
            
            commentRowView.frame = CGRect(x: 0, y: y, width: screenWidth, height: commentRowHeight)
            
        } else {
            // commenter's nickname
            let commentUsernameHeight:CGFloat = 21
            var commentUsername:UILabel = UILabel(frame: CGRect(x: commentImageViewWidth + 28, y: 0, width: screenWidth - (commentImageViewWidth + 28), height: commentUsernameHeight))
            commentUsername.textColor = tintColor
            commentUsername.text = username
            
            commentRowView.addSubview(commentUsername)
            
            // comment
            var comment:UILabel = UILabel()
            comment.lineBreakMode = NSLineBreakMode.ByWordWrapping
            comment.numberOfLines = 0
            comment.text = commentString
            
            let commentHeight = heightForTextLabel(comment.text!, font: comment.font, width: screenWidth - (commentImageViewWidth + 40), hasInsets: false)
            comment.frame = CGRect(x: commentImageViewWidth + 28, y: 18, width: screenWidth - (commentImageViewWidth + 40), height: commentHeight)
            
            commentRowView.addSubview(comment)
            
            commentRowHeight = commentUsernameHeight + commentHeight + commentRowPaddingBottom
            
            commentRowView.frame = CGRect(x: 0, y: y, width: screenWidth, height: commentRowHeight)
        }
    }
    
    func heightForTextLabel(text:String, font:UIFont, width:CGFloat, hasInsets:Bool) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return hasInsets ? label.frame.height + 70 : label.frame.height // + 70 because of the custom insets from SprubixItemDescription
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SprubixItemDescription: UILabel {
    override func drawTextInRect(rect: CGRect) {
        let insets:UIEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}

class SprubixHandleBarSeperator: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, handleWidth: CGFloat, lineStroke: CGFloat, glow: Bool = true, opacity: CGFloat = 1.0) {
        super.init(frame: frame)
        
        // seperator line
        var seperatorLineTop: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: lineStroke))
        seperatorLineTop.backgroundColor = UIColor.whiteColor()
        seperatorLineTop.alpha = opacity
        
        self.addSubview(seperatorLineTop)
        
        // handlebar
        let handleBarWidth: CGFloat = handleWidth
        let handleBarHeight: CGFloat = 5.0 + lineStroke
        var handleBar: UIView = UIView(frame: CGRectMake(self.frame.width / 2 - handleBarWidth / 2, lineStroke / 2 - handleBarHeight / 2, handleBarWidth, handleBarHeight))
        handleBar.backgroundColor = UIColor.whiteColor()
        handleBar.layer.cornerRadius = handleBarHeight / 2
        handleBar.alpha = opacity
        
        self.addSubview(handleBar)
        
        if glow != false {
            Glow.addGlow(seperatorLineTop)
            Glow.addGlow(handleBar)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SprubixCreditButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, buttonLabel: String, username: String, userThumbnail: String = "person-placeholder.jpg") {
        super.init(frame:frame)
        
        // the button
        self.autoresizesSubviews = true
        self.backgroundColor = UIColor.whiteColor()
        self.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        self.exclusiveTouch = true
        
        // profile pic inside button
        var creditImageView: UIImageView = UIImageView()
        
        if userThumbnail == "person-placeholder.jpg" {
            creditImageView.image = UIImage(named: userThumbnail)
        } else {
            // create profile UIImageView programmatically
            let userThumbnailURL = NSURL(string: userThumbnail)
            creditImageView.setImageWithURL(userThumbnailURL)
        }
        
        let creditImageViewWidth:CGFloat = 35
        creditImageView.frame = CGRect(x: 20, y: (self.frame.height/2) - creditImageViewWidth/2, width: creditImageViewWidth, height: creditImageViewWidth)
        
        // circle mask
        creditImageView.layer.cornerRadius = creditImageView.frame.size.width / 2
        creditImageView.clipsToBounds = true
        creditImageView.layer.borderWidth = 1.0
        creditImageView.layer.borderColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1).CGColor
        
        self.addSubview(creditImageView)
        
        // UILines on top and buttom of button
        var buttonLineBottom = UIView(frame: CGRect(x: 0, y: self.frame.height - 10.0, width: self.frame.width, height: 10))
        buttonLineBottom.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        var buttonLineTop = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 10))
        buttonLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        self.addSubview(buttonLineTop)
        self.addSubview(buttonLineBottom)
        
        // labels 'posted by'/'from' and user name below
        var buttonLabelTopHeight:CGFloat = 20
        var buttonLabelTop:UILabel = UILabel(frame: CGRect(x: creditImageViewWidth + 28, y: buttonLabelTopHeight, width: self.frame.width - creditImageViewWidth + 20, height: 21))
        buttonLabelTop.font = UIFont(name: buttonLabelTop.font.fontName, size: 13)
        buttonLabelTop.textColor = UIColor.lightGrayColor()
        buttonLabelTop.text = buttonLabel
        
        var buttonLabelBottom:UILabel = UILabel(frame: CGRect(x: creditImageViewWidth + 28, y: buttonLabelTopHeight + 18, width: self.frame.width - creditImageViewWidth + 20, height: 21))
        buttonLabelBottom.font = UIFont(name: buttonLabelTop.font.fontName, size: 13)
        buttonLabelBottom.text = username
        
        self.addSubview(buttonLabelTop)
        self.addSubview(buttonLabelBottom)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Glow {
    class func addGlow(item: AnyObject) {
        item.layer.shadowColor = UIColor.blackColor().CGColor
        item.layer.shadowOpacity = 0.8
        item.layer.shadowRadius = 1
        item.layer.shadowOffset = CGSizeZero
        item.layer.masksToBounds = false
    }
}
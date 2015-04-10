//
//  SprubixFeedCommentsController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 20/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol SprubixFeedCommentsProtocol {
    func dismissCommentsView()
}

class SprubixFeedCommentsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var delegate: SprubixFeedCommentsProtocol?
    
    var descriptionCommentsDismissView: UIView!
    var descriptionCommentsTableView: UITableView!
    
    var descriptionCell: UITableViewCell = UITableViewCell()
    var commentsCell: UITableViewCell = UITableViewCell()
    
    let descriptionCommentsHeight:CGFloat = screenHeight - screenHeight/4
    
    override func viewDidLoad() {
        // create all the ui elements
        view.backgroundColor = UIColor.clearColor()
        
        descriptionCommentsDismissView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight - descriptionCommentsHeight))
        descriptionCommentsDismissView.backgroundColor = UIColor.clearColor()
        descriptionCommentsDismissView.userInteractionEnabled = true
        descriptionCommentsDismissView.exclusiveTouch = true
        
        // add gesture recognizers
        var singleTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
        singleTap.numberOfTapsRequired = 1
        descriptionCommentsDismissView.addGestureRecognizer(singleTap)
        
        view.addSubview(descriptionCommentsDismissView)
        
        // 1. row 0 is description
        // 2. row 1 is comments section
        // 3. there will be a overlay for 'add a comment' inside this view controller (doesnt scroll)
        
        descriptionCommentsTableView = UITableView(frame: CGRect(x: 0, y: screenHeight - descriptionCommentsHeight, width: screenWidth, height: descriptionCommentsHeight))
        
        descriptionCommentsTableView.backgroundColor = UIColor.whiteColor()
        descriptionCommentsTableView.separatorColor = UIColor.clearColor()
        descriptionCommentsTableView.delegate = self
        descriptionCommentsTableView.dataSource = self
        descriptionCommentsTableView.delaysContentTouches = false
        
        view.addSubview(descriptionCommentsTableView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        switch(indexPath.row)
        {
        case 0: // description
            descriptionCell.textLabel?.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud."
            
            descriptionCell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
            descriptionCell.textLabel?.numberOfLines = 0
            descriptionCell.userInteractionEnabled = false
            
            return descriptionCell
            
        case 1: // comments
            // init comments
            let viewAllCommentsHeight:CGFloat = 40
            //let commentYPos:CGFloat = screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight + viewAllCommentsHeight
            
            // view all comments button
            var viewAllComments:UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2 + 35, height: viewAllCommentsHeight))
            var numComments:Int = 15
            viewAllComments.setTitle("View all comments (\(numComments))", forState: UIControlState.Normal)
            viewAllComments.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            viewAllComments.backgroundColor = UIColor.whiteColor()
            viewAllComments.addTarget(self, action: "viewAllComments:", forControlEvents: UIControlEvents.TouchUpInside)
            
            var viewAllCommentsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
            viewAllCommentsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            viewAllComments.addSubview(viewAllCommentsLineTop)
            
            commentsCell.addSubview(viewAllComments)
            
            // the 3 most recent comments
            var commentRowView1:SprubixItemCommentRow = SprubixItemCommentRow(username: "Mika", commentString: "Lorem ipsum dolor sit amet", y: viewAllCommentsHeight, button: false, userThumbnail: "user4-mika.jpg")
            var commentRowView2:SprubixItemCommentRow = SprubixItemCommentRow(username: "Rika", commentString: "Lorem ipsum dolor sit amet, consec tetur adipiscing elit", y: viewAllCommentsHeight + commentRowView1.commentRowHeight, button: false, userThumbnail: "user5-rika.jpg")
            var commentRowView3:SprubixItemCommentRow = SprubixItemCommentRow(username: "Melody", commentString: "Lorem ipsum", y: viewAllCommentsHeight + commentRowView1.commentRowHeight + commentRowView2.commentRowHeight, button: false, userThumbnail: "user6-melody.jpg")
            
            commentsCell.addSubview(commentRowView1)
            commentsCell.addSubview(commentRowView2)
            commentsCell.addSubview(commentRowView3)
            
            // add a comment button
            var commentRowButton:SprubixItemCommentRow = SprubixItemCommentRow(username: "", commentString: "", y: 0, button: true, userThumbnail: "sprubix-user")
            
            commentRowButton.frame = CGRect(x: 0, y: screenHeight - commentRowButton.commentRowHeight, width: screenWidth, height: commentRowButton.commentRowHeight)
            commentRowButton.postCommentButton.addTarget(self, action: "addCommentPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            view.addSubview(commentRowButton)
            
            // get rid of the gray bg when cell is selected
            var bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.clearColor()
            commentsCell.selectedBackgroundView = bgColorView
            
            return commentsCell

        default: fatalError("Unknown row in section")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight : CGFloat!
        
        switch(indexPath.row)
        {
        case 0:
            cellHeight = 100
        case 1:
            cellHeight = 270
        default:
            cellHeight = 300
        }
        
        return cellHeight
    }
    
    func addCommentPressed(sender: UIButton) {
        println("addCommentPressed")
    }
    
    func viewAllComments(sender: UIButton) {
        println("viewAllComments")
    }
    
    func wasSingleTapped(gesture: UITapGestureRecognizer) {
        delegate?.dismissCommentsView()
    }
}

//
//  OutfitDetailsCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class OutfitDetailsCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    var navController: UINavigationController?
    var commentsViewController: CommentsViewController?
    
    var imageName: String?

    var pullAction: ((offset : CGPoint) -> Void)?
    var returnAction: (() -> Void)?
    var tappedAction: (() -> Void)?
    
    let tableView = UITableView(frame: screenBounds, style: UITableViewStyle.Plain)
    
    var outfit: NSDictionary!
    var pieces: [NSDictionary]!
    var user: NSDictionary!
    var inspiredBy: NSDictionary!
    
    var pieceImageView: UIImageView!
    var pieceImages: [UIImageView] = [UIImageView]()

    var pullLabel:UILabel!
    
    var outfitImageCell: UITableViewCell!
    var creditsCell: UITableViewCell!
    var descriptionCell: UITableViewCell!
    var commentsCell: UITableViewCell!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //tableView.backgroundColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1)
        
        tableView.backgroundColor = UIColor.whiteColor()
        
        contentView.addSubview(tableView)
        
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorColor = UIColor.clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        
        self.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight;
        
        outfitImageCell = UITableViewCell()
        creditsCell = UITableViewCell()
        descriptionCell = UITableViewCell()
        commentsCell = UITableViewCell()
        
        outfitImageCell.backgroundColor = UIColor.whiteColor()
        creditsCell.backgroundColor = UIColor.whiteColor()
        descriptionCell.backgroundColor = UIColor.whiteColor()
        commentsCell.backgroundColor = UIColor.whiteColor()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.reloadData()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        pullLabel.removeFromSuperview()
        pieceImageView.removeFromSuperview()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch(indexPath.row)
        {
        case 0:
            // uilabel for 'pull down to go back'
            pullLabel = UILabel(frame: CGRect(x: 0, y: -40, width: screenWidth, height: 30))
            pullLabel.text = "Pull down to go back"
            pullLabel.textColor = UIColor.lightGrayColor()
            pullLabel.textAlignment = NSTextAlignment.Center
            
            outfitImageCell.addSubview(pullLabel)
            
            pieceImages.removeAll()
            var outfitHeight:CGFloat = 0
            var prevPieceHeight:CGFloat = 0
            
            pieces = outfit["pieces"] as! [NSDictionary]
            
            for piece in pieces {
                // calculate piece UIImageView height
                var itemHeight = piece["height"] as! CGFloat
                var itemWidth = piece["width"] as! CGFloat
                
                let pieceHeight:CGFloat = itemHeight * screenWidth / itemWidth
                
                // setting the image for piece
                pieceImageView = UIImageView()
                pieceImageView.image = nil
                pieceImageView.frame = CGRect(x:0, y: prevPieceHeight, width: UIScreen.mainScreen().bounds.width, height: pieceHeight)
                
                var pieceImagesString = piece["images"] as! String
                var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                var pieceCoverURL = NSURL(string: pieceImagesDict["cover"] as! String)
                
                pieceImageView.setImageWithURL(pieceCoverURL)
                pieceImageView.contentMode = UIViewContentMode.ScaleAspectFit
                pieceImageView.userInteractionEnabled = true
                
                // add gesture recognizers
                var singleTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
                singleTap.numberOfTapsRequired = 1
                pieceImageView.addGestureRecognizer(singleTap)
                
                var doubleTap = UITapGestureRecognizer(target: self, action: Selector("wasDoubleTapped:"))
                doubleTap.numberOfTapsRequired = 2
                pieceImageView.addGestureRecognizer(doubleTap)
                
                singleTap.requireGestureRecognizerToFail(doubleTap) // so that single tap will not be called during a double tap
                
                outfitImageCell.addSubview(pieceImageView)
                
                pieceImages.append(pieceImageView)
                
                prevPieceHeight += pieceHeight // to offset 2nd piece image's height with first image's height
                outfitHeight += pieceHeight // accumulate height of all pieces
            }
            
            return outfitImageCell
        case 1:
            // init 'posted by' and 'from' credits
            let creditsViewHeight:CGFloat = 80
            var creditsView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: creditsViewHeight))
            
            var postedByButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "posted by", username: user["username"] as! String, userThumbnail: user["image"] as! String)
            
            // if no inspired by, it is original
            // inspired by = parent, always credit parent
            var fromButton:SprubixCreditButton!
            
            if inspiredBy == nil {
                fromButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "inspired by", username: user["username"] as! String, userThumbnail: user["image"] as! String)
            } else {
                fromButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "inspired by", username: inspiredBy["username"] as! String, userThumbnail: inspiredBy["image"] as! String)
            }
            
            creditsView.addSubview(postedByButton)
            creditsView.addSubview(fromButton)
            
            creditsCell.addSubview(creditsView)
            
            return creditsCell
        case 2:
            descriptionCell.textLabel?.text = outfit["description"] as! String!
            
            descriptionCell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
            descriptionCell.textLabel?.numberOfLines = 0
            descriptionCell.userInteractionEnabled = false
            
            return descriptionCell
            
        case 3:
            // init comments
            let viewAllCommentsHeight:CGFloat = 40
            //let commentYPos:CGFloat = screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight + viewAllCommentsHeight
            
            // view all comments button
            var viewAllComments:UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2 + 35, height: viewAllCommentsHeight))
            var numComments:Int = 15
            viewAllComments.setTitle("View all comments (\(numComments))", forState: UIControlState.Normal)
            viewAllComments.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            viewAllComments.backgroundColor = UIColor.whiteColor()
            
            var viewAllCommentsBG:UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: viewAllCommentsHeight))
            viewAllCommentsBG.backgroundColor = UIColor.whiteColor()
            
            var viewAllCommentsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
            viewAllCommentsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            viewAllCommentsBG.addSubview(viewAllComments)
            viewAllCommentsBG.addSubview(viewAllCommentsLineTop)
            
            commentsCell.addSubview(viewAllCommentsBG)
            
            // the 3 most recent comments
            var commentRowView1:SprubixItemCommentRow = SprubixItemCommentRow(username: "Mika", commentString: "Really love this!", y: viewAllCommentsHeight, button: false, userThumbnail: "user4-mika.jpg")
            var commentRowView2:SprubixItemCommentRow = SprubixItemCommentRow(username: "Rika", commentString: "Hey! I also have this at home!", y: viewAllCommentsHeight + commentRowView1.commentRowHeight, button: false, userThumbnail: "user5-rika.jpg")
            var commentRowView3:SprubixItemCommentRow = SprubixItemCommentRow(username: "Melody", commentString: "How much is it?", y: viewAllCommentsHeight + commentRowView1.commentRowHeight + commentRowView2.commentRowHeight, button: false, userThumbnail: "user6-melody.jpg")
            
            commentsCell.addSubview(commentRowView1)
            commentsCell.addSubview(commentRowView2)
            commentsCell.addSubview(commentRowView3)
            
            // add a comment button
            var commentRowButton:SprubixItemCommentRow = SprubixItemCommentRow(username: "", commentString: "", y: viewAllCommentsHeight + commentRowView1.commentRowHeight + commentRowView2.commentRowHeight + commentRowView3.commentRowHeight, button: true, userThumbnail: "sprubix-user")
            
            commentRowButton.postCommentButton.addTarget(self, action: "addComments:", forControlEvents: UIControlEvents.TouchUpInside)
            
            commentsCell.addSubview(commentRowButton)
            
            // get rid of the gray bg when cell is selected
            var bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.clearColor()
            commentsCell.selectedBackgroundView = bgColorView
            
            return commentsCell
            
        default: fatalError("Unknown row in section")
        }
    }
    
    func wasSingleTapped(gesture: UITapGestureRecognizer) {
        
        var selectedPiece:UIImageView = gesture.view as! UIImageView
        var position = find(pieceImages, selectedPiece)
        
        var currentIndexPath:NSIndexPath = NSIndexPath(forItem: position!, inSection: 0)
        
        let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath: currentIndexPath)

        pieceDetailsViewController.pieces = pieces
        pieceDetailsViewController.user = user
        pieceDetailsViewController.inspiredBy = inspiredBy
        
        //collectionView.setToIndexPath(indexPath)
        navController!.delegate = nil
        //navController!.pushViewController(pieceDetailsViewController, animated: true)
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionMoveIn
        transition.subtype = kCATransitionFromTop
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        navController?.view.layer.addAnimation(transition, forKey: kCATransition)
        navController!.pushViewController(pieceDetailsViewController, animated: false)
        
        navController!.delegate = transitionDelegateHolder
    }
    
    func wasDoubleTapped(gesture: UITapGestureRecognizer) {
        println("double tapped!")
        println(gesture.view)
    }
    
    func heightForTextLabel(text:String, width:CGFloat, padding: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.text = text
        
        label.sizeToFit()
        return label.frame.height + padding
    }
    
    func detailsViewControllerLayout () -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        
        let itemSize  = CGSizeMake(screenWidth, screenHeight) //navController!.navigationBarHidden ?
            //CGSizeMake(screenWidth, screenHeight+20) : CGSizeMake(screenWidth, screenHeight-navigationHeaderAndStatusbarHeight)
        
        //let itemSize = CGSizeMake(screenWidth, screenHeight + navigationHeight)
        
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        return flowLayout
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        var cellHeight : CGFloat!
        
        switch(indexPath.row)
        {
        case 0:
            
            let outfitHeight = outfit["height"] as! CGFloat
            let outfitWidth = outfit["width"] as! CGFloat
            
            let imageHeight = outfitHeight * screenWidth / outfitWidth
            
            cellHeight = imageHeight
        case 1:
            cellHeight = 80 // creditsViewHeight
        case 2:
            cellHeight = heightForTextLabel(outfit["description"] as! String, width: screenWidth, padding: 20) // description height
        case 3:
            cellHeight = 270 // comments height
        default:
            cellHeight = 300
        }
        
        return cellHeight
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        tappedAction?()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -80 {
            pullLabel.text = "Release to go back"
            
            if scrollView.contentOffset.y < -150 {
                pullLabel.text = "Return to main feed"
            }
        } else {
            pullLabel.text = "Pull down to go back"
        }
    }
    
    func scrollViewWillBeginDecelerating(scrollView : UIScrollView){        
        if scrollView.contentOffset.y < -150 {
            returnAction?()
        } else if scrollView.contentOffset.y < -80 {
            pullAction?(offset: scrollView.contentOffset)
        }
    }
    
    // button callbacks
    func addComments(sender: UIButton) {
        if commentsViewController == nil {
            commentsViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("CommentsView") as? CommentsViewController
        }
        
        commentsViewController?.prevViewIsOutfit = true
        
        navController!.delegate = nil
        navController!.pushViewController(commentsViewController!, animated: true)
    }
}

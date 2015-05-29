//
//  PieceDetailsCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol PieceDetailsOutfitProtocol {
    func relevantOutfitSelected(collectionView: UICollectionView, index: NSIndexPath)
}

class PieceDetailsCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout {

    var outfits: [NSDictionary] = [NSDictionary]()
    
    var piece: NSDictionary!
    var user: NSDictionary!
    var inspiredBy: NSDictionary!
    
    var pullAction : ((offset : CGPoint) -> Void)?
    var returnAction : (() -> Void)?
    var tappedAction : (() -> Void)?
    
    let relatedOutfitCellIdentifier = "ProfileOutfitCell"
    
    var pieceDetailsHeaderHeight:CGFloat = 800
    
    var singlePieceCollectionView: UICollectionView!
    
    var navController:UINavigationController?
    var commentsViewController: CommentsViewController?
    var delegate:PieceDetailsOutfitProtocol?
    
    // piece detail info
    var pieceDetailInfoView:UIView!
    var pullLabel:UILabel!
    var pieceImageView: UIImageView = UIImageView()
    var totalHeaderHeight: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // layout for outfits tab
        var relatedOutfitsLayout = CHTCollectionViewWaterfallLayout()
        
        relatedOutfitsLayout.sectionInset = UIEdgeInsetsMake(1000, 10, 10, 10)
        //relatedOutfitsLayout.headerHeight = 1
        relatedOutfitsLayout.footerHeight = 10
        relatedOutfitsLayout.minimumColumnSpacing = 10
        relatedOutfitsLayout.minimumInteritemSpacing = 10
        relatedOutfitsLayout.columnCount = 2
        
        // collection view init
        singlePieceCollectionView = UICollectionView(frame: screenBounds, collectionViewLayout: relatedOutfitsLayout)
        singlePieceCollectionView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        singlePieceCollectionView.showsVerticalScrollIndicator = false
        
        singlePieceCollectionView.registerClass(ProfileOutfitCell.self, forCellWithReuseIdentifier: relatedOutfitCellIdentifier)
        
        singlePieceCollectionView.alwaysBounceVertical = true
        singlePieceCollectionView.backgroundColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1)
        
        singlePieceCollectionView.dataSource = self;
        singlePieceCollectionView.delegate = self;
        
        addSubview(singlePieceCollectionView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        for subview in pieceDetailInfoView.subviews {
            subview.removeFromSuperview()
        }
        
        pieceDetailInfoView.removeFromSuperview()
        pieceDetailInfoView = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        pieceDetailInfoView = UIView()
        
        // uilabel for 'pull down to go back'
        pullLabel = UILabel(frame: CGRect(x: 0, y: -40, width: screenWidth, height: 30))
        pullLabel.text = "Pull down to go back"
        pullLabel.textColor = UIColor.lightGrayColor()
        pullLabel.textAlignment = NSTextAlignment.Center
        
        pieceDetailInfoView.addSubview(pullLabel)
        
        pieceDetailInfoView.addSubview(pieceImageView)
        
        // init horizontal scrollview
        var pieceImagesString = piece["images"] as! String
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        var pieceImageURL = NSURL(string: pieceImagesDict["cover"] as! String)
        
        pieceImageView.setImageWithURL(pieceImageURL)
        pieceImageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth)
        pieceImageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        // init 'posted by' and 'from' credits
        let creditsViewHeight:CGFloat = 80
        var creditsView:UIView = UIView(frame: CGRect(x: 0, y: screenWidth, width: screenWidth, height: creditsViewHeight))
        
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
        
        pieceDetailInfoView.addSubview(creditsView)
        
        // init piece specifications
        let itemSpecHeight:CGFloat = 55
        let itemSpecHeightTotal:CGFloat = itemSpecHeight * 4
        
        var pieceSpecsView:UIView = UIView(frame: CGRect(x: 0, y: screenWidth + creditsViewHeight, width: screenWidth, height: itemSpecHeightTotal))
        pieceSpecsView.backgroundColor = UIColor.whiteColor()
        
        // generate 4 labels with icons
        let itemImageViewWidth:CGFloat = 0.3 * screenWidth
        
        // name
        var itemNameImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemNameImage.setImage(UIImage(named: "view-item-name"), forState: UIControlState.Normal)
        itemNameImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemNameImage.frame = CGRect(x: 0, y: 0, width: itemImageViewWidth, height: itemSpecHeight)
        itemNameImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemNameImage)
        
        var itemNameLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: 0, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemNameLabel.text = piece["name"] as? String
        
        // category
        var itemCategoryImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemCategoryImage.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
        itemCategoryImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemCategoryImage.frame = CGRect(x: 0, y: itemSpecHeight, width: itemImageViewWidth, height: itemSpecHeight)
        itemCategoryImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemCategoryImage)
        
        var itemCategoryLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemCategoryLabel.text = piece["category"] as? String
        
        // brand
        var itemBrandImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemBrandImage.setImage(UIImage(named: "view-item-brand"), forState: UIControlState.Normal)
        itemBrandImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemBrandImage.frame = CGRect(x: 0, y: itemSpecHeight * 2, width: itemImageViewWidth, height: itemSpecHeight)
        itemBrandImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemBrandImage)
        
        var itemBrandLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight * 2, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemBrandLabel.text = piece["brand"] as? String
        
        // size
        var itemSizeImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemSizeImage.setImage(UIImage(named: "view-item-size"), forState: UIControlState.Normal)
        itemSizeImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemSizeImage.frame = CGRect(x: 0, y: itemSpecHeight * 3, width: itemImageViewWidth, height: itemSpecHeight)
        itemSizeImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemSizeImage)

        var itemSizeLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight * 3, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemSizeLabel.text = piece["size"] as? String
        
        pieceSpecsView.addSubview(itemNameImage)
        pieceSpecsView.addSubview(itemNameLabel)
        
        pieceSpecsView.addSubview(itemCategoryImage)
        pieceSpecsView.addSubview(itemCategoryLabel)
        
        pieceSpecsView.addSubview(itemBrandImage)
        pieceSpecsView.addSubview(itemBrandLabel)
        
        pieceSpecsView.addSubview(itemSizeImage)
        pieceSpecsView.addSubview(itemSizeLabel)
        
        pieceDetailInfoView.addSubview(pieceSpecsView)
        
        // init piece description
        var itemDescription:SprubixItemDescription = SprubixItemDescription()
        itemDescription.lineBreakMode = NSLineBreakMode.ByWordWrapping
        itemDescription.numberOfLines = 0
        itemDescription.backgroundColor = UIColor.whiteColor()
        itemDescription.text = piece["description"] as? String
        
        var itemDescriptionHeight = heightForTextLabel(itemDescription.text!, font: itemDescription.font, width: screenWidth, hasInsets: true)
        
        itemDescription.frame = CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal, width: screenWidth, height: itemDescriptionHeight)
        itemDescription.drawTextInRect(CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal, width: screenWidth, height: itemDescriptionHeight))
        
        pieceDetailInfoView.addSubview(itemDescription)
        
        // init comments
        let viewAllCommentsHeight:CGFloat = 40
        let commentYPos:CGFloat = screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight + viewAllCommentsHeight
        
        // view all comments button
        var viewAllComments:UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2 + 35, height: viewAllCommentsHeight))
        var numComments:Int = 15
        viewAllComments.setTitle("View all comments (\(numComments))", forState: UIControlState.Normal)
        viewAllComments.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        viewAllComments.backgroundColor = UIColor.whiteColor()
        
        var viewAllCommentsBG:UIView = UIView(frame: CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight, width: screenWidth, height: viewAllCommentsHeight))
        viewAllCommentsBG.backgroundColor = UIColor.whiteColor()
        
        var viewAllCommentsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
        viewAllCommentsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        viewAllCommentsBG.addSubview(viewAllComments)
        viewAllCommentsBG.addSubview(viewAllCommentsLineTop)
        
        pieceDetailInfoView.addSubview(viewAllCommentsBG)
        
        // the 3 most recent comments
        var commentRowView1:SprubixItemCommentRow = SprubixItemCommentRow(username: "Mika", commentString: "Really love this!", y: commentYPos, button: false, userThumbnail: "user4-mika.jpg")
        var commentRowView2:SprubixItemCommentRow = SprubixItemCommentRow(username: "Rika", commentString: "Hey! I also have this at home!", y: commentYPos + commentRowView1.commentRowHeight, button: false, userThumbnail: "user5-rika.jpg")
        var commentRowView3:SprubixItemCommentRow = SprubixItemCommentRow(username: "Melody", commentString: "How much is it?", y: commentYPos + commentRowView1.commentRowHeight + commentRowView2.commentRowHeight, button: false, userThumbnail: "user6-melody.jpg")
        
        pieceDetailInfoView.addSubview(commentRowView1)
        pieceDetailInfoView.addSubview(commentRowView2)
        pieceDetailInfoView.addSubview(commentRowView3)
        
        // add a comment button
        var commentRowButton:SprubixItemCommentRow = SprubixItemCommentRow(username: "", commentString: "", y: commentYPos + commentRowView1.commentRowHeight + commentRowView2.commentRowHeight + commentRowView3.commentRowHeight, button: true, userThumbnail: "sprubix-user")
        
        commentRowButton.postCommentButton.addTarget(self, action: "addComments:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceDetailInfoView.addSubview(commentRowButton)
        
        let commentSectionHeight:CGFloat = commentRowView1.commentRowHeight + commentRowView2.commentRowHeight + commentRowView3.commentRowHeight + commentRowButton.commentRowHeight
        
        var outfitsUsingLabel:UILabel = UILabel(frame: CGRectInset(CGRect(x: 0, y: commentYPos + commentSectionHeight, width: screenWidth, height: 70), 20, 15))
        outfitsUsingLabel.text = "Outfits using this item"
        outfitsUsingLabel.textColor = UIColor.grayColor()
        
        pieceDetailInfoView.addSubview(outfitsUsingLabel)
        
        // total height of entire header
        totalHeaderHeight = commentYPos + commentSectionHeight

        pieceDetailInfoView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: totalHeaderHeight)
        
        singlePieceCollectionView.addSubview(pieceDetailInfoView)
        
        resetHeaderHeight(totalHeaderHeight, padding: 60.0)
        
        retrieveOutfits()
    }
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        var itemHeight:CGFloat!
        var itemWidth:CGFloat!
        
        let outfit = outfits[indexPath.row] as NSDictionary
        itemHeight = outfit["height"] as! CGFloat
        itemWidth = outfit["width"] as! CGFloat
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight)
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(relatedOutfitCellIdentifier, forIndexPath: indexPath) as! ProfileOutfitCell
        
        var outfit = outfits[indexPath.row] as NSDictionary
        var outfitImagesString = outfit["images"] as! NSString
        var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
        
        (cell as ProfileOutfitCell).imageURLString = outfitImageDict["small"] as! String
        
        cell.setNeedsLayout()
        cell.setNeedsDisplay()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return outfits.count
    }
    
    func retrieveOutfits() {
        let pieceId:Int = piece["id"] as! Int
        
        // retrieve outfits using this piece
        manager.GET(SprubixConfig.URL.api + "/piece/\(pieceId)/outfits",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.outfits = responseObject["data"] as! [NSDictionary]
                self.singlePieceCollectionView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // ResetHeaderHeight protocol
    func resetHeaderHeight(headerHeight: CGFloat, padding: CGFloat) {
        var relatedOutfitsLayout = CHTCollectionViewWaterfallLayout()
        
        relatedOutfitsLayout.sectionInset = UIEdgeInsetsMake(headerHeight + padding, 10, 10, 10)
        relatedOutfitsLayout.footerHeight = 10
        relatedOutfitsLayout.minimumColumnSpacing = 10
        relatedOutfitsLayout.minimumInteritemSpacing = 10
        relatedOutfitsLayout.columnCount = 2

        singlePieceCollectionView.reloadData()
        singlePieceCollectionView.setCollectionViewLayout(relatedOutfitsLayout, animated: false)
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.relevantOutfitSelected(collectionView, index: indexPath)
        
        let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath:indexPath)
        outfitDetailsViewController.outfits = outfits
        
        collectionView.setToIndexPath(indexPath)
        navController!.pushViewController(outfitDetailsViewController, animated: true)
    }
    
    func detailsViewControllerLayout () -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        
        let itemSize = CGSizeMake(screenWidth, screenHeight) //navController!.navigationBarHidden ?
            //CGSizeMake(screenWidth, screenHeight+20) : CGSizeMake(screenWidth, screenHeight-navigationHeaderAndStatusbarHeight)
        
        //let itemSize = CGSizeMake(screenWidth, screenHeight + navigationHeight)
        
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        return flowLayout
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
    
    // button callbacks
    func addComments(sender: UIButton) {
        if commentsViewController == nil {
            commentsViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("CommentsView") as? CommentsViewController
        }
        
        navController!.delegate = nil
        navController!.pushViewController(commentsViewController!, animated: true)
    }
}

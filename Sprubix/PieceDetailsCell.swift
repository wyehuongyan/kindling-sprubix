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
    var pullAction : ((offset : CGPoint) -> Void)?
    var tappedAction : (() -> Void)?
    
    let relatedOutfitCellIdentifier = "ProfileOutfitCell"
    
    var pieceDetailsHeaderHeight:CGFloat = 800
    
    var singlePieceCollectionView: UICollectionView!
    
    var navController:UINavigationController?
    var delegate:PieceDetailsOutfitProtocol?
    
    // piece detail info
    var pieceDetailInfoView:UIView!
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
        
        // testing
        manager.GET(SprubixConfig.URL.api + "/user/1/outfits",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                self.outfits = responseObject["data"] as [NSDictionary]!
                self.singlePieceCollectionView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
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
        
        pieceDetailInfoView.addSubview(pieceImageView)
        
        // init horizontal scrollview
        var pieceImagesString = piece["images"] as NSString!
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        var pieceImageURL = NSURL(string: pieceImagesDict["cover"] as NSString)
        
        pieceImageView.setImageWithURL(pieceImageURL)
        pieceImageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth)
        pieceImageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        // init 'posted by' and 'from' credits
        let creditsViewHeight:CGFloat = 80
        var creditsView:UIView = UIView(frame: CGRect(x: 0, y: screenWidth, width: screenWidth, height: creditsViewHeight))
        
        var postedByButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "posted by", username: "user name")
        var fromButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "from", username: "user name")
        
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
        
        var itemNameImageView:UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: itemImageViewWidth, height: itemSpecHeight))
        itemNameImageView.image = UIImage(named: "icon-placeholder.png")
        itemNameImageView.contentMode = UIViewContentMode.ScaleAspectFit
        var itemNameLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: 0, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemNameLabel.text = "Name"
        
        var itemCategoryImageView:UIImageView = UIImageView(frame: CGRect(x: 0, y: itemSpecHeight, width: itemImageViewWidth, height: itemSpecHeight))
        itemCategoryImageView.image = UIImage(named: "icon-placeholder.png")
        itemCategoryImageView.contentMode = UIViewContentMode.ScaleAspectFit
        var itemCategoryLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemCategoryLabel.text = "Category"
        
        var itemBrandImageView:UIImageView = UIImageView(frame: CGRect(x: 0, y: itemSpecHeight * 2, width: itemImageViewWidth, height: itemSpecHeight))
        itemBrandImageView.image = UIImage(named: "icon-placeholder.png")
        itemBrandImageView.contentMode = UIViewContentMode.ScaleAspectFit
        var itemBrandLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight * 2, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemBrandLabel.text = "Brand"
        
        var itemSizeImageView:UIImageView = UIImageView(frame: CGRect(x: 0, y: itemSpecHeight * 3, width: itemImageViewWidth, height: itemSpecHeight))
        itemSizeImageView.image = UIImage(named: "icon-placeholder.png")
        itemSizeImageView.contentMode = UIViewContentMode.ScaleAspectFit
        var itemSizeLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight * 3, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemSizeLabel.text = "Size"
        
        pieceSpecsView.addSubview(itemNameImageView)
        pieceSpecsView.addSubview(itemNameLabel)
        
        pieceSpecsView.addSubview(itemCategoryImageView)
        pieceSpecsView.addSubview(itemCategoryLabel)
        
        pieceSpecsView.addSubview(itemBrandImageView)
        pieceSpecsView.addSubview(itemBrandLabel)
        
        pieceSpecsView.addSubview(itemSizeImageView)
        pieceSpecsView.addSubview(itemSizeLabel)
        
        pieceDetailInfoView.addSubview(pieceSpecsView)
        
        // init piece description
        var itemDescription:SprubixItemDescription = SprubixItemDescription()
        itemDescription.lineBreakMode = NSLineBreakMode.ByWordWrapping
        itemDescription.numberOfLines = 0
        itemDescription.backgroundColor = UIColor.whiteColor()
        itemDescription.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud."
        
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
        var commentRowView1:SprubixItemCommentRow = SprubixItemCommentRow(username: "Onigiri", commentString: "Lorem ipsum dolor sit amet", y: commentYPos, button: false)
        var commentRowView2:SprubixItemCommentRow = SprubixItemCommentRow(username: "Croquette", commentString: "Lorem ipsum dolor sit amet, consec tetur adipiscing elit", y: commentYPos + commentRowView1.commentRowHeight, button: false)
        var commentRowView3:SprubixItemCommentRow = SprubixItemCommentRow(username: "Peach", commentString: "Lorem ipsum", y: commentYPos + commentRowView1.commentRowHeight + commentRowView2.commentRowHeight, button: false)
        
        pieceDetailInfoView.addSubview(commentRowView1)
        pieceDetailInfoView.addSubview(commentRowView2)
        pieceDetailInfoView.addSubview(commentRowView3)
        
        // add a comment button
        var commentRowButton:SprubixItemCommentRow = SprubixItemCommentRow(username: "", commentString: "", y: commentYPos + commentRowView1.commentRowHeight + commentRowView2.commentRowHeight + commentRowView3.commentRowHeight, button: true)
        
        commentRowButton.postCommentButton.addTarget(self, action: "addCommentPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceDetailInfoView.addSubview(commentRowButton)
        
        let commentSectionHeight:CGFloat = commentRowView1.commentRowHeight + commentRowView2.commentRowHeight + commentRowView3.commentRowHeight + commentRowButton.commentRowHeight
        
        // total height of entire header
        totalHeaderHeight = commentYPos + commentSectionHeight

        pieceDetailInfoView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: totalHeaderHeight)
        
        singlePieceCollectionView.addSubview(pieceDetailInfoView)
        
        resetHeaderHeight(totalHeaderHeight, padding: 65.0)
    }
    
    // CHTCollectionViewDelegateWaterfallLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        var itemHeight:CGFloat!
        var itemWidth:CGFloat!
        
        let outfit = outfits[indexPath.row] as NSDictionary
        itemHeight = outfit["height"] as CGFloat
        itemWidth = outfit["width"] as CGFloat
        
        let imageHeight = itemHeight * gridWidth/itemWidth
        
        return CGSizeMake(gridWidth, imageHeight)
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(relatedOutfitCellIdentifier, forIndexPath: indexPath) as ProfileOutfitCell
        
        var outfit = outfits[indexPath.row] as NSDictionary
        
        (cell as ProfileOutfitCell).imageURLString = outfit["images"] as String!
        
        cell.setNeedsLayout()
        cell.setNeedsDisplay()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return outfits.count
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
    
    func scrollViewWillBeginDecelerating(scrollView : UIScrollView){
        if scrollView.contentOffset.y < -100 {
            pullAction?(offset: scrollView.contentOffset)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.relevantOutfitSelected(collectionView, index: indexPath)
        
        //println(navController)
        
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
    
    // selectors
    func addCommentPressed(sender: UIButton) {
        println("lol")
    }
}

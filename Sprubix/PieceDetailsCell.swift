//
//  PieceDetailsCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import AFNetworking

protocol PieceDetailsOutfitProtocol {
    func relevantOutfitSelected(collectionView: UICollectionView, index: NSIndexPath)
}

class PieceDetailsCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout, UIScrollViewDelegate {

    var detailsCellActionDelegate: DetailsCellActions?
    var outfits: [NSDictionary] = [NSDictionary]()
    
    var piece: NSDictionary!
    var user: NSDictionary!
    var inspiredBy: NSDictionary!
    var recentComments: [NSDictionary] = [NSDictionary]()
    var numTotalComments: Int = 0
    var numTotalLikes: Int = 0
    
    var pullAction: ((offset : CGPoint) -> Void)?
    var returnAction: (() -> Void)?
    var tappedAction: (() -> Void)?
    
    let relatedOutfitCellIdentifier = "ProfileOutfitCell"
    
    var pieceDetailsHeaderHeight: CGFloat = 800
    
    var singlePieceCollectionView: UICollectionView!
    
    var navController: UINavigationController?
    var commentsViewController: CommentsViewController?
    var delegate: PieceDetailsOutfitProtocol?
    
    // piece detail info
    var pieceDetailInfoView: UIView!
    let pullLabel: UILabel = UILabel()
    var pieceImagesScrollView: UIScrollView!
    var pageControl:UIPageControl!
    var totalHeaderHeight: CGFloat!
    
    let viewAllCommentsHeight:CGFloat = 40
    var commentRowButton: SprubixItemCommentRow!
    
    // firebase
    var childAddedHandle: UInt?
    var poutfitCommentsRef: Firebase!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        
        pageControl.removeFromSuperview()
        pageControl = nil
        
        for subview in pieceImagesScrollView.subviews {
            subview.removeFromSuperview()
        }
        
        pieceImagesScrollView.removeFromSuperview()
        pieceImagesScrollView = nil
        
        if childAddedHandle != nil {
            poutfitCommentsRef.removeObserverWithHandle(childAddedHandle!)
            
            childAddedHandle = nil
            numTotalComments = 0
        }
        
        numTotalLikes = 0
    }
    
    func initPieceCollectionView() {
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
        singlePieceCollectionView.backgroundColor = sprubixGray
        
        singlePieceCollectionView.dataSource = self;
        singlePieceCollectionView.delegate = self;
        
        addSubview(singlePieceCollectionView)
        
        initPieceDetails()
    }
    
    func initPieceDetails() {
        pieceDetailInfoView = UIView()
        
        // uilabel for 'pull down to go back'
        pullLabel.frame = CGRect(x: 0, y: -40, width: screenWidth, height: 30)
        pullLabel.text = "Pull down to go back"
        pullLabel.textColor = UIColor.lightGrayColor()
        pullLabel.textAlignment = NSTextAlignment.Center
        
        pieceDetailInfoView.addSubview(pullLabel)
        
        // init horizontal scrollview
        var pieceImagesString = piece["images"] as! String
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        var pieceImageURL = NSURL(string: pieceImagesDict["cover"] as! String)
        
        // piece images horizontal scroll view
        pieceImagesScrollView = UIScrollView(frame: CGRectMake(0, 0, screenWidth, screenWidth))
        pieceImagesScrollView.pagingEnabled = true
        pieceImagesScrollView.scrollEnabled = true
        pieceImagesScrollView.showsHorizontalScrollIndicator = false
        pieceImagesScrollView.alwaysBounceHorizontal = true
        pieceImagesScrollView.delegate = self
        
        let pieceImagesArray = pieceImagesDict["images"] as! NSArray
        
        for var i = 0; i < pieceImagesArray.count ; i++ {
            var imageDict = pieceImagesArray[i] as! NSDictionary
            let imageURL = NSURL(string: imageDict["medium"] as! String)
            
            var pieceImageView: UIImageView = UIImageView()
            pieceImageView.backgroundColor = sprubixGray
            pieceImageView.setImageWithURL(imageURL)
            pieceImageView.frame = CGRect(x: CGFloat(i) * screenWidth, y: 0, width: screenWidth, height: screenWidth)
            pieceImageView.contentMode = UIViewContentMode.ScaleAspectFit
            
            pieceImagesScrollView.addSubview(pieceImageView)
        }
        
        pieceImagesScrollView.contentSize = CGSize(width: screenWidth * CGFloat(pieceImagesArray.count), height: pieceImagesScrollView.frame.size.height)
        
        pieceDetailInfoView.addSubview(pieceImagesScrollView)
        
        // create a page control to show paging indicators
        pageControl = UIPageControl(frame: CGRect(x: 0, y: screenWidth - 40, width: bounds.width, height: 21))
        pageControl.numberOfPages = pieceImagesArray.count
        pageControl.currentPage = 0
        pageControl.clipsToBounds = true
        
        Glow.addGlow(pageControl)
        
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
        let itemSpecHeightTotal:CGFloat = itemSpecHeight * 5
        
        var pieceSpecsView:UIView = UIView(frame: CGRect(x: 0, y: screenWidth + creditsViewHeight, width: screenWidth, height: itemSpecHeightTotal))
        pieceSpecsView.backgroundColor = UIColor.whiteColor()
        
        // generate 5 labels with icons
        let itemImageViewWidth:CGFloat = 0.3 * screenWidth
        
        // likes
        var itemLikesImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemLikesImage.setImage(UIImage(named: "main-like"), forState: UIControlState.Normal)
        itemLikesImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemLikesImage.frame = CGRect(x: 0, y: 0, width: itemImageViewWidth, height: itemSpecHeight)
        itemLikesImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemLikesImage)
        
        var itemLikesLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: 0, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        if numTotalLikes != 0 {
            itemLikesLabel.text = numTotalLikes > 1 ? "\(numTotalLikes) people like this" : "\(numTotalLikes) person likes this"
        } else {
            itemLikesLabel.text = "Be the first to like!"
        }
        
        // name
        var itemNameImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemNameImage.setImage(UIImage(named: "view-item-name"), forState: UIControlState.Normal)
        itemNameImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemNameImage.frame = CGRect(x: 0, y: itemSpecHeight, width: itemImageViewWidth, height: itemSpecHeight)
        itemNameImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemNameImage)
        
        var itemNameLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemNameLabel.text = piece["name"] as? String
        
        // category
        var itemCategoryImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemCategoryImage.setImage(UIImage(named: "view-item-cat-top"), forState: UIControlState.Normal)
        itemCategoryImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemCategoryImage.frame = CGRect(x: 0, y: itemSpecHeight * 2, width: itemImageViewWidth, height: itemSpecHeight)
        itemCategoryImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemCategoryImage)
        
        var itemCategoryLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight * 2, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        
        let pieceCategory = piece["category"] as? NSDictionary
        itemCategoryLabel.text = pieceCategory?["name"] as? String
        
        // brand
        var itemBrandImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemBrandImage.setImage(UIImage(named: "view-item-brand"), forState: UIControlState.Normal)
        itemBrandImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemBrandImage.frame = CGRect(x: 0, y: itemSpecHeight * 3, width: itemImageViewWidth, height: itemSpecHeight)
        itemBrandImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemBrandImage)
        
        var itemBrandLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight * 3, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))

        let pieceBrand = piece["brand"] as? NSDictionary
        itemBrandLabel.text = pieceBrand?["name"] as? String
        
        // size
        var itemSizeImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemSizeImage.setImage(UIImage(named: "view-item-size"), forState: UIControlState.Normal)
        itemSizeImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemSizeImage.frame = CGRect(x: 0, y: itemSpecHeight * 4, width: itemImageViewWidth, height: itemSpecHeight)
        itemSizeImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        
        Glow.addGlow(itemSizeImage)
        
        var itemSizeLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight * 4, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        itemSizeLabel.text = piece["size"] as? String
        
        pieceSpecsView.addSubview(itemLikesImage)
        pieceSpecsView.addSubview(itemLikesLabel)
        
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
        itemDescription.textColor = UIColor.darkGrayColor()
        
        var itemDescriptionHeight = heightForTextLabel(itemDescription.text!, font: itemDescription.font, width: screenWidth, hasInsets: true)
        
        itemDescription.frame = CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal, width: screenWidth, height: itemDescriptionHeight)
        itemDescription.drawTextInRect(CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal, width: screenWidth, height: itemDescriptionHeight))
        
        pieceDetailInfoView.addSubview(itemDescription)
        
        // init comments
        let commentYPos:CGFloat = screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight + viewAllCommentsHeight
        
        // view all comments button
        var viewAllComments:UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0.8 * screenWidth, height: viewAllCommentsHeight))
        viewAllComments.setTitle("View all comments (\(numTotalComments))", forState: UIControlState.Normal)
        viewAllComments.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0)
        viewAllComments.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        viewAllComments.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        viewAllComments.backgroundColor = UIColor.whiteColor()
        viewAllComments.titleLabel?.font = UIFont.systemFontOfSize(17.0)
        viewAllComments.addTarget(self, action: "addComments:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var viewMore: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image = UIImage(named: "more-dots")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        viewMore.frame = CGRectMake(viewAllComments.frame.size.width, 0, screenWidth - viewAllComments.frame.size.width, viewAllCommentsHeight)
        viewMore.setImage(image, forState: UIControlState.Normal)
        viewMore.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 16)
        viewMore.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        viewMore.imageView?.tintColor = sprubixGray
        viewMore.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Right
        viewMore.backgroundColor = UIColor.clearColor()
        viewMore.addTarget(self, action: "showMoreOptions:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var viewAllCommentsBG:UIView = UIView(frame: CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight, width: screenWidth, height: viewAllCommentsHeight))
        viewAllCommentsBG.backgroundColor = UIColor.whiteColor()
        
        var viewAllCommentsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
        viewAllCommentsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        viewAllCommentsBG.addSubview(viewAllComments)
        viewAllCommentsBG.addSubview(viewMore)
        viewAllCommentsBG.addSubview(viewAllCommentsLineTop)
        
        pieceDetailInfoView.addSubview(viewAllCommentsBG)
        
        if childAddedHandle == nil {
            // retrieve 3 most recent comments
            let pieceId = piece["id"] as! Int
            retrieveRecentComments("piece_\(pieceId)")
        }
        
        let commentSectionHeight: CGFloat = loadRecentComments(commentYPos)
        
        var outfitsUsingLabel:UILabel = UILabel(frame: CGRectInset(CGRect(x: 0, y: commentYPos + commentSectionHeight, width: screenWidth, height: 70), 20, 15))
        outfitsUsingLabel.text = "Outfits using this item"
        outfitsUsingLabel.textColor = UIColor.grayColor()
        
        pieceDetailInfoView.addSubview(outfitsUsingLabel)
        
        // total height of entire header
        totalHeaderHeight = commentYPos + commentSectionHeight
        
        pieceDetailInfoView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: totalHeaderHeight)
        
        singlePieceCollectionView.addSubview(pieceDetailInfoView)
        
        if pieceImagesArray.count > 1 {
            singlePieceCollectionView.addSubview(pageControl)
        }
        
        resetHeaderHeight(totalHeaderHeight, padding: 60.0)
        
        retrieveOutfits()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func loadRecentComments(commentYPos: CGFloat) -> CGFloat {
        var prevHeight: CGFloat = 0
        
        for recentComment in recentComments {
            let commentAuthor = recentComment["author"] as! NSDictionary
            let authorImage = commentAuthor["image"] as! String
            let authorUserName = commentAuthor["username"] as! String
            
            let commentBody = recentComment["body"] as! String
            
            var commentRowView: SprubixItemCommentRow = SprubixItemCommentRow(username: authorUserName, commentString: commentBody, y: commentYPos + prevHeight, button: false, userThumbnail: authorImage)
            
            prevHeight += commentRowView.commentRowHeight
            pieceDetailInfoView.addSubview(commentRowView)
        }
        
        // add a comment button
        commentRowButton = SprubixItemCommentRow(username: "", commentString: "", y: commentYPos + prevHeight, button: true, userThumbnail: "sprubix-user")
        
        commentRowButton.postCommentButton.addTarget(self, action: "addComments:", forControlEvents: UIControlEvents.TouchUpInside)
        
        pieceDetailInfoView.addSubview(commentRowButton)
        
        return prevHeight + commentRowButton.commentRowHeight
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
    
    func calculatePageIndicator() {
        let pageWidth = pieceImagesScrollView.frame.size.width
        let page = Int(floor((pieceImagesScrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
        
        pageControl.currentPage = page
    }
    
    // ResetHeaderHeight protocol
    func resetHeaderHeight(headerHeight: CGFloat, padding: CGFloat) {
        var relatedOutfitsLayout = CHTCollectionViewWaterfallLayout()
        
        relatedOutfitsLayout.sectionInset = UIEdgeInsetsMake(headerHeight + padding, 10, 10, 10)
        relatedOutfitsLayout.footerHeight = 10
        relatedOutfitsLayout.minimumColumnSpacing = 10
        relatedOutfitsLayout.minimumInteritemSpacing = 10
        relatedOutfitsLayout.columnCount = 2
        
        var oldContentOffset = singlePieceCollectionView.contentOffset
        relatedOutfitsLayout.targetContentOffsetForProposedContentOffset(oldContentOffset)
        
        singlePieceCollectionView.reloadData()
        singlePieceCollectionView.setCollectionViewLayout(relatedOutfitsLayout, animated: false)
        singlePieceCollectionView.contentOffset = oldContentOffset
    }
    
    // scrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView == pieceImagesScrollView {
            calculatePageIndicator()
        } else {
            if scrollView.contentOffset.y < -80 {
                pullLabel.text = "Release to go back"
                
                if scrollView.contentOffset.y < -150 {
                    pullLabel.text = "Return to main feed"
                }
            } else {
                pullLabel.text = "Pull down to go back"
            }
        }
    }
    
    func scrollViewWillBeginDecelerating(scrollView : UIScrollView){
        if scrollView != pieceImagesScrollView {
            if scrollView.contentOffset.y < -150 {
                returnAction?()
                
                // delete firebase observer handle
                if childAddedHandle != nil {
                    poutfitCommentsRef.removeObserverWithHandle(childAddedHandle!)
                }
            } else if scrollView.contentOffset.y < -80 {
                pullAction?(offset: scrollView.contentOffset)
                
                // delete firebase observer handle
                if childAddedHandle != nil {
                    poutfitCommentsRef.removeObserverWithHandle(childAddedHandle!)
                }
            }
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
    func showMoreOptions(sender: UIButton) {
        let ownerId = user["id"] as! Int
        let pieceId = piece["id"] as! Int
        
        detailsCellActionDelegate?.showMoreOptions(ownerId, targetId: pieceId)
    }
    
    func addComments(sender: UIButton) {
        commentsViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("CommentsView") as? CommentsViewController
        
        if sender == commentRowButton.postCommentButton {
            commentsViewController?.showKeyboard = true
        }
        
        // init
        let pieceId = piece["id"] as! Int
        let pieceImagesString = piece["images"] as! NSString
        let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
        
        let thumbnailURLString = pieceImageDict["thumbnail"] as! String
        
        commentsViewController?.delegate = containerViewController
        commentsViewController?.poutfitImageURL = thumbnailURLString
        commentsViewController?.receiverUsername = user["username"] as! String
        commentsViewController?.poutfitIdentifier = "piece_\(pieceId)"
        
        navController!.delegate = nil
        navController!.pushViewController(commentsViewController!, animated: true)
    }
    
    func retrieveRecentComments(poutfitIdentifier: String) {
        // firebase retrieve 3 most recent comments
        recentComments.removeAll()
        
        poutfitCommentsRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)/comments")
        
        childAddedHandle = poutfitCommentsRef.queryOrderedByChild("created_at").queryLimitedToLast(3).observeEventType(.ChildAdded, withBlock: { snapshot in
            // do some stuff once
            
            if (snapshot.value as? NSNull) != nil {
                // does not exist
                println("Error: (PieceDetailsCell) poutfitCommentsRef does not exist")
            } else {
                // retrieve total number of comments
                let poutfitCommentCountRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)/num_comments")
                
                poutfitCommentCountRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                    if (snapshot.value as? NSNull) != nil {
                        // does not exist
                        println("Error: (PieceDetailsCell) poutfitCommentCountRef does not exist")
                    } else {
                        self.numTotalComments = snapshot.value as! Int
                    }
                })
                
                let commentKey = snapshot.key as String
                let commentRef = firebaseRef.childByAppendingPath("comments/\(commentKey)")
                
                // retreieve comment data
                commentRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                    if (snapshot.value as? NSNull) != nil {
                        // does not exist
                        println("Error: (PieceDetailsCell) commentRef does not exist")
                    } else {
                        var comment = snapshot.value as! NSDictionary
                        
                        self.recentComments.append(comment)
                        
                        if self.recentComments.count > 3 {
                            // remove oldest (first one)
                            self.recentComments.removeAtIndex(0)
                        }

                        self.initPieceDetails()
                    }
                })
            }
        })
        
        // retrieve total number of comments
        let poutfitLikesCountRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)/num_likes")
        
        numTotalLikes = 0
        
        poutfitLikesCountRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if (snapshot.value as? NSNull) != nil {
                // does not exist
                println("Error: (PieceDetailsCell) poutfitLikesCountRef does not exist")
            } else {
                self.numTotalLikes = snapshot.value as! Int
                
                self.initPieceDetails()
            }
        })
    }
}

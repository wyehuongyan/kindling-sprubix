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
import KLCPopup
import ActionSheetPicker_3_0
import TSMessages
import FBSDKShareKit
import SSKeychain

protocol PieceDetailsOutfitProtocol {
    func relevantOutfitSelected(collectionView: UICollectionView, index: NSIndexPath)
}

class PieceDetailsCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, CHTCollectionViewDelegateWaterfallLayout, UIScrollViewDelegate, UIDocumentInteractionControllerDelegate {
    
    var documentController:UIDocumentInteractionController!
    var detailsCellActionDelegate: DetailsCellActions?
    var outfits: [NSDictionary] = [NSDictionary]()
    
    var parentOutfitId: Int? // to detect if this piece was accessed from an outfit
    
    var currentPage: Int?
    var lastPage: Int?
    
    var piece: NSDictionary!
    var user: NSDictionary!
    var inspiredBy: NSDictionary!
    var recentComments: [NSDictionary] = [NSDictionary]()
    var numTotalComments: Int = 0
    var numTotalLikes: Int = 0
    
    // credits
    var postedByButton: SprubixCreditButton!
    
    var liked: Bool?
    var likeButton: UIButton!
    var itemLikesImage: UIButton?
    var itemLikesLabel: UILabel?
    var likeImageView: UIImageView!
    var commentsButton: UIButton!
    
    var priceLabel: UILabel!
    var addToBagButton: UIButton!
    
    var pullAction: ((offset : CGPoint) -> Void)?
    var returnAction: (() -> Void)?
    var tappedAction: (() -> Void)?
    var doubleTappedAction: ((like : Bool) -> Void)?
    
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
    var pieceCoverURL: NSURL!
    
    let viewAllCommentsHeight:CGFloat = 40
    var commentRowButton: SprubixItemCommentRow!
    
    // buy
    var itemBuySizeLabel: UILabel!
    var itemBuyQuantityLabel: UILabel!
    var itemBuyDeliveryLabel: UILabel!
    
    var deliveryMethods: [NSDictionary]?
    var buyPieceInfo: NSMutableDictionary?
    var buyPopup: KLCPopup?
    
    var selectedSize: String?
    var darkenedOverlay: UIView?
    
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
        
        currentPage = 0
        lastPage = 0
        numTotalLikes = 0
    }
    
    func initPieceCollectionView() {
        // layout for outfits tab
        var relatedOutfitsLayout = CHTCollectionViewWaterfallLayout()
        
        relatedOutfitsLayout.sectionInset = UIEdgeInsetsMake(1000, 10, 10, 10)
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
        
        // infinite scrolling
        singlePieceCollectionView.addInfiniteScrollingWithActionHandler({
            self.insertMoreOutfits()
        })
        
        addSubview(singlePieceCollectionView)
        
        initPieceDetails()
        
        // manual dim background because of TSMessage being blocked
        darkenedOverlay = UIView(frame: CGRectMake(0, 0, screenWidth, screenHeight))
        darkenedOverlay?.backgroundColor = UIColor.blackColor()
        darkenedOverlay?.alpha = 0
        
        addSubview(darkenedOverlay!)
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
        
        // piece images horizontal scroll view
        pieceImagesScrollView = UIScrollView(frame: CGRectMake(0, 0, screenWidth, screenWidth))
        pieceImagesScrollView.pagingEnabled = true
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

            if i == 0 {
                pieceCoverURL = NSURL(string: imageDict["original"] as! String)
            }
            
            pieceImageView.frame = CGRect(x: CGFloat(i) * screenWidth, y: 0, width: screenWidth, height: screenWidth)
            pieceImageView.contentMode = UIViewContentMode.ScaleAspectFit
            
            pieceImagesScrollView.addSubview(pieceImageView)
        }
        
        if pieceImagesArray.count > 1 {
            pieceImagesScrollView.scrollEnabled = true
        } else {
            pieceImagesScrollView.scrollEnabled = false
        }
        
        pieceImagesScrollView.contentSize = CGSize(width: screenWidth * CGFloat(pieceImagesArray.count), height: pieceImagesScrollView.frame.size.height)
        
        pieceDetailInfoView.addSubview(pieceImagesScrollView)
        
        // create a page control to show paging indicators
        pageControl = UIPageControl(frame: CGRect(x: 0, y: screenWidth - 40, width: bounds.width, height: 21))
        pageControl.numberOfPages = pieceImagesArray.count
        pageControl.currentPage = 0
        pageControl.clipsToBounds = true
        
        Glow.addGlow(pageControl)
        
        // add gesture recognizers
        var doubleTap = UITapGestureRecognizer(target: self, action: Selector("wasDoubleTapped:"))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        pieceImagesScrollView.addGestureRecognizer(doubleTap)
        
        // like and comment buttons
        let likeButtonWidth = frame.size.width / 10
        likeButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image = UIImage(named: "main-like")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        likeButton.setImage(image, forState: UIControlState.Normal)
        likeButton.setImage(UIImage(named: "main-like-filled"), forState: UIControlState.Selected)
        likeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        likeButton.imageView?.tintColor = sprubixGray
        likeButton.backgroundColor = UIColor.clearColor()
        likeButton.frame = CGRectMake(8 * likeButtonWidth, screenWidth - likeButtonWidth, likeButtonWidth, likeButtonWidth)
        likeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        likeButton.addTarget(self, action: "togglePieceLike:", forControlEvents: UIControlEvents.TouchUpInside)
        likeButton.exclusiveTouch = true
        
        pieceDetailInfoView.addSubview(likeButton)
        Glow.addGlow(likeButton)
        
        // comment button
        commentsButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        image = UIImage(named: "main-comments")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        commentsButton.setImage(image, forState: UIControlState.Normal)
        commentsButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        commentsButton.imageView?.tintColor = sprubixGray
        commentsButton.backgroundColor = UIColor.clearColor()
        commentsButton.frame = CGRectMake(9 * likeButtonWidth, screenWidth - likeButtonWidth, likeButtonWidth, likeButtonWidth)
        commentsButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        commentsButton.addTarget(self, action: "addComments:", forControlEvents: UIControlEvents.TouchUpInside)
        commentsButton.exclusiveTouch = true
        
        pieceDetailInfoView.addSubview(commentsButton)
        Glow.addGlow(commentsButton)
        
        // like heart image
        let likeImageViewWidth:CGFloat = 75
        likeImageView = UIImageView(image: UIImage(named: "main-like-filled-large"))
        likeImageView.frame = CGRect(x: frame.size.width / 2 - likeImageViewWidth / 2, y: 0, width: likeImageViewWidth, height: screenWidth)
        likeImageView.contentMode = UIViewContentMode.ScaleAspectFit
        likeImageView.alpha = 0
        pieceImagesScrollView.addSubview(likeImageView)
        
        // init 'posted by' and 'from' credits
        let creditsViewHeight:CGFloat = 80
        var creditsView:UIView = UIView(frame: CGRect(x: 0, y: screenWidth, width: screenWidth, height: creditsViewHeight))
        
        postedByButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "owned by", username: user["username"] as! String, userThumbnail: user["image"] as! String)
        
        postedByButton.user = user
        
        postedByButton.addTarget(self, action: "creditsShowProfile:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // UILines on top and buttom of button
        var buttonLineBottom = UIView(frame: CGRect(x: 0, y: creditsView.frame.height - 10.0, width: screenWidth, height: 10))
        buttonLineBottom.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        var buttonLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 10))
        buttonLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        creditsView.backgroundColor = UIColor.whiteColor()
        
        creditsView.addSubview(buttonLineTop)
        creditsView.addSubview(buttonLineBottom)
        
        creditsView.addSubview(postedByButton)
        
        pieceDetailInfoView.addSubview(creditsView)
        
        // init piece specifications
        let itemSpecHeight:CGFloat = 55
        var itemSpecHeightTotal:CGFloat = !piece["quantity"]!.isKindOfClass(NSNull) ? itemSpecHeight * 6 : itemSpecHeight * 5
        
        var pieceSpecsView:UIView = UIView(frame: CGRect(x: 0, y: screenWidth + creditsViewHeight, width: screenWidth, height: itemSpecHeightTotal))
        pieceSpecsView.backgroundColor = UIColor.whiteColor()
        
        // generate 5 labels with icons
        let itemImageViewWidth:CGFloat = 0.3 * screenWidth
        
        // likes
        itemLikesImage?.removeFromSuperview()
        itemLikesImage = UIButton.buttonWithType(UIButtonType.Custom) as? UIButton
        itemLikesImage!.setImage(UIImage(named: "main-like"), forState: UIControlState.Normal)
        itemLikesImage!.setImage(UIImage(named: "main-like-filled"), forState: UIControlState.Selected)
        itemLikesImage!.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemLikesImage!.frame = CGRect(x: 0, y: 0, width: itemImageViewWidth, height: itemSpecHeight)
        itemLikesImage!.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        itemLikesImage!.addTarget(self, action: "togglePieceLike:", forControlEvents: UIControlEvents.TouchUpInside)
        itemLikesImage!.selected = likeButton.selected
        
        Glow.addGlow(itemLikesImage!)
        
        itemLikesLabel?.removeFromSuperview()
        itemLikesLabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: 0, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
        refreshItemLikesLabel()
        
        // very first time: check likebutton selected
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let username = userData!["username"] as! String
        let pieceId = piece["id"] as! Int
        
        let poutfitLikesUserRef = firebaseRef.childByAppendingPath("poutfits/piece_\(pieceId)/likes/\(username)")
        
        if liked != nil {
            likeButton.selected = liked!
            itemLikesImage!.selected = liked!
        } else {
            // check if user has already liked this outfit
            poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if (snapshot.value as? NSNull) != nil {
                    // not yet liked
                    self.liked = false
                } else {
                    self.liked = true
                }
                
                self.likeButton.selected = self.liked!
            })
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
        
        var pieceSizesString = piece["size"] as! String
        var pieceSizesData:NSData = pieceSizesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var pieceSizesArray: NSArray = NSJSONSerialization.JSONObjectWithData(pieceSizesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSArray
        
        itemSizeLabel.text = pieceSizesArray.componentsJoinedByString("/")
        
        pieceSpecsView.addSubview(itemLikesImage!)
        pieceSpecsView.addSubview(itemLikesLabel!)
        
        pieceSpecsView.addSubview(itemNameImage)
        pieceSpecsView.addSubview(itemNameLabel)
        
        pieceSpecsView.addSubview(itemCategoryImage)
        pieceSpecsView.addSubview(itemCategoryLabel)
        
        pieceSpecsView.addSubview(itemBrandImage)
        pieceSpecsView.addSubview(itemBrandLabel)
        
        pieceSpecsView.addSubview(itemSizeImage)
        pieceSpecsView.addSubview(itemSizeLabel)
        
        pieceDetailInfoView.addSubview(pieceSpecsView)
        
        let shoppable = user["shoppable"] as! NSDictionary
        let buyable: Bool? = shoppable["purchasable"] as? Bool
        
        if buyable != nil && buyable! != false && piece["price"] as! String != "0.00" {
            if !piece["quantity"]!.isKindOfClass(NSNull) {
                // price label
                let padding: CGFloat = 10
                let priceLabelHeight: CGFloat = 35
                priceLabel = UILabel()
                priceLabel.textAlignment = NSTextAlignment.Center
                priceLabel.font = UIFont.boldSystemFontOfSize(18.0)
                
                let price = piece["price"] as! String
                priceLabel.text = "$\(price)"
                priceLabel.frame = CGRectMake(screenWidth - (priceLabel.intrinsicContentSize().width + 20.0) - padding, padding, (priceLabel.intrinsicContentSize().width + 20.0), priceLabelHeight)
                
                priceLabel.layer.cornerRadius = priceLabelHeight / 2
                priceLabel.clipsToBounds = true
                priceLabel.textColor = UIColor.whiteColor()
                priceLabel.backgroundColor = sprubixColor
                
                pieceDetailInfoView.addSubview(priceLabel)
                
                // quantity spec
                var itemQuantityImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                itemQuantityImage.setImage(UIImage(named: "view-item-quantity"), forState: UIControlState.Normal)
                itemQuantityImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                itemQuantityImage.frame = CGRect(x: 0, y: itemSpecHeight * 5, width: itemImageViewWidth, height: itemSpecHeight)
                itemQuantityImage.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
                
                Glow.addGlow(itemQuantityImage)
                
                var itemQuantityLabel:UILabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: itemSpecHeight * 5, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))

                var pieceQuantityString = piece["quantity"] as! String
                var pieceQuantityData:NSData = pieceQuantityString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var pieceQuantityDict = NSJSONSerialization.JSONObjectWithData(pieceQuantityData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                var total = 0
                
                for (size, pieceQuantity) in pieceQuantityDict {
                    total += (pieceQuantity as! String).toInt()!
                }
                
                itemQuantityLabel.text = "\(total) left in stock"
                
                pieceSpecsView.addSubview(itemQuantityImage)
                pieceSpecsView.addSubview(itemQuantityLabel)
                
                let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                let userType = userData!["shoppable_type"] as! String
                
                if userType.lowercaseString.rangeOfString("shopper") != nil {
                    // add to bag CTA button
                    addToBagButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
                    addToBagButton.backgroundColor = sprubixColor
                    
                    var image: UIImage = UIImage(named: "sidemenu-cart")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    
                    addToBagButton.setImage(image, forState: UIControlState.Normal)
                    addToBagButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                    addToBagButton.imageView?.tintColor = UIColor.whiteColor()
                    addToBagButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)

                    addToBagButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16.0)
                    addToBagButton.setTitle("Buy Now", forState: UIControlState.Normal)
                    addToBagButton.addTarget(self, action: "addToBagButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                    
                    addSubview(addToBagButton)
                }
                
                // add info into buyPieceInfo
                buyPieceInfo = NSMutableDictionary()
                buyPieceInfo?.setObject(piece["id"] as! Int, forKey: "piece_id")
                buyPieceInfo?.setObject(piece["user_id"] as! Int, forKey: "seller_id")
                
                if parentOutfitId != nil {
                    // this piece was accessed via an outfit
                    // // points!
                    buyPieceInfo?.setObject(parentOutfitId!, forKey: "outfit_id")
                }
                
            } else {
                println("quantity is 0, not enough for sale")
            }
        }
        
        // init piece description
        var itemDescription:SprubixItemDescription = SprubixItemDescription()
        itemDescription.lineBreakMode = NSLineBreakMode.ByWordWrapping
        itemDescription.numberOfLines = 0
        itemDescription.backgroundColor = UIColor.whiteColor()
        itemDescription.text = piece["description"] as? String
        itemDescription.textColor = UIColor.darkGrayColor()
        
        var itemDescriptionHeight = heightForTextLabel(itemDescription.text!, font: itemDescription.font, width: screenWidth - 40, padding: 20)
        
        itemDescription.frame = CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal, width: screenWidth, height: itemDescriptionHeight)
        itemDescription.drawTextInRect(CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal, width: screenWidth, height: itemDescriptionHeight))
        
        var itemDescriptionLineTop = UIView(frame: CGRect(x: 0, y: itemDescription.frame.origin.y, width: screenWidth, height: 2))
        itemDescriptionLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        pieceDetailInfoView.addSubview(itemDescription)
        pieceDetailInfoView.addSubview(itemDescriptionLineTop)
        
        // init social buttons
        var socialButtonsRow: UIView = UIView()
        
        // Social Label
        let socialLabelY: CGFloat = 10
        let socialLabelHeight: CGFloat = 20
        let socialLabel: UILabel = UILabel(frame: CGRect(x: 20, y: socialLabelY, width: screenWidth, height: socialLabelHeight))
        socialLabel.text = "Share this item"
        socialLabel.textColor = UIColor.lightGrayColor()
        
        socialButtonsRow.addSubview(socialLabel)
        
        let socialButtonRow1Y: CGFloat = socialLabelY + socialLabelHeight - 3
        var socialButtonRow1: UIView = UIView(frame: CGRect(x: 0, y: socialButtonRow1Y, width: screenWidth, height: 44))

        // Facebook
        var socialImageFacebook = UIImage(named: "spruce-share-fb")
        var socialButtonFacebook: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        socialButtonFacebook.setImage(socialImageFacebook, forState: UIControlState.Normal)
        socialButtonFacebook.setTitle("Facebook", forState: UIControlState.Normal)
        socialButtonFacebook.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        socialButtonFacebook.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        socialButtonFacebook.frame = CGRect(x: 0, y: 10, width: screenWidth/2, height: 44)
        socialButtonFacebook.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        socialButtonFacebook.imageEdgeInsets = UIEdgeInsetsMake(5, 20, 5, 0)
        socialButtonFacebook.titleEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 0)
        socialButtonFacebook.addTarget(self, action: "facebookTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Instagram
        var socialImageInstagram = UIImage(named: "spruce-share-ig")
        var socialButtonInstagram: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        socialButtonInstagram.setImage(socialImageInstagram, forState: UIControlState.Normal)
        socialButtonInstagram.setTitle("Instagram", forState: UIControlState.Normal)
        socialButtonInstagram.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        socialButtonInstagram.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        socialButtonInstagram.frame = CGRect(x: screenWidth/2, y: 10, width: screenWidth/2, height: 44)
        socialButtonInstagram.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        socialButtonInstagram.imageEdgeInsets = UIEdgeInsetsMake(3, 10, 3, 0)
        socialButtonInstagram.titleEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 0)
        socialButtonInstagram.addTarget(self, action: "instagramTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var socialButtonsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
        socialButtonsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        
        socialButtonRow1.addSubview(socialButtonFacebook)
        socialButtonRow1.addSubview(socialButtonInstagram)
        socialButtonsRow.addSubview(socialButtonRow1)
        socialButtonsRow.addSubview(socialButtonsLineTop)
        
        let socialButtonsRowY: CGFloat = screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight
        let socialButtonsRowHeight: CGFloat = socialLabelY + socialLabelHeight + 44 + 15
        socialButtonsRow.frame = CGRect(x: 0, y: socialButtonsRowY, width: screenWidth, height: socialButtonsRowHeight)
        socialButtonsRow.backgroundColor = UIColor.whiteColor()
        
        pieceDetailInfoView.addSubview(socialButtonsRow)
        
        // init comments
        let commentYPos:CGFloat = screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight + viewAllCommentsHeight + socialButtonsRowHeight
        
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
        image = UIImage(named: "more-dots")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        viewMore.frame = CGRectMake(viewAllComments.frame.size.width, 0, screenWidth - viewAllComments.frame.size.width, viewAllCommentsHeight)
        viewMore.setImage(image, forState: UIControlState.Normal)
        viewMore.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 16)
        viewMore.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        viewMore.imageView?.tintColor = sprubixGray
        viewMore.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Right
        viewMore.backgroundColor = UIColor.clearColor()
        viewMore.addTarget(self, action: "showMoreOptions:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var viewAllCommentsBG:UIView = UIView(frame: CGRect(x: 0, y: screenWidth + creditsViewHeight + itemSpecHeightTotal + itemDescriptionHeight + socialButtonsRowHeight, width: screenWidth, height: viewAllCommentsHeight))
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
        
        var outfitsUsingLabel:UILabel = UILabel(frame: CGRectInset(CGRect(x: 0, y: commentYPos + commentSectionHeight, width: screenWidth, height: 70), 10, 15))
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
                self.currentPage = responseObject["current_page"] as? Int
                self.lastPage = responseObject["last_page"] as? Int
                self.outfits = responseObject["data"] as! [NSDictionary]
                self.singlePieceCollectionView.reloadData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    private func insertMoreOutfits() {
        if currentPage < lastPage {
            let pieceId:Int = piece["id"] as! Int
            let nextPage = currentPage! + 1
            
            // retrieve outfits using this piece
            manager.GET(SprubixConfig.URL.api + "/piece/\(pieceId)/outfits?page=\(nextPage)",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    let moreOutfits = responseObject["data"] as! [NSDictionary]
                    
                    for moreOutfit in moreOutfits {
                        self.outfits.append(moreOutfit)
                        
                        self.singlePieceCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.outfits.count - 1, inSection: 0)])
                    }
                    
                    self.currentPage = nextPage
                    
                    if self.singlePieceCollectionView.infiniteScrollingView != nil {
                        self.singlePieceCollectionView.infiniteScrollingView.stopAnimating()
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    if self.singlePieceCollectionView.infiniteScrollingView != nil {
                        self.singlePieceCollectionView.infiniteScrollingView.stopAnimating()
                    }
            })
        } else {
            if self.singlePieceCollectionView.infiniteScrollingView != nil {
                self.singlePieceCollectionView.infiniteScrollingView.stopAnimating()
            }
        }
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
        relatedOutfitsLayout.footerHeight = 10 + navigationHeight // navigationHeight is height of buy CTA
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
        outfitDetailsViewController.delegate = containerViewController.mainInstance()
        
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
    
    func heightForTextLabel(text:String, font:UIFont, width:CGFloat, padding: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height + padding
    }
    
    // gesture recognizers 
    func wasDoubleTapped(gesture: UITapGestureRecognizer) {
        likeButton.selected = true
        liked = true
        doubleTappedAction?(like: true)
        animateHeart()
    }
    
    func refreshItemLikesLabel() {
        if numTotalLikes != 0 {
            itemLikesLabel!.text = numTotalLikes > 1 ? "\(numTotalLikes) people like this" : "\(numTotalLikes) person likes this"
        } else {
            itemLikesLabel!.text = "Be the first to like!"
        }
    }
    
    func togglePieceLike(sender: UIButton) {
        if sender.selected != true {
            sender.selected = true
            likeButton.selected = true
            itemLikesImage?.selected = true
            
            liked = true
            doubleTappedAction?(like: true)
            animateHeart()
            
            numTotalLikes += 1
        } else {
            sender.selected = false
            likeButton.selected = false
            itemLikesImage?.selected = false
            
            liked = false
            doubleTappedAction?(like: false)
            
            if numTotalLikes > 0 {
                numTotalLikes -= 1
            }
        }
        
        refreshItemLikesLabel()
    }
    
    func creditsShowProfile(sender: UIButton) {
        containerViewController.showUserProfile(postedByButton.user!)

        // Mixpanel - Viewed User Profile, Piece View
        mixpanel.track("Viewed User Profile", properties: [
            "Source": "Piece View",
            "Tab": "Outfit",
            "Target User ID": piece["user_id"] as! Int
        ])
        // Mixpanel - End
    }

    func animateHeart() {
        if likeImageView != nil {
            UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.likeImageView!.alpha = 1.0
                }, completion: { finished in
                    if finished {
                        UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                            self.likeImageView!.alpha = 0.0
                            }, completion: nil)
                    }
            })
        }
    }
    
    // button callbacks
    func addToBagButtonPressed(sender: UIButton) {
        
        // user is logged out, need to reauthenticate
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        // user is logged in
        if userData != nil {
            let username = userData!["username"] as! String
            let country: String? = defaults.objectForKey("userCountry") as? String
            
            // check only in production
            if SprubixConfig.URL.api == "https://api.sprbx.com" {
                if country != nil && contains(countriesAvailable, country!) {
                    showBuyPopup()
                } else {
                    var alert = UIAlertController(title: "We hear you!", message: "Currently, Sprubix commerce is only available in Singapore.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.view.tintColor = sprubixColor
                    
                    // Yes
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { action in
                    }))
                    
                    self.navController?.presentViewController(alert, animated: true, completion: nil)
                }
            } else {
                // staging and dev
                // just show the popup
                showBuyPopup()
            }
        }
    }
    
    func showBuyPopup() {
        let itemSpecHeight:CGFloat = 45
        let popupWidth: CGFloat = screenWidth - 100
        let popupHeight: CGFloat = popupWidth + itemSpecHeight * 3 + navigationHeight
        let itemImageViewWidth:CGFloat = 0.25 * popupWidth
        
        let popupContentView: UIView = UIView(frame: CGRectMake(0, 0, popupWidth, popupHeight))
        popupContentView.backgroundColor = UIColor.whiteColor()
        popupContentView.layer.cornerRadius = 12.0
        
        let buyPieceView: UIView = UIView(frame: popupContentView.bounds)
        
        // add content to popupContentView
        var buyPiecesScrollView = UIScrollView(frame: CGRectMake(0, 0, popupWidth, popupHeight))
        buyPiecesScrollView.layer.cornerRadius = 12.0
        buyPiecesScrollView.pagingEnabled = true
        buyPiecesScrollView.alwaysBounceHorizontal = true
        
        var pieceImagesString = piece["images"] as! String
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        let imageURL = NSURL(string: pieceImagesDict["cover"] as! String)
        
        // cover image
        var buyPieceImage: UIImageView = UIImageView(frame: CGRectMake(0, 0, popupWidth, popupWidth))
        buyPieceImage.backgroundColor = sprubixGray
        buyPieceImage.contentMode = UIViewContentMode.ScaleAspectFit
        buyPieceImage.setImageWithURL(imageURL)
        
        // price label
        let padding: CGFloat = 10
        let priceLabelHeight: CGFloat = 35
        var buyPriceLabel = UILabel()
        buyPriceLabel.textAlignment = NSTextAlignment.Center
        buyPriceLabel.font = UIFont.boldSystemFontOfSize(18.0)
        
        let price = piece["price"] as! String
        buyPriceLabel.text = "$\(price)"
        buyPriceLabel.frame = CGRectMake(buyPieceImage.frame.width - (buyPriceLabel.intrinsicContentSize().width + 20.0) - padding, padding, (buyPriceLabel.intrinsicContentSize().width + 20.0), priceLabelHeight)
        
        buyPriceLabel.layer.cornerRadius = priceLabelHeight / 2
        buyPriceLabel.clipsToBounds = true
        buyPriceLabel.textColor = UIColor.whiteColor()
        buyPriceLabel.backgroundColor = sprubixColor
        
        buyPieceImage.addSubview(buyPriceLabel)
        
        buyPieceView.addSubview(buyPieceImage)
        
        // size
        var itemSizeImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemSizeImage.setImage(UIImage(named: "view-item-size"), forState: UIControlState.Normal)
        itemSizeImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemSizeImage.frame = CGRect(x: 0, y: popupWidth, width: itemImageViewWidth, height: itemSpecHeight)
        itemSizeImage.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
        
        Glow.addGlow(itemSizeImage)
        
        var itemSizeButton: UIButton = UIButton(frame: CGRect(x: itemImageViewWidth, y: popupWidth, width: popupWidth - itemImageViewWidth, height: itemSpecHeight))
        itemBuySizeLabel = UILabel(frame: itemSizeButton.bounds)
        itemBuySizeLabel.text = "Select size"
        itemBuySizeLabel.font = UIFont.systemFontOfSize(14.0)
        itemBuySizeLabel.textColor = UIColor.lightGrayColor()
        
        itemSizeButton.addSubview(itemBuySizeLabel)
        itemSizeButton.addTarget(self, action: "selectBuySize:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // quantity
        var itemQuantityImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemQuantityImage.setImage(UIImage(named: "view-item-quantity"), forState: UIControlState.Normal)
        itemQuantityImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemQuantityImage.frame = CGRect(x: 0, y: popupWidth + itemSpecHeight, width: itemImageViewWidth, height: itemSpecHeight)
        itemQuantityImage.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
        
        Glow.addGlow(itemQuantityImage)
        
        var itemQuantityButton: UIButton = UIButton(frame: CGRect(x: itemImageViewWidth, y: popupWidth + itemSpecHeight, width: popupWidth - itemImageViewWidth, height: itemSpecHeight))
        itemBuyQuantityLabel = UILabel(frame: itemQuantityButton.bounds)
        itemBuyQuantityLabel.text = "Select quantity"
        itemBuyQuantityLabel.font = UIFont.systemFontOfSize(14.0)
        itemBuyQuantityLabel.textColor = UIColor.lightGrayColor()
        
        itemQuantityButton.addSubview(itemBuyQuantityLabel)
        itemQuantityButton.addTarget(self, action: "selectBuyQuantity:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // delivery method
        var itemDeliveryImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var deliveryImage: UIImage = UIImage(named: "sidemenu-fulfilment")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        itemDeliveryImage.setImage(deliveryImage, forState: UIControlState.Normal)
        itemDeliveryImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemDeliveryImage.imageView?.tintColor = UIColor.whiteColor()
        itemDeliveryImage.frame = CGRect(x: 0, y: popupWidth + itemSpecHeight * 2, width: itemImageViewWidth, height: itemSpecHeight)
        itemQuantityImage.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
        
        Glow.addGlow(itemDeliveryImage)
        
        var itemDeliveryButton: UIButton = UIButton(frame: CGRect(x: itemImageViewWidth, y: popupWidth + itemSpecHeight * 2, width: popupWidth - itemImageViewWidth, height: itemSpecHeight))
        itemBuyDeliveryLabel = UILabel(frame: itemDeliveryButton.bounds)
        itemBuyDeliveryLabel.text = "Select delivery method"
        itemBuyDeliveryLabel.font = UIFont.systemFontOfSize(14.0)
        itemBuyDeliveryLabel.textColor = UIColor.lightGrayColor()
        
        itemDeliveryButton.addSubview(itemBuyDeliveryLabel)
        itemDeliveryButton.addTarget(self, action: "selectBuyDeliveryMethod:", forControlEvents: UIControlEvents.TouchUpInside)
        
        buyPieceView.addSubview(itemSizeImage)
        buyPieceView.addSubview(itemSizeButton)
        
        buyPieceView.addSubview(itemQuantityImage)
        buyPieceView.addSubview(itemQuantityButton)
        
        buyPieceView.addSubview(itemDeliveryImage)
        buyPieceView.addSubview(itemDeliveryButton)
        
        buyPiecesScrollView.addSubview(buyPieceView)
        popupContentView.addSubview(buyPiecesScrollView)
        
        // add to cart button
        var addToCart: UIButton = UIButton(frame: CGRectMake(0, popupHeight - navigationHeight, popupWidth, navigationHeight))
        addToCart.backgroundColor = sprubixColor
        addToCart.setTitle("Add to Cart", forState: UIControlState.Normal)
        addToCart.titleLabel?.font = UIFont.boldSystemFontOfSize(addToCart.titleLabel!.font.pointSize)
        addToCart.addTarget(self, action: "addToCartPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        buyPieceView.addSubview(addToCart)
        
        // load the delivery methods for this piece
        preloadBuyDeliveryMethod()
        
        buyPopup = KLCPopup(contentView: popupContentView, showType: KLCPopupShowType.BounceInFromTop, dismissType: KLCPopupDismissType.BounceOutToTop, maskType: KLCPopupMaskType.Clear, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
        
        // dim background
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            darkenedOverlay?.alpha = 0.5
            }, completion: nil)
        
        buyPopup?.willStartDismissingCompletion = {
            // brighten background
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                darkenedOverlay?.alpha = 0.0
                }, completion: nil)
            
            self.selectedSize = nil
            self.buyPieceInfo?.removeObjectsForKeys(["size", "quantity", "delivery_option_id"])
        }
        
        buyPopup?.show()
        
        // Mixpanel - Clicked Buy, Piece View
        mixpanel.track("Clicked Buy", properties: [
            "Source": "Piece View",
            "Piece ID": piece["id"] as! Int
            ])
    }
    
    func selectBuySize(sender: UIButton) {
        var pieceSizesString = piece["size"] as? String
        
        if pieceSizesString != nil {
            var pieceSizesData:NSData = pieceSizesString!.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceSizesArray: NSArray = NSJSONSerialization.JSONObjectWithData(pieceSizesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSArray
            
            let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Size", rows: pieceSizesArray as! [String], initialSelection: 0,
                doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                    
                    // add info to buyPieceInfo
                    self.buyPieceInfo?.setObject(selectedValue, forKey: "size")
                    
                    self.itemBuySizeLabel.text = "\(selectedValue)"
                    self.itemBuySizeLabel.textColor = UIColor.blackColor()
                    
                    self.selectedSize = selectedValue as? String
                    
                }, cancelBlock: nil, origin: sender)
            
            // custom done button
            let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
            
            doneButton.setTitleTextAttributes([
                NSForegroundColorAttributeName: sprubixColor,
                ], forState: UIControlState.Normal)
            
            picker.setDoneButton(doneButton)
            
            // custom cancel button
            var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            
            cancelButton.setTitle("X", forState: UIControlState.Normal)
            cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
            cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            
            picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
            
            picker.showActionSheetPicker()
        }
    }
    
    func selectBuyQuantity(sender: UIButton) {
        if selectedSize != nil {
            // create quantity array
            var quantityArray: [Int] = [Int]()
            
            if !piece["quantity"]!.isKindOfClass(NSNull) {
                var pieceQuantityString = piece["quantity"] as! String
                var pieceQuantityData:NSData = pieceQuantityString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var pieceQuantityDict = NSJSONSerialization.JSONObjectWithData(pieceQuantityData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
                for var i = 1; i <= (pieceQuantityDict[selectedSize!] as! String).toInt(); i++ {
                    quantityArray.append(i)
                }
                
                let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Quantity", rows: quantityArray, initialSelection: 0,
                    doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                        
                        // add info to buyPieceInfo
                        self.buyPieceInfo?.setObject(selectedValue, forKey: "quantity")
                        
                        self.itemBuyQuantityLabel.text = "\(selectedValue)"
                        self.itemBuyQuantityLabel.textColor = UIColor.blackColor()
                        
                    }, cancelBlock: nil, origin: sender)
                
                // custom done button
                let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
                
                doneButton.setTitleTextAttributes([
                    NSForegroundColorAttributeName: sprubixColor,
                    ], forState: UIControlState.Normal)
                
                picker.setDoneButton(doneButton)
                
                // custom cancel button
                var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                
                cancelButton.setTitle("X", forState: UIControlState.Normal)
                cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
                cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                
                picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
                
                picker.showActionSheetPicker()
            }
        } else {
            println("Please select size first")
        }
    }
    
    func preloadBuyDeliveryMethod() {
        // REST call to server to retrieve delivery methods
        var shopId: Int? = user["id"] as? Int
        
        if shopId != nil {
            manager.POST(SprubixConfig.URL.api + "/delivery/options",
                parameters: [
                    "user_id": shopId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    self.deliveryMethods = responseObject["data"] as? [NSDictionary]
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    func selectBuyDeliveryMethod(sender: UIButton) {
        if deliveryMethods != nil {
            showBuyDeliveryMethodPicker(sender)
        }
    }
    
    private func showBuyDeliveryMethodPicker(sender: UIButton) {
        // create delivery array
        var deliveryArray: [String] = [String]()
        var deliveryIdsArray: [Int] = [Int]()
        
        for deliveryOption in deliveryMethods! {
            let deliveryOptionName = deliveryOption["name"] as! String
            let deliveryOptionPrice = deliveryOption["price"] as! String
            let deliveryOptionId = deliveryOption["id"] as! Int
            let deliveryOptionEstimatedTime = deliveryOption["estimated_time"] as! Int
            
            deliveryArray.append("$\(deliveryOptionPrice) \(deliveryOptionEstimatedTime) days (\(deliveryOptionName))")
            deliveryIdsArray.append(deliveryOptionId)
        }
        
        let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Delivery method", rows: deliveryArray, initialSelection: 0,
            doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                
                if deliveryIdsArray.count > 0 {
                    let selectedDeliveryId = deliveryIdsArray[selectedIndex]
                    
                    // add info to buyPieceInfo
                    self.buyPieceInfo?.setObject(selectedDeliveryId, forKey: "delivery_option_id")
                    
                    self.itemBuyDeliveryLabel.text = "\(selectedValue)"
                    self.itemBuyDeliveryLabel.textColor = UIColor.blackColor()
                }
                
            }, cancelBlock: nil, origin: sender)
        
        // custom done button
        let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        doneButton.setTitleTextAttributes([
            NSForegroundColorAttributeName: sprubixColor,
            ], forState: UIControlState.Normal)
        
        picker.setDoneButton(doneButton)
        
        // custom cancel button
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        cancelButton.setTitle("X", forState: UIControlState.Normal)
        cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
        
        picker.showActionSheetPicker()
    }
    
    func addToCartPressed(sender: UIButton) {
        let userId: Int? = defaults.objectForKey("userId") as? Int
        
        if  buyPieceInfo?.objectForKey("size") != nil &&
            buyPieceInfo?.objectForKey("quantity") != nil &&
            buyPieceInfo?.objectForKey("delivery_option_id") != nil {

            if userId != nil && buyPieceInfo != nil {
                buyPieceInfo?.setObject(userId!, forKey: "buyer_id")
                
                // REST call to server to create cart item and add to user's cart
                manager.POST(SprubixConfig.URL.api + "/cart/item/add",
                    parameters: buyPieceInfo!,
                    success: { (operation: AFHTTPRequestOperation!, responseObject:
                        AnyObject!) in
                        
                        var status = responseObject["status"] as! String
                        var automatic: NSTimeInterval = 0
                        
                        if status == "200" {
                            // success
                            TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Item added to cart", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                            
                            // Mixpanel - Added to Cart, Piece View, Success
                            mixpanel.track("Added To Cart", properties: [
                                "Source": "Piece View",
                                "Piece ID": self.buyPieceInfo!.objectForKey("piece_id") as! Int,
                                "Status": "Success"
                            ])
                        } else {
                            // error exception
                            TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                            
                            // Mixpanel - Added to Cart, Piece View, Fail
                            mixpanel.track("Added To Cart", properties: [
                                "Source": "Piece View",
                                "Piece ID": self.buyPieceInfo!.objectForKey("piece_id") as! Int,
                                "Status": "Fail"
                            ])
                        }
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            }
        } else {
            var automatic: NSTimeInterval = 0
            
            // warning message
            TSMessage.showNotificationInViewController(TSMessage.defaultViewController(), title: "Oops!", subtitle: "Please complete all fields before adding to cart.", image: nil, type: TSMessageNotificationType.Warning, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
        }
    }

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
        commentsViewController?.receiverId = user["id"] as! Int
        commentsViewController?.poutfitIdentifier = "piece_\(pieceId)"
        
        navController!.delegate = nil
        navController!.pushViewController(commentsViewController!, animated: true)
        
        // Mixpanel - Viewed Piece Comments
        mixpanel.track("Viewed Piece Comments", properties: [
            "Source": "Piece View",
            "Piece ID": pieceId,
            "Owner User ID": piece["user_id"] as! Int
        ])
        mixpanel.people.increment("Piece Comments Viewed", by: 1)
        // Mixpanel - End
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
        
        retrieveTotalLikes(poutfitIdentifier)
    }
    
    func retrieveTotalLikes(poutfitIdentifier: String) {
        // retrieve total number of likes
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
    
    func facebookTapped(sender: UIButton) {
        let pieceImagesString = piece["images"] as! String
        let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
        let pieceThumbnailUrl = pieceImageDict["thumbnail"] as! String
        
        let content : FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = NSURL(string: "http://www.sprubix.com/")
        content.contentTitle = piece["name"] as! String
        content.contentDescription = "Check this item out! Download the Sprubix app now."
        content.imageURL = NSURL(string: pieceThumbnailUrl)
        
        let button : FBSDKShareButton = FBSDKShareButton()
        button.shareContent = content
        button.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        
        // Mixpanel - Share, Facebook
        mixpanel.track("Share", properties: [
            "Type": "Piece",
            "Platform": "Facebook"
        ])
        // Mixpanel - End
    }
    
    func instagramTapped(sender: UIButton) {
        let instagramUrl = NSURL(string: "instagram://app")
        if(UIApplication.sharedApplication().canOpenURL(instagramUrl!)){
            
            // calculate resized image for IG
            var data = NSData(contentsOfURL: pieceCoverURL)
            var pieceImage: UIImage = UIImage(data: data!)!
            
            var IGFrameWidth: CGFloat = 750.0
            var IGFrameHeight: CGFloat = 750.0 //(IGFrameWidth / 4) * 5
            var IGFrameSize: CGSize = CGSizeMake(IGFrameWidth, IGFrameHeight)
            
            // outfit height needs to be equal to IGFrameHeight
            var realWidth: CGFloat = pieceImage.scale * pieceImage.size.width
            var realHeight: CGFloat = pieceImage.scale * pieceImage.size.height
            
            var finalWidth: CGFloat = realWidth
            var finalHeight: CGFloat = realHeight
            
            if realHeight > realWidth {
                // if item's height is longer than its width
                // height will be equal to IGFrameHeight
                
                finalHeight = IGFrameHeight
                finalWidth = (realWidth / realHeight) * finalHeight
            }
            
            UIGraphicsBeginImageContextWithOptions(IGFrameSize, false, 0.0) // avoid image quality degrading
            
            pieceImage.drawInRect(CGRectMake((IGFrameWidth - finalWidth)/2, (IGFrameHeight - finalHeight)/2, finalWidth, finalHeight))
            
            // final image
            var finalImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            //Instagram App avaible
            let imageData = UIImageJPEGRepresentation(finalImage, 0.9)
            let captionString = piece["description"] as! String
            let writePath = NSTemporaryDirectory().stringByAppendingPathComponent("instagram.igo")
            
            // copy description to clipboard
            UIPasteboard.generalPasteboard().string = captionString != "" ? captionString + " @sprubix #sprubix" : "@sprubix #sprubix"
            
            if(!imageData.writeToFile(writePath, atomically: true)){
                //Fail to write. Don't post it
                return
            } else{
                //Safe to post
                var alert = UIAlertController(title: "Ready for Instagram", message: "The description has been copied to your clipboard!", preferredStyle: UIAlertControllerStyle.Alert)
                alert.view.tintColor = sprubixColor
                
                // Yes
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { action in
                    
                    let fileURL = NSURL(fileURLWithPath: writePath)
                    self.documentController = UIDocumentInteractionController(URL: fileURL!)
                    self.documentController.delegate = self
                    self.documentController.UTI = "com.instagram.exclusivegram"
                    self.documentController.annotation =  NSDictionary(object: captionString, forKey: "InstagramCaption")
                    
                    var view = self.navController!.view as UIView
                    
                    self.documentController.presentOpenInMenuFromRect(view.frame, inView: view, animated: true)
                    
                    // Mixpanel - Share, Instagram
                    mixpanel.track("Share", properties: [
                        "Type": "Piece",
                        "Platform": "Instagram"
                        ])
                    // Mixpanel - End
                }))
                
                self.navController!.presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            //Instagram App NOT avaible...
            var automatic: NSTimeInterval = 0
            
            // warning message
            TSMessage.showNotificationInViewController(TSMessage.defaultViewController(), title: "Oops!", subtitle: "Please install Instagram before sharing.", image: nil, type: TSMessageNotificationType.Warning, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
        }
    }
    
}

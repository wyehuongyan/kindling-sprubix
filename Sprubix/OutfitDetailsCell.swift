//
//  OutfitDetailsCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import KLCPopup
import ActionSheetPicker_3_0
import TSMessages
import FBSDKShareKit
import JDFTooltips
import SSKeychain

@objc
protocol DetailsCellActions {
    func showMoreOptions(ownerId: Int, targetId: Int)
    optional func setOutfitsLiked(outfitId: Int, liked: Bool)
    optional func likedOutfit(outfitId: Int, thumbnailURLString: String, itemIdentifier: String, receiver: NSDictionary)
    optional func unlikedOutfit(outfitId: Int, itemIdentifier: String, receiver: NSDictionary)
}

class OutfitDetailsCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, PieceInteractionProtocol, UIDocumentInteractionControllerDelegate {
    
    var documentController:UIDocumentInteractionController!
    var delegate: DetailsCellActions?
    var selectedPieceDetail: NSDictionary?
    
    var navController: UINavigationController?
    var commentsViewController: CommentsViewController?
    
    var imageName: String?

    var pullAction: ((offset : CGPoint) -> Void)?
    var returnAction: (() -> Void)?
    var tappedAction: (() -> Void)?
    
    let tableView = UITableView(frame: screenBounds, style: UITableViewStyle.Plain)
    
    var outfit: NSDictionary!
    var pieces: [NSDictionary]!
    var buyPieces: [NSDictionary] = [NSDictionary]()
    var deletedPieces: [NSDictionary] = [NSDictionary]()
    var piecesLiked: NSMutableDictionary = NSMutableDictionary()
    var user: NSDictionary!
    var inspiredBy: NSDictionary!
    var recentComments: [NSDictionary] = [NSDictionary]()
    var numTotalComments: Int = 0
    
    var itemLikesImage: UIButton?
    var itemLikesLabel: UILabel?
    var numTotalLikes: Int = 0
    
    // credits
    var postedByButton: SprubixCreditButton!
    var fromButton: SprubixCreditButton!
    
    var pieceImageView: UIImageView!
    var pieceImages: [UIImageView] = [UIImageView]()
    var likeImageView: UIImageView!
    var likeImagesDict: NSMutableDictionary = NSMutableDictionary()
    var likeButton: UIButton!
    var likeButtons: [UIButton] = [UIButton]()
    var likeButtonsDict: NSMutableDictionary = NSMutableDictionary()
    var commentsButton: UIButton!
    var commentsButtons: [UIButton] = [UIButton]()
    var findSimilarButtons: [UIButton] = [UIButton]()
    
    var purchasable: Bool = false
    var addToBagButton: UIButton!
    var priceLabel: UILabel!
    var userThumbnail: UIImageView!
    
    let pullLabel: UILabel = UILabel()
    
    var outfitImageCell: UITableViewCell!
    var creditsCell: UITableViewCell!
    var descriptionCell: UITableViewCell!
    var specificationCell: UITableViewCell!
    var socialCell: UITableViewCell!
    var commentsCell: UITableViewCell!
    
    // buy
    var itemBuySizeLabel: UILabel!
    var itemBuyQuantityLabel: UILabel!
    var itemBuyDeliveryLabel: UILabel!
    
    var itemBuySizeLabels: [UILabel] = [UILabel]()
    var itemBuyQuantityLabels: [UILabel] = [UILabel]()
    var itemBuyDeliveryLabels: [UILabel] = [UILabel]()
    
    var buyPieceViews: [UIView] = [UIView]()
    
    var deliveryMethods: [Int: [NSDictionary]] = [Int: [NSDictionary]]()
    var buyPieceInfo: NSMutableDictionary?
    var buyPiecesInfo: NSMutableDictionary = NSMutableDictionary()
    var buyPopup: KLCPopup?
    
    var selectedSizes: [String] = [String]()
    var darkenedOverlay: UIView?
    
    let itemSpecHeight: CGFloat = 55
    let viewAllCommentsHeight: CGFloat = 40
    var commentRowButton: SprubixItemCommentRow!
    
    // firebase
    var childAddedHandle: UInt?
    var poutfitCommentsRef: Firebase!
    var liked: Bool?
    
    // social button
    var socialButtonFacebook: UIButton!
    var socialButtonInstagram: UIButton!
    
    // spruce button
    var spruceButton: UIButton!
    var spruceButtonLine: UIView!
    
    // tooltip
    var tooltipManager: JDFSequentialTooltipManager!
    let tooltipWidth: CGFloat = screenWidth / 2
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // retrieve 3 most recent comments
        let outfitId = outfit["id"] as! Int
        retrieveRecentComments("outfit_\(outfitId)")
        
        tableView.reloadData()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        pullLabel.removeFromSuperview()
        pieceImageView.removeFromSuperview()
        
        if childAddedHandle != nil {
            poutfitCommentsRef.removeObserverWithHandle(childAddedHandle!)
            
            childAddedHandle = nil
            numTotalComments = 0
        }
        
        numTotalLikes = 0
        purchasable = false
    }
    
    func initOutfitTableView() {
        tableView.backgroundColor = UIColor.whiteColor()
        
        contentView.addSubview(tableView)
        
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorColor = UIColor.clearColor()
        tableView.delaysContentTouches = false
        tableView.delegate = self
        tableView.dataSource = self
        
        self.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight;
        
        outfitImageCell = UITableViewCell()
        creditsCell = UITableViewCell()
        descriptionCell = UITableViewCell()
        specificationCell = UITableViewCell()
        socialCell = UITableViewCell()
        commentsCell = UITableViewCell()
        
        outfitImageCell.backgroundColor = UIColor.whiteColor()
        creditsCell.backgroundColor = UIColor.whiteColor()
        descriptionCell.backgroundColor = UIColor.whiteColor()
        specificationCell.backgroundColor = UIColor.whiteColor()
        socialCell.backgroundColor = UIColor.whiteColor()
        commentsCell.backgroundColor = UIColor.whiteColor()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch(indexPath.row)
        {
        case 0:
            // uilabel for 'pull down to go back'
            pullLabel.frame = CGRect(x: 0, y: -40, width: screenWidth, height: 30)
            pullLabel.text = "Pull down to go back"
            pullLabel.textColor = UIColor.lightGrayColor()
            pullLabel.textAlignment = NSTextAlignment.Center
            
            outfitImageCell.selectionStyle = UITableViewCellSelectionStyle.None
            outfitImageCell.userInteractionEnabled = true
            outfitImageCell.addSubview(pullLabel)
            
            pieceImages.removeAll()
            var outfitHeight: CGFloat = 0
            var prevPieceHeight: CGFloat = 0
            
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
                pieceImageView.backgroundColor = sprubixGray
                
                var pieceImagesString = piece["images"] as! String
                var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                var pieceCoverURL = NSURL(string: pieceImagesDict["cover"] as! String)
                
                pieceImageView.setImageWithURL(pieceCoverURL)
                pieceImageView.contentMode = UIViewContentMode.ScaleAspectFit
                pieceImageView.userInteractionEnabled = true
                
                // like heart image
                let likeImageViewWidth:CGFloat = 75
                likeImageView = UIImageView(image: UIImage(named: "main-like-filled-large"))
                likeImageView.frame = CGRect(x: frame.size.width / 2 - likeImageViewWidth / 2, y: 0, width: likeImageViewWidth, height: pieceHeight)
                likeImageView.contentMode = UIViewContentMode.ScaleAspectFit
                likeImageView.alpha = 0
                pieceImageView.addSubview(likeImageView)
                
                likeImagesDict.setObject(likeImageView, forKey: piece)
                pieceImages.append(pieceImageView)
                
                outfitImageCell.addSubview(pieceImageView)
                
                if piece["deleted_at"]!.isKindOfClass(NSNull) {
                    // add gesture recognizers
                    var singleTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
                    singleTap.numberOfTapsRequired = 1
                    singleTap.cancelsTouchesInView = false
                    pieceImageView.addGestureRecognizer(singleTap)
                    
                    var doubleTap = UITapGestureRecognizer(target: self, action: Selector("wasDoubleTapped:"))
                    doubleTap.numberOfTapsRequired = 2
                    doubleTap.cancelsTouchesInView = false
                    pieceImageView.addGestureRecognizer(doubleTap)
                    
                    singleTap.requireGestureRecognizerToFail(doubleTap) // so that single tap will not be called during a double tap
                    
                    singleTap.delegate = self
                    doubleTap.delegate = self
                    
                    // like button
                    let likeButtonWidth = frame.size.width / 10
                    likeButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                    var image = UIImage(named: "main-like")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    likeButton.setImage(image, forState: UIControlState.Normal)
                    likeButton.setImage(UIImage(named: "main-like-filled"), forState: UIControlState.Selected)
                    likeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                    likeButton.imageView?.tintColor = sprubixGray
                    likeButton.backgroundColor = UIColor.clearColor()
                    likeButton.frame = CGRectMake(8 * likeButtonWidth, pieceHeight - likeButtonWidth, likeButtonWidth, likeButtonWidth)
                    likeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
                    likeButton.addTarget(self, action: "togglePieceLike:", forControlEvents: UIControlEvents.TouchUpInside)
                    likeButton.exclusiveTouch = true

                    let pieceId = piece["id"] as! Int
                    likeButtonsDict.setObject(likeButton, forKey: piece)
                    likeButtons.append(likeButton)
                    
                    // very first time: check likebutton selected
                    let userData: NSDictionary? = defaults.dictionaryForKey("userData")
                    let username = userData!["username"] as! String

                    let poutfitLikesUserRef = firebaseRef.childByAppendingPath("poutfits/piece_\(pieceId)/likes/\(username)")
                    
                    var liked: Bool?
                    
                    // check if user has already liked this outfit
                    poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                        snapshot in
                        
                        if (snapshot.value as? NSNull) != nil {
                            // not yet liked
                            liked = false
                        } else {
                            liked = true
                        }
                        
                        (self.likeButtonsDict[piece] as! UIButton).selected = liked!
                        self.piecesLiked.setObject(liked!, forKey: pieceId)
                    })
                    
                    pieceImageView.addSubview(likeButton)
                    Glow.addGlow(likeButton)
                    
                    // comment button
                    commentsButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                    image = UIImage(named: "main-comments")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    commentsButton.setImage(image, forState: UIControlState.Normal)
                    commentsButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                    commentsButton.imageView?.tintColor = sprubixGray
                    commentsButton.backgroundColor = UIColor.clearColor()
                    commentsButton.frame = CGRectMake(9 * likeButtonWidth, pieceHeight - likeButtonWidth, likeButtonWidth, likeButtonWidth)
                    commentsButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
                    commentsButton.addTarget(self, action: "addCommentsPiece:", forControlEvents: UIControlEvents.TouchUpInside)
                    commentsButton.exclusiveTouch = true
                    commentsButtons.append(commentsButton)
                    
                    pieceImageView.addSubview(commentsButton)
                    Glow.addGlow(commentsButton)
                    
                    let padding: CGFloat = 10
                    let pieceUser = piece["user"] as! NSDictionary
                    let shoppable = pieceUser["shoppable"] as! NSDictionary
                    let buyable: Bool? = shoppable["purchasable"] as? Bool
                    
                    // price label and buy button if outfit has price and quantity
                    if buyable != nil && buyable! != false && piece["price"] as! String != "0.00" {
                        if !piece["quantity"]!.isKindOfClass(NSNull) {
                            // price label
                            let priceLabelHeight: CGFloat = 35
                            priceLabel = UILabel()
                            priceLabel.textAlignment = NSTextAlignment.Center
                            priceLabel.font = UIFont.boldSystemFontOfSize(18.0)
                            
                            let price = piece["price"] as! String
                            priceLabel.text = "$\(price)"
                            priceLabel.frame = CGRectMake(screenWidth - (priceLabel.intrinsicContentSize().width + 20.0) - padding, padding, (priceLabel.intrinsicContentSize().width + 20.0), priceLabelHeight)
                            
                            priceLabel.layer.cornerRadius = priceLabelHeight / 2
                            priceLabel.layer.borderWidth = 0.5
                            priceLabel.layer.borderColor = UIColor.lightGrayColor().CGColor
                            priceLabel.clipsToBounds = true
                            priceLabel.textColor = UIColor.whiteColor()
                            priceLabel.backgroundColor = sprubixColor

                            pieceImageView.addSubview(priceLabel)
                            
                            purchasable = true
                            
                            // add info into buyPieceInfo
                            buyPieceInfo = NSMutableDictionary()
                            buyPieceInfo?.setObject(piece["id"] as! Int, forKey: "piece_id")
                            buyPieceInfo?.setObject(piece["user_id"] as! Int, forKey: "seller_id")
                            
                            // this piece was from this outfit
                            buyPieceInfo?.setObject(outfit["id"] as! Int, forKey: "outfit_id")
                            buyPiecesInfo.setObject(buyPieceInfo!, forKey: pieceId)
                            
                        } else {
                            println("quantity is 0, not enough for sale")
                        }
                    }
                    
                    // user thumbnail and name on top left
                    let userThumbnailWidth: CGFloat = 35
                    
                    userThumbnail = UIImageView(frame: CGRectMake(padding, padding, userThumbnailWidth, userThumbnailWidth))
                    
                    userThumbnail.layer.cornerRadius = userThumbnail.frame.size.width / 2
                    userThumbnail.clipsToBounds = true
                    userThumbnail.layer.borderWidth = 0.5
                    userThumbnail.layer.borderColor = UIColor.lightGrayColor().CGColor
                    
                    let userThumbnailURL = NSURL(string: pieceUser["image"] as! String)
                    userThumbnail.setImageWithURL(userThumbnailURL)
                    
                    // gesture recognizer
                    let userThumbnailToProfile:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showProfile:")
                    userThumbnailToProfile.numberOfTapsRequired = 1
                    
                    userThumbnail.userInteractionEnabled = true
                    userThumbnail.addGestureRecognizer(userThumbnailToProfile)
                    
                    pieceImageView.addSubview(userThumbnail)
                    
                } else {
                    // darkened overlay
                    // // two buttons: complete outfit, find similar
                    
                    let deletedOverlay = UIView(frame: pieceImageView.bounds)
                    deletedOverlay.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
                    deletedOverlay.alpha = 0.0
                    deletedOverlay.userInteractionEnabled = true
                    pieceImageView.addSubview(deletedOverlay)
                    
                    // label
                    var deletedLabel = UILabel(frame: deletedOverlay.bounds)
                    deletedLabel.textColor = UIColor.whiteColor()
                    deletedLabel.text = "Oh no, the owner\nhas removed this item!"
                    deletedLabel.textAlignment = NSTextAlignment.Center
                    deletedLabel.numberOfLines = 0
                    deletedLabel.font = UIFont.boldSystemFontOfSize(18)
                    Glow.addGlow(deletedLabel)
                    deletedOverlay.addSubview(deletedLabel)
                    
                    // two buttons
                    let deletedButtonHeight: CGFloat = 30
                    let deletedButtonPadding: CGFloat = 10
                    let deletedButtonWidth: CGFloat = (screenWidth - 3 * deletedButtonPadding) / 2 // 10 is padding
                    let completeOutfit = UIButton(frame: CGRectMake(deletedButtonPadding, deletedOverlay.frame.size.height - deletedButtonHeight - deletedButtonPadding, deletedButtonWidth, deletedButtonHeight))
                    completeOutfit.setTitle("Complete this outfit", forState: UIControlState.Normal)
                    completeOutfit.layer.cornerRadius = deletedButtonHeight / 2
                    completeOutfit.titleLabel?.font = screenWidth < 375 ? UIFont.systemFontOfSize(14) : UIFont.systemFontOfSize(16)
                    completeOutfit.layer.borderWidth = 2.0
                    completeOutfit.layer.borderColor = UIColor.whiteColor().CGColor
                    completeOutfit.addTarget(self, action: "completeOutfit:", forControlEvents: UIControlEvents.TouchUpInside)
                    completeOutfit.alpha = 0.0
                    pieceImageView.addSubview(completeOutfit)

                    let findSimilar = UIButton(frame: CGRectMake(completeOutfit.frame.origin.x + completeOutfit.frame.size.width + deletedButtonPadding, deletedOverlay.frame.size.height - deletedButtonHeight - deletedButtonPadding, deletedButtonWidth, deletedButtonHeight))
                    findSimilar.setTitle("Recommend similar", forState: UIControlState.Normal)
                    findSimilar.layer.cornerRadius = deletedButtonHeight / 2
                    findSimilar.titleLabel?.font = screenWidth < 375 ? UIFont.systemFontOfSize(14) : UIFont.systemFontOfSize(16)
                    findSimilar.layer.borderWidth = 2.0
                    findSimilar.layer.borderColor = UIColor.whiteColor().CGColor
                    findSimilar.addTarget(self, action: "findSimilar:", forControlEvents: UIControlEvents.TouchUpInside)
                    findSimilar.alpha = 0.0
                    pieceImageView.addSubview(findSimilar)
                    findSimilarButtons.append(findSimilar)
                    deletedPieces.append(piece)
                    
                    UIView.animateWithDuration(0.6, delay: 0.3, usingSpringWithDamping: 0.9 , initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                            deletedOverlay.alpha = 1.0
                            completeOutfit.alpha = 1.0
                            findSimilar.alpha = 1.0
                        }, completion: { finished in
                    })
                }
                
                prevPieceHeight += pieceHeight // to offset 2nd piece image's height with first image's height
                outfitHeight += pieceHeight // accumulate height of all pieces
            }
            
            // add to bag CTA button
            let userData: NSDictionary? = defaults.dictionaryForKey("userData")
            let userType = userData!["shoppable_type"] as! String
            
            // Shopper: Spruce button, Buy button (if purchasable)
            if userType.lowercaseString.rangeOfString("shopper") != nil {
                
                if purchasable {
                    addToBagButton = UIButton(frame: CGRect(x: screenWidth / 3, y: screenHeight - navigationHeight, width: 2 * screenWidth / 3, height: navigationHeight))
                    addToBagButton.backgroundColor = sprubixColor
                    
                    var image: UIImage = UIImage(named: "sidemenu-cart")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    
                    addToBagButton.setImage(image, forState: UIControlState.Normal)
                    addToBagButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                    addToBagButton.imageView?.tintColor = UIColor.whiteColor()
                    addToBagButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
                    addToBagButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16.0)
                    addToBagButton.setTitle("Buy Outfit Now", forState: UIControlState.Normal)
                    addToBagButton.addTarget(self, action: "addToBagButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                    
                    contentView.addSubview(addToBagButton)
                    
                    // spruce button
                    spruceButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth / 3, height: navigationHeight))
                    spruceButton.backgroundColor = sprubixGray
                    
                    image = UIImage(named: "profile-mycloset")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    
                    spruceButton.setImage(image, forState: UIControlState.Normal)
                    spruceButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                    spruceButton.imageView?.tintColor = UIColor.grayColor()
                    spruceButton.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 12, 0)
                    spruceButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16.0)
                    spruceButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
                    spruceButton.setTitle("Spruce", forState: UIControlState.Normal)
                    spruceButton.addTarget(self, action: "spruceButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                    
                    contentView.addSubview(spruceButton)
                    
                    // manual dim background because of TSMessage being blocked
                    darkenedOverlay = UIView(frame: CGRectMake(0, 0, screenWidth, screenHeight))
                    darkenedOverlay?.backgroundColor = UIColor.blackColor()
                    darkenedOverlay?.alpha = 0
                    
                    contentView.addSubview(darkenedOverlay!)
                    
                } else {
                    // spruce button
                    spruceButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
                    spruceButton.backgroundColor = sprubixGray
                    
                    var image: UIImage = UIImage(named: "profile-mycloset")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    
                    spruceButton.setImage(image, forState: UIControlState.Normal)
                    spruceButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                    spruceButton.imageView?.tintColor = UIColor.grayColor()
                    spruceButton.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 12, 0)
                    spruceButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16.0)
                    
                    spruceButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
                    spruceButton.setTitle("Spruce Outfit", forState: UIControlState.Normal)
                    spruceButton.addTarget(self, action: "spruceButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                    
                    contentView.addSubview(spruceButton)
                }
            }
            // Shop: Only Spruce button
            else {
                // spruce button
                spruceButton = UIButton(frame: CGRect(x: 0, y: screenHeight - navigationHeight, width: screenWidth, height: navigationHeight))
                spruceButton.backgroundColor = sprubixGray
                
                var image: UIImage = UIImage(named: "profile-mycloset")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                
                spruceButton.setImage(image, forState: UIControlState.Normal)
                spruceButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                spruceButton.imageView?.tintColor = UIColor.grayColor()
                spruceButton.imageEdgeInsets = UIEdgeInsetsMake(8, 0, 12, 0)
                spruceButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16.0)

                spruceButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
                spruceButton.setTitle("Spruce Outfit", forState: UIControlState.Normal)
                spruceButton.addTarget(self, action: "spruceButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                
                contentView.addSubview(spruceButton)
            }
            
            // tooltip
            let onboardedOutfitDetails = defaults.boolForKey("onboardedOutfitDetails")
            let onboardedOutfitDetails1CTA = defaults.boolForKey("onboardedOutfitDetails1CTA")
            let onboardedOutfitDetails2CTA = defaults.boolForKey("onboardedOutfitDetails2CTA")
            
            if onboardedOutfitDetails == false || onboardedOutfitDetails1CTA == false || onboardedOutfitDetails2CTA == false {
                initTooltipOnboarding(onboardedOutfitDetails, onboardedOutfitDetails1CTA: onboardedOutfitDetails1CTA, onboardedOutfitDetails2CTA: onboardedOutfitDetails2CTA, purchasable: purchasable, spruceButton: spruceButton)
            }
            
            return outfitImageCell
        case 1:
            // init 'posted by' and 'from' credits
            let creditsViewHeight:CGFloat = 80
            var creditsView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: creditsViewHeight))
            
            postedByButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "posted by", username: user["username"] as! String, userThumbnail: user["image"] as! String)
            
            postedByButton.user = user
            
            // if no inspired by, it is original
            // inspired by = parent, always credit parent
            
            if inspiredBy == nil {
                fromButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "inspired by", username: user["username"] as! String, userThumbnail: user["image"] as! String)
                
                fromButton.user = user
            } else {
                fromButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "inspired by", username: inspiredBy["username"] as! String, userThumbnail: inspiredBy["image"] as! String)
                
                fromButton.user = inspiredBy
            }
            
            postedByButton.addTarget(self, action: "creditsShowProfile:", forControlEvents: UIControlEvents.TouchUpInside)
            
            fromButton.addTarget(self, action: "creditsShowProfile:", forControlEvents: UIControlEvents.TouchUpInside)
            
            creditsView.addSubview(postedByButton)
            creditsView.addSubview(fromButton)
            
            creditsCell.selectionStyle = UITableViewCellSelectionStyle.None
            creditsCell.addSubview(creditsView)
            
            return creditsCell
        case 2:
            let itemImageViewWidth:CGFloat = 0.3 * screenWidth
            
            // likes
            itemLikesImage?.removeFromSuperview()
            itemLikesImage = UIButton.buttonWithType(UIButtonType.Custom) as? UIButton
            itemLikesImage!.setImage(UIImage(named: "main-like"), forState: UIControlState.Normal)
            itemLikesImage!.setImage(UIImage(named: "main-like-filled"), forState: UIControlState.Selected)
            itemLikesImage!.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            itemLikesImage!.frame = CGRect(x: 0, y: 0, width: itemImageViewWidth, height: itemSpecHeight)
            itemLikesImage!.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
            itemLikesImage!.addTarget(self, action: "toggleOutfitLike:", forControlEvents: UIControlEvents.TouchUpInside)
            
            Glow.addGlow(itemLikesImage!)
            
            itemLikesLabel?.removeFromSuperview()
            itemLikesLabel = UILabel(frame: CGRect(x: itemImageViewWidth, y: 0, width: screenWidth - itemImageViewWidth, height: itemSpecHeight))
            if numTotalLikes != 0 {
                itemLikesLabel!.text = numTotalLikes > 1 ? "\(numTotalLikes) people like this" : "\(numTotalLikes) person likes this"

            } else {
                itemLikesLabel!.text = "Be the first to like!"
            }
            
            // check if user has liked this outfit yet
            let userData: NSDictionary? = defaults.dictionaryForKey("userData")
            let username = userData!["username"] as! String
            let outfitId = outfit["id"] as! Int
            let itemIdentifier = "outfit_\(outfitId)"
            
            let poutfitLikesUserRef = firebaseRef.childByAppendingPath("poutfits/\(itemIdentifier)/likes/\(username)")
            
            if liked != nil {
                itemLikesImage!.selected = self.liked!
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
                    
                    self.itemLikesImage!.selected = self.liked!
                    
                    self.delegate?.setOutfitsLiked!(outfitId, liked: self.liked!)
                })
            }
            
            specificationCell.selectionStyle = UITableViewCellSelectionStyle.None
            specificationCell.addSubview(itemLikesImage!)
            specificationCell.addSubview(itemLikesLabel!)
            
            return specificationCell
        case 3:
            descriptionCell.textLabel?.text = outfit["description"] as! String!
            descriptionCell.textLabel?.textColor = UIColor.darkGrayColor()
            descriptionCell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
            descriptionCell.textLabel?.numberOfLines = 0
            descriptionCell.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0)
            descriptionCell.userInteractionEnabled = false
            descriptionCell.selectionStyle = UITableViewCellSelectionStyle.None
            
            var itemDescriptionLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
            itemDescriptionLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            descriptionCell.addSubview(itemDescriptionLineTop)
            
            return descriptionCell
            
        case 4:
            // Social Label
            let socialLabelY: CGFloat = 10
            let socialLabelHeight: CGFloat = 20
            let socialLabel: UILabel = UILabel(frame: CGRect(x: 20, y: socialLabelY, width: screenWidth, height: socialLabelHeight))
            socialLabel.text = "Share this outfit"
            socialLabel.textColor = UIColor.lightGrayColor()
            
            socialCell.addSubview(socialLabel)
            
            let socialButtonRow1Y: CGFloat = socialLabelY + socialLabelHeight - 3
            var socialButtonRow1: UIView = UIView(frame: CGRect(x: 0, y: socialButtonRow1Y, width: screenWidth, height: 44))
            
            // Facebook
            var socialImageFacebook = UIImage(named: "spruce-share-fb")
            
            socialButtonFacebook = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
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
            
            socialButtonInstagram = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            socialButtonInstagram.setImage(socialImageInstagram, forState: UIControlState.Normal)
            socialButtonInstagram.setTitle("Instagram", forState: UIControlState.Normal)
            socialButtonInstagram.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
            socialButtonInstagram.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            socialButtonInstagram.frame = CGRect(x: screenWidth/2, y: 10, width: screenWidth/2, height: 44)
            socialButtonInstagram.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            socialButtonInstagram.imageEdgeInsets = UIEdgeInsetsMake(3, 10, 3, 0)
            socialButtonInstagram.titleEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 0)
            socialButtonInstagram.addTarget(self, action: "instagramTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            
            socialButtonRow1.addSubview(socialButtonFacebook)
            socialButtonRow1.addSubview(socialButtonInstagram)
            socialCell.selectionStyle = UITableViewCellSelectionStyle.None
            socialCell.addSubview(socialButtonRow1)
            
            var socialButtonsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
            socialButtonsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            socialCell.addSubview(socialButtonsLineTop)
            
            return socialCell
        case 5:
            // init comments
            
            // view all comments button
            var viewAllComments: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0.8 * screenWidth, height: viewAllCommentsHeight))

            viewAllComments.setTitle("View all comments (\(numTotalComments))", forState: UIControlState.Normal)
            viewAllComments.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0)
            viewAllComments.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            viewAllComments.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            viewAllComments.backgroundColor = UIColor.whiteColor()
            viewAllComments.titleLabel?.font = UIFont.systemFontOfSize(17.0)
            viewAllComments.addTarget(self, action: "addComments:", forControlEvents:
                UIControlEvents.TouchUpInside)
            
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
            
            var viewAllCommentsBG:UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: viewAllCommentsHeight))
            viewAllCommentsBG.backgroundColor = UIColor.whiteColor()
            
            var viewAllCommentsLineTop = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 2))
            viewAllCommentsLineTop.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            viewAllCommentsBG.addSubview(viewAllComments)
            viewAllCommentsBG.addSubview(viewMore)
            viewAllCommentsBG.addSubview(viewAllCommentsLineTop)
            
            commentsCell.selectionStyle = UITableViewCellSelectionStyle.None
            commentsCell.addSubview(viewAllCommentsBG)
            
            loadRecentComments()
            
            // get rid of the gray bg when cell is selected
            var bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.clearColor()
            commentsCell.selectedBackgroundView = bgColorView
            
            return commentsCell
            
        default: fatalError("Unknown row in section")
        }
    }
    
    private func loadRecentComments() {
        var prevHeight: CGFloat = 0
        
        for recentComment in recentComments {
            let commentAuthor = recentComment["author"] as! NSDictionary
            let authorImage = commentAuthor["image"] as! String
            let authorUserName = commentAuthor["username"] as! String
            
            let commentBody = recentComment["body"] as! String
            
            var commentRowView: SprubixItemCommentRow = SprubixItemCommentRow(username: authorUserName, commentString: commentBody, y: viewAllCommentsHeight + prevHeight, button: false, userThumbnail: authorImage)
            
            prevHeight += commentRowView.commentRowHeight
            commentsCell.addSubview(commentRowView)
        }
        
        // add a comment button
        commentRowButton = SprubixItemCommentRow(username: "", commentString: "", y: viewAllCommentsHeight + prevHeight, button: true, userThumbnail: "sprubix-user")
        
        commentRowButton.postCommentButton.addTarget(self, action: "addComments:", forControlEvents: UIControlEvents.TouchUpInside)
        
        commentsCell.addSubview(commentRowButton)
    }
    
    func initTooltipOnboarding(onboardedOutfitDetails: Bool, onboardedOutfitDetails1CTA: Bool, onboardedOutfitDetails2CTA: Bool, purchasable: Bool, spruceButton: UIButton) {
        if onboardedOutfitDetails == false || onboardedOutfitDetails1CTA == false || onboardedOutfitDetails2CTA == false {
            if tooltipManager == nil {
                tooltipManager = JDFSequentialTooltipManager(hostView: self.contentView)
                tooltipManager.showsBackdropView = true
                tooltipManager.backdropColour = UIColor.blackColor()
                tooltipManager.backdropAlpha = 0.3
            }
        }
        
        if onboardedOutfitDetails == false {
            let pulldownText = "Pull down to go back.\nPull further to return to main feed."
            let pieceText = "Touch here to view item details"
            let swipeText = "Swipe left or right to view\nthe next outfit"
            
            let pulldownPoint: CGPoint = CGPoint(x: screenWidth/2 - 40, y: 20)
            let piecePoint: CGPoint = CGPoint(x: screenWidth/2 - 40, y: screenHeight/3)
            let swipePoint: CGPoint = CGPoint(x: screenWidth/2 - 40, y: screenHeight/2)
            
            let pulldownTooltip: JDFTooltipView = JDFTooltipView(targetPoint: pulldownPoint, hostView: self.contentView, tooltipText: pulldownText, arrowDirection: JDFTooltipViewArrowDirection.Up, width: screenWidth*2/3)
            let pieceTooltip: JDFTooltipView = JDFTooltipView(targetPoint: piecePoint, hostView: self.contentView, tooltipText: pieceText, arrowDirection: JDFTooltipViewArrowDirection.Down, width: screenWidth*2/3)
            let swipeTooltip: JDFTooltipView = JDFTooltipView(targetPoint: swipePoint, hostView: self.contentView, tooltipText: swipeText, arrowDirection: JDFTooltipViewArrowDirection.Down, width: screenWidth*2/3)
            
            tooltipManager.addTooltip(pulldownTooltip)
            tooltipManager.addTooltip(pieceTooltip)
            tooltipManager.addTooltip(swipeTooltip)
            defaults.setBool(true, forKey: "onboardedOutfitDetails")
        }
        
        // add to bag CTA button
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let userType = userData!["shoppable_type"] as! String
        
        // Shopper: Spruce button, Buy button (if purchasable)
        if userType.lowercaseString.rangeOfString("shopper") != nil {
            if purchasable {
                // tooltip: 2 buttons
                if onboardedOutfitDetails2CTA == false {
                    let spruceText = "Dislike something here?\nEdit the outfit!"
                    let buyText = "Like everything here?\nBuy them now!"
                    
                    let spruceTooltip: JDFTooltipView = JDFTooltipView(targetView: spruceButton, hostView: self.contentView, tooltipText: spruceText, arrowDirection: JDFTooltipViewArrowDirection.Down, width: tooltipWidth)
                    let buyTooltip: JDFTooltipView = JDFTooltipView(targetView: addToBagButton, hostView: self.contentView, tooltipText: buyText, arrowDirection: JDFTooltipViewArrowDirection.Down, width: tooltipWidth)
                    
                    tooltipManager.addTooltip(spruceTooltip)
                    tooltipManager.addTooltip(buyTooltip)
                    defaults.setBool(true, forKey: "onboardedOutfitDetails2CTA")
                }
                
            } else {
                // tooltip: 1 button
                if onboardedOutfitDetails1CTA == false {
                    let spruceText = "Like the outfit but\ndislike a certain item?\nEdit the outfit now!"
                    let sprucePoint: CGPoint = CGPoint(x: screenWidth/2 - 40, y: spruceButton.frame.origin.y)
                    let spruceTooltip: JDFTooltipView = JDFTooltipView(targetPoint: sprucePoint, hostView: self.contentView, tooltipText: spruceText, arrowDirection: JDFTooltipViewArrowDirection.Down, width: screenWidth*2/3)
                    
                    tooltipManager.addTooltip(spruceTooltip)
                    defaults.setBool(true, forKey: "onboardedOutfitDetails1CTA")
                }
            }
        }
        // Shop: Only Spruce button
        else {
            // tooltip: 1 button
            if onboardedOutfitDetails1CTA == false {
                let spruceText = "Like the outfit but\ndislike a certain item?\nEdit the outfit now!"
                let sprucePoint: CGPoint = CGPoint(x: screenWidth/2 - 40, y: spruceButton.frame.origin.y)
                let spruceTooltip: JDFTooltipView = JDFTooltipView(targetPoint: sprucePoint, hostView: self.contentView, tooltipText: spruceText, arrowDirection: JDFTooltipViewArrowDirection.Down, width: screenWidth*2/3)
                
                tooltipManager.addTooltip(spruceTooltip)
                defaults.setBool(true, forKey: "onboardedOutfitDetails1CTA")
            }
            
            // no 2CTA buttons, just set to true
            defaults.setBool(true, forKey: "onboardedOutfitDetails2CTA")
        }
        
        if onboardedOutfitDetails == false || onboardedOutfitDetails1CTA == false || onboardedOutfitDetails2CTA == false {
            tooltipManager.setFontForAllTooltips(UIFont.systemFontOfSize(16))
            tooltipManager.setTextColourForAllTooltips(UIColor.whiteColor())
            tooltipManager.setBackgroundColourForAllTooltips(sprubixColor)
            tooltipManager.showNextTooltip()
        }
    }
    
    func wasSingleTapped(gesture: UITapGestureRecognizer) {
        
        var selectedPiece:UIImageView = gesture.view as! UIImageView
        var position = find(pieceImages, selectedPiece)
        
        var currentIndexPath:NSIndexPath = NSIndexPath(forItem: position!, inSection: 0)
        
        let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath: currentIndexPath)

        selectedPieceDetail = pieces[position!] as NSDictionary
        
        pieceDetailsViewController.parentOutfitId = outfit["id"] as? Int
        pieceDetailsViewController.pieces = pieces
        pieceDetailsViewController.user = user
        pieceDetailsViewController.inspiredBy = inspiredBy
        pieceDetailsViewController.pieceInteractionDelegate = self
        
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
        
        // Mixpanel - Viewed Piece Details
        mixpanel.track("Viewed Piece Details", properties: [
            "Source": "Outfit View",
            "Piece ID": pieces[currentIndexPath.row].objectForKey("id") as! Int,
            "Owner User ID": pieces[currentIndexPath.row].objectForKey("user_id") as! Int
        ])
        // Mixpanel - End
    }
    
    func wasDoubleTapped(gesture: UITapGestureRecognizer) {
        // like Piece
        println("double tapped!")
        
        let parentView = gesture.view
        
        if parentView != nil {
            let pos: Int? = find(pieceImages, (parentView as! UIImageView))
            
            if pos != nil {
                let piece = pieces[pos!]
               
                likedPiece(piece)
            }
        }
    }
    
    func creditsShowProfile(sender: UIButton) {
        if sender == postedByButton {
            containerViewController.showUserProfile(postedByButton.user!)
            
            // Mixpanel - Viewed User Profile, Outfit View
            mixpanel.track("Viewed User Profile", properties: [
                "Source": "Outfit View",
                "Tab": "Outfit",
                "Target User ID": postedByButton.user!.objectForKey("id") as! Int
            ])
            // Mixpanel - End
        } else if sender == fromButton {
            containerViewController.showUserProfile(fromButton.user!)
            
            // Mixpanel - Viewed User Profile, Outfit View
            mixpanel.track("Viewed User Profile", properties: [
                "Source": "Outfit View",
                "Tab": "Outfit",
                "Target User ID": fromButton.user!.objectForKey("id") as! Int
            ])
        }
    }
    
    func animateHeart(piece: NSDictionary) {
        var likeImageView = likeImagesDict[piece] as? UIImageView
        
        if likeImageView != nil {
            UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                likeImageView!.alpha = 1.0
                }, completion: { finished in
                    if finished {
                        UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                            likeImageView!.alpha = 0.0
                            }, completion: nil)
                    }
            })
        }
    }
    
    func likedPiece(piece: NSDictionary) {
        // needed:
        // // pieceId, thumbnailURLString, itemIdentifier, receiver
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            animateHeart(piece)
            
            let pieceId = piece["id"] as! Int
            let receiver = piece["user"] as! NSDictionary
            let pieceImagesString = piece["images"] as! NSString
            let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
            
            let thumbnailURLString = pieceImageDict["thumbnail"] as! String
            let itemIdentifier = "piece_\(pieceId)"
            
            // firebase collections: users, likes, poutfits and notifications
            let likesRef = firebaseRef.childByAppendingPath("likes")
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            let poutfitsRef = firebaseRef.childByAppendingPath("poutfits")
            let poutfitLikesRef = poutfitsRef.childByAppendingPath("\(itemIdentifier)/likes")
            
            let senderUsername = userData!["username"] as! String
            let senderImage = userData!["image"] as! String
            let receiverUsername = receiver["username"] as! String
            let poutfitRef = firebaseRef.childByAppendingPath("poutfits/\(itemIdentifier)")
            let poutfitLikesUserRef = poutfitLikesRef.childByAppendingPath(senderUsername)
            
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            let senderLikesRef = firebaseRef.childByAppendingPath("users/\(senderUsername)/likes")
            
            let createdAt = timestamp
            
            // check if user has already liked this piece
            poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if (snapshot.value as? NSNull) != nil {
                    self.piecesLiked.setObject(true, forKey: pieceId)
                    (self.likeButtonsDict[piece] as! UIButton).selected = true
                    
                    // does not exist, add it
                    let likeRef = likesRef.childByAutoId()
                    
                    let like = [
                        "author": senderUsername, // yourself
                        "created_at": createdAt,
                        "poutfit": itemIdentifier
                    ]
                    
                    likeRef.setValue(like, withCompletionBlock: {
                        (error:NSError?, ref:Firebase!) in
                        
                        if (error != nil) {
                            println("Error: Like could not be added.")
                        } else {
                            // like added successfully
                            
                            // update poutfitRef num of likes
                            let poutfitLikeCountRef = poutfitRef.childByAppendingPath("num_likes")
                            
                            poutfitLikeCountRef.runTransactionBlock({
                                (currentData:FMutableData!) in
                                
                                var value = currentData.value as? Int
                                
                                if value == nil {
                                    value = 0
                                }
                                
                                currentData.value = value! + 1
                                
                                return FTransactionResult.successWithValue(currentData)
                            })
                            
                            // update child values: poutfits
                            poutfitLikesRef.updateChildValues([
                                userData!["username"] as! String: likeRef.key
                                ])
                            
                            // update child values: user
                            let senderLikeRef = senderLikesRef.childByAppendingPath(likeRef.key)
                            
                            senderLikeRef.updateChildValues([
                                "created_at": createdAt,
                                "poutfit": itemIdentifier
                                ], withCompletionBlock: {
                                    
                                    (error:NSError?, ref:Firebase!) in
                                    
                                    if (error != nil) {
                                        println("Error: Like Key could not be added to User Likes.")
                                    }
                            })
                            
                            // push new notifications
                            let notificationRef = notificationsRef.childByAutoId()
                            
                            let notification = [
                                "poutfit": [
                                    "key": itemIdentifier,
                                    "image": thumbnailURLString
                                ],
                                "created_at": createdAt,
                                "sender": [
                                    "username": senderUsername, // yourself
                                    "image": senderImage
                                ],
                                "receiver": receiverUsername,
                                "type": "like",
                                "like": likeRef.key,
                                "unread": true
                            ]
                            
                            notificationRef.setValue(notification, withCompletionBlock: {
                                
                                (error:NSError?, ref:Firebase!) in
                                
                                if (error != nil) {
                                    println("Error: Notification could not be added.")
                                } else {
                                    // update target user notifications
                                    let receiverUserNotificationRef = receiverUserNotificationsRef.childByAppendingPath(notificationRef.key)
                                    
                                    if receiverUsername != senderUsername {
                                        receiverUserNotificationRef.updateChildValues([
                                            "created_at": createdAt,
                                            "unread": true
                                            ], withCompletionBlock: {
                                                
                                                (error:NSError?, ref:Firebase!) in
                                                
                                                if (error != nil) {
                                                    println("Error: Notification Key could not be added to Users.")
                                                } else {
                                                    // send APNS
                                                    let recipientId = receiver["id"] as! Int
                                                    let senderId = userData!["id"] as! Int
                                                    
                                                    if recipientId != senderId {
                                                        let pushMessage = "\(senderUsername) liked your item."
                                                        
                                                        APNS.sendPushNotification(pushMessage, recipientId: recipientId)
                                                    }
                                                }
                                        })
                                    }
                                    
                                    // update likes with notification key
                                    likeRef.updateChildValues([
                                        "notification": notificationRef.key
                                        ], withCompletionBlock: {
                                            
                                            (error:NSError?, ref:Firebase!) in
                                            
                                            if (error != nil) {
                                                println("Error: Notification Key could not be added to Likes.")
                                                
                                                self.piecesLiked.setObject(false, forKey: pieceId)
                                                (self.likeButtonsDict[piece] as! UIButton).selected = false
                                                
                                            } else {
                                                println("Piece liked successfully!")
                                                // add to piecesLiked dictionary
                                                self.piecesLiked.setObject(true, forKey: pieceId)
                                                (self.likeButtonsDict[piece] as! UIButton).selected = true
                                            }
                                    })
                                }
                            })
                            
                            // Mixpanel - Liked Pieces
                            mixpanel.track("Liked Pieces", properties: [
                                "Piece ID": pieceId,
                                "Owner User ID": receiver["id"] as! Int
                            ])
                            mixpanel.people.increment("Pieces Liked", by: 1)
                            // Mixpanel - End
                        }
                    })
                    
                } else {
                    println("You have already liked this piece")
                    
                    // add to piecesLiked dictionary
                    self.piecesLiked.setObject(true, forKey: pieceId)
                    (self.likeButtonsDict[piece] as! UIButton).selected = true
                }
            })
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    func unlikedPiece(piece: NSDictionary) {
        // needed:
        // // pieceId, itemIdentifier, receiver
        
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        
        if userData != nil {
            let pieceId = piece["id"] as! Int
            let receiver = piece["user"] as! NSDictionary
            let itemIdentifier = "piece_\(pieceId)"
            
            // firebase collections: users, likes, poutfits and notifications
            let likesRef = firebaseRef.childByAppendingPath("likes")
            let notificationsRef = firebaseRef.childByAppendingPath("notifications")
            let poutfitsRef = firebaseRef.childByAppendingPath("poutfits")
            let poutfitLikesRef = poutfitsRef.childByAppendingPath("\(itemIdentifier)/likes")
            
            let senderUsername = userData!["username"] as! String
            let receiverUsername = receiver["username"] as! String
            let poutfitRef = firebaseRef.childByAppendingPath("poutfits/\(itemIdentifier)")
            let poutfitLikesUserRef = poutfitLikesRef.childByAppendingPath(senderUsername) // to be removed
            
            let receiverUserNotificationsRef = firebaseRef.childByAppendingPath("users/\(receiverUsername)/notifications")
            let senderLikesRef = firebaseRef.childByAppendingPath("users/\(senderUsername)/likes")
            
            // check if user has already liked this outfit
            poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if (snapshot.value as? NSNull) != nil {
                    // does not exist, already unliked
                    println("You have already unliked this piece")
                    
                    self.piecesLiked.setObject(false, forKey: pieceId)
                } else {
                    // was liked, set it to unliked here
                    poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                        snapshot in
                        
                        if (snapshot.value as? NSNull) != nil {
                            // does not exist
                            println("Error: Like key in Poutfits could not be found.")
                        } else {
                            // exists
                            var likeRefKey = snapshot.value as! String
                            
                            let likeRef = likesRef.childByAppendingPath(likeRefKey) // to be removed
                            
                            let likeRefNotificationKey = likeRef.childByAppendingPath("notification")
                            
                            likeRefNotificationKey.observeSingleEventOfType(.Value, withBlock: { snapshot in
                                
                                if (snapshot.value as? NSNull) != nil {
                                    // does not exist
                                    println("Error: Notification key in Likes could not be found.")
                                } else {
                                    var notificationRefKey = snapshot.value as! String
                                    
                                    let notificationRef = notificationsRef.childByAppendingPath(notificationRefKey) // to be removed
                                    
                                    let receiverUserNotificationRef = receiverUserNotificationsRef.childByAppendingPath(notificationRefKey) // to be removed
                                    
                                    let senderLikeRef = senderLikesRef.childByAppendingPath(likeRefKey) // to be removed
                                    
                                    // remove all values
                                    senderLikeRef.removeValue()
                                    notificationRef.removeValue()
                                    receiverUserNotificationRef.removeValue()
                                    likeRef.removeValue()
                                    poutfitLikesUserRef.removeValue()
                                    
                                    self.piecesLiked.setObject(false, forKey: pieceId)
                                    
                                    // update poutfitRef num of likes
                                    let poutfitLikeCountRef = poutfitRef.childByAppendingPath("num_likes")
                                    
                                    poutfitLikeCountRef.runTransactionBlock({
                                        (currentData:FMutableData!) in
                                        
                                        var value = currentData.value as? Int
                                        
                                        if value == nil {
                                            value = 0
                                        } else {
                                            if value > 0 {
                                                value = value! - 1
                                            }
                                        }
                                        
                                        currentData.value = value!
                                        
                                        return FTransactionResult.successWithValue(currentData)
                                    })
                                    
                                    println("Piece unliked successfully!")
                                }
                            })
                            
                            // Mixpanel - Liked Pieces (decrement)
                            mixpanel.people.increment("Pieces Liked", by: -1)
                            // Mixpanel - End
                        }
                    })
                }
            })
        } else {
            println("userData not found, please login or create an account")
        }
    }
    
    func heightForTextLabel(text:String, width:CGFloat, padding: CGFloat) -> CGFloat {
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
            cellHeight = itemSpecHeight // specifications height
        case 3:
            cellHeight = heightForTextLabel(outfit["description"] as! String, width: screenWidth - 20, padding: 20) // description height
        case 4:
            cellHeight = 90 // share height (40 = top-padding, 44 = per icon row, rest = bottom-padding)
        case 5:
            cellHeight = purchasable ? 300 + navigationHeight : 300 // comments height, 300 = 270 + 30 (bottom-padding)
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
    
    // button callbacks
    func addComments(sender: UIButton) {
        commentsViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("CommentsView") as? CommentsViewController
        
        if sender == commentRowButton.postCommentButton {
            commentsViewController?.showKeyboard = true
        }
        
        // init
        let outfitId = outfit["id"] as! Int
        let outfitImagesString = outfit["images"] as! NSString
        let outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        let outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
        
        let thumbnailURLString = outfitImageDict["thumbnail"] as! String
        
        commentsViewController?.delegate = containerViewController
        commentsViewController?.poutfitImageURL = thumbnailURLString
        commentsViewController?.receiverUsername = user["username"] as! String
        commentsViewController?.receiverId = user["id"] as! Int
        commentsViewController?.poutfitIdentifier = "outfit_\(outfitId)"
        commentsViewController?.prevViewIsOutfit = true
        
        navController?.delegate = nil
        navController?.pushViewController(commentsViewController!, animated: true)
        
        // Mixpanel - Viewed Outfit Comments, Main Feed
        mixpanel.track("Viewed Outfit Comments", properties: [
            "Source": "Outfit View",
            "Outfit ID": outfitId,
            "Owner User ID": user["id"] as! Int
        ])
        mixpanel.people.increment("Outfit Comments Viewed", by: 1)
        // Mixpanel - End
    }
    
    func completeOutfit(sender: UIButton) {
        let spruceViewController = SpruceViewController()
        spruceViewController.outfit = outfit
        spruceViewController.userIdFrom = user["id"] as! Int
        spruceViewController.usernameFrom = user["username"] as! String
        spruceViewController.userThumbnailFrom = user["image"] as! String
        
        navController?.delegate = nil
        navController?.pushViewController(spruceViewController, animated: true)
    }
    
    func findSimilar(sender: UIButton) {
        var pos: Int? = find(findSimilarButtons, sender)
        
        if pos != nil {
            let piece = deletedPieces[pos!]
            let category = piece["category"] as! NSDictionary
            let searchViewController = SearchViewController()
            
            searchViewController.currentScope = 1
            searchViewController.searchString = (category["name"] as! String).lowercaseString
            searchViewController.fromRecommendSimilar = true
            
            navController?.pushViewController(searchViewController, animated: false)
        }
    }
    
    // UIGestureRecognizerDelegate
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if touch.view as? UIButton != nil {
            if find(likeButtons, touch.view as! UIButton) != nil  || find(commentsButtons, touch.view as! UIButton) != nil {
                return false
            }
        }
        
        return true
    }
    
    // like button callback
    func toggleOutfitLike(sender: UIButton) {
        let outfitId = outfit["id"] as! Int
        let itemIdentifier = "outfit_\(outfitId)"
        
        var outfitImagesString = outfit["images"] as! NSString
        var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
        
        let thumbnailURLString = outfitImageDict["thumbnail"] as! String
        
        if sender.selected != true {
            sender.selected = true
            liked = true
            
            delegate?.likedOutfit!(outfitId, thumbnailURLString: thumbnailURLString, itemIdentifier: itemIdentifier, receiver: user)
            
            numTotalLikes += 1
        } else {
            sender.selected = false
            liked = false
            
            delegate?.unlikedOutfit!(outfitId, itemIdentifier: itemIdentifier, receiver: user)
            
            if numTotalLikes > 0 {
                numTotalLikes -= 1
            }
        }
        
        var nsPath = NSIndexPath(forRow: 2, inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    // piece button callbacks
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
        // reset arrays
        itemBuySizeLabels.removeAll()
        itemBuyQuantityLabels.removeAll()
        itemBuyDeliveryLabels.removeAll()
        buyPieces.removeAll()
        
        let itemSpecHeight:CGFloat = 45
        let popupWidth: CGFloat = screenWidth - 100
        let popupHeight: CGFloat = popupWidth + itemSpecHeight * 3 + navigationHeight
        let itemImageViewWidth:CGFloat = 0.25 * popupWidth
        
        let popupContentView: UIView = UIView(frame: CGRectMake(0, 0, popupWidth, popupHeight))
        popupContentView.backgroundColor = UIColor.whiteColor()
        popupContentView.layer.cornerRadius = 12.0
        
        // left arrow
        let arrowButtonHeight: CGFloat = 25
        var leftArrowButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        
        leftArrowButton.frame = CGRectMake(-arrowButtonHeight, (popupHeight / 2) - (arrowButtonHeight / 2), arrowButtonHeight, arrowButtonHeight)
        leftArrowButton.backgroundColor = UIColor.clearColor()
        leftArrowButton.setImage(UIImage(named: "spruce-arrow-left"), forState: UIControlState.Normal)
        leftArrowButton.tintColor = UIColor.whiteColor()
        leftArrowButton.autoresizesSubviews = true
        leftArrowButton.exclusiveTouch = true
        
        Glow.addGlow(leftArrowButton)
        
        // right arrow
        var rightArrowButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        
        rightArrowButton.frame = CGRectMake(popupWidth, (popupHeight / 2) - (arrowButtonHeight / 2), arrowButtonHeight, arrowButtonHeight)
        rightArrowButton.backgroundColor = UIColor.clearColor()
        rightArrowButton.setImage(UIImage(named: "spruce-arrow-right"), forState: UIControlState.Normal)
        rightArrowButton.tintColor = UIColor.whiteColor()
        rightArrowButton.autoresizesSubviews = true
        rightArrowButton.exclusiveTouch = true
        
        Glow.addGlow(rightArrowButton)
        
        // add content to popupContentView
        var buyPiecesScrollView = UIScrollView(frame: CGRectMake(0, 0, popupWidth, popupHeight))
        buyPiecesScrollView.layer.cornerRadius = 12.0
        buyPiecesScrollView.pagingEnabled = true
        buyPiecesScrollView.alwaysBounceHorizontal = true
        
        buyPieceViews.removeAll()
        
        var sellablePieces: Int = 0
        
        for var i = 0; i < pieces.count; i++ {
            let piece = pieces[i] as NSDictionary
            
            if piece["price"] as! String != "0.00" {
                if !piece["quantity"]!.isKindOfClass(NSNull) && piece["deleted_at"]!.isKindOfClass(NSNull) {
                    
                    let buyPieceView: UIView = UIView(frame: CGRectMake(popupWidth * CGFloat(sellablePieces), 0, popupWidth, popupHeight))
                    
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
                    itemBuySizeLabels.append(itemBuySizeLabel)
                    
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
                    itemBuyQuantityLabels.append(itemBuyQuantityLabel)
                    
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
                    itemBuyDeliveryLabels.append(itemBuyDeliveryLabel)
                    
                    buyPieceView.addSubview(itemSizeImage)
                    buyPieceView.addSubview(itemSizeButton)
                    
                    buyPieceView.addSubview(itemQuantityImage)
                    buyPieceView.addSubview(itemQuantityButton)
                    
                    buyPieceView.addSubview(itemDeliveryImage)
                    buyPieceView.addSubview(itemDeliveryButton)
                    
                    buyPiecesScrollView.addSubview(buyPieceView)
                    
                    popupContentView.addSubview(buyPiecesScrollView)
                    popupContentView.addSubview(leftArrowButton)
                    popupContentView.addSubview(rightArrowButton)
                    
                    // add to cart button
                    var addToCart: UIButton = UIButton(frame: CGRectMake(0, popupHeight - navigationHeight, popupWidth, navigationHeight))
                    addToCart.backgroundColor = sprubixColor
                    addToCart.setTitle("Add to Cart", forState: UIControlState.Normal)
                    addToCart.titleLabel?.font = UIFont.boldSystemFontOfSize(addToCart.titleLabel!.font.pointSize)
                    addToCart.addTarget(self, action: "addToCartPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                    
                    buyPieceView.addSubview(addToCart)
                    
                    buyPieceViews.append(buyPieceView)
                    
                    var selectedSize: String = ""
                    selectedSizes.append(selectedSize)
                    
                    buyPieces.append(piece)
                    
                    // load the delivery methods for this piece
                    preloadBuyDeliveryMethod(sellablePieces)
                    
                    sellablePieces += 1
                }
            }
        }
        
        buyPiecesScrollView.contentSize = CGSizeMake(popupWidth * CGFloat(sellablePieces), popupHeight)
        
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
            
            self.selectedSizes.removeAll()
            self.buyPieceInfo?.removeObjectsForKeys(["size", "quantity", "delivery_option_id"])
        }
        
        buyPopup?.show()
        
        // Mixpanel - Clicked Buy, Outfit View
        mixpanel.track("Clicked Buy", properties: [
            "Source": "Outfit View",
            "Outfit ID": outfit["id"] as! Int
            ])
    }
    
    func selectBuySize(sender: UIButton) {
        let pos = find(buyPieceViews, sender.superview!)
        let piece: NSDictionary = buyPieces[pos!] as NSDictionary
        let buyPieceInfo = buyPiecesInfo[piece["id"] as! Int] as? NSMutableDictionary
        
        var pieceSizesString: String? = piece["size"] as? String
        
        if pieceSizesString != nil {
            var pieceSizesData:NSData = pieceSizesString!.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceSizesArray: NSArray = NSJSONSerialization.JSONObjectWithData(pieceSizesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSArray
            
            let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Size", rows: pieceSizesArray as! [String], initialSelection: 0,
                doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                    
                    // add info to buyPieceInfo
                    buyPieceInfo?.setObject(selectedValue, forKey: "size")
                    
                    (self.itemBuySizeLabels[pos!] as UILabel).text = "\(selectedValue)"
                    (self.itemBuySizeLabels[pos!] as UILabel).textColor = UIColor.blackColor()
                    
                    self.selectedSizes[pos!] = selectedValue as! String
                    
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
        let pos = find(buyPieceViews, sender.superview!)
        let piece: NSDictionary = buyPieces[pos!] as NSDictionary
        let buyPieceInfo = buyPiecesInfo[piece["id"] as! Int] as? NSMutableDictionary
        let selectedSize: String = selectedSizes[pos!]
        
        // create quantity array
        var quantityArray: [Int] = [Int]()
        
        if selectedSize != "" {
            if !piece["quantity"]!.isKindOfClass(NSNull) {
                var pieceQuantityString = piece["quantity"] as! String
                var pieceQuantityData:NSData = pieceQuantityString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var pieceQuantityDict = NSJSONSerialization.JSONObjectWithData(pieceQuantityData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                for var i = 1; i <= (pieceQuantityDict[selectedSize] as! String).toInt(); i++ {
                    quantityArray.append(i)
                }
            
                let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Quantity", rows: quantityArray, initialSelection: 0,
                    doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                        
                        // add info to buyPieceInfo
                        buyPieceInfo?.setObject(selectedValue, forKey: "quantity")
                        
                        (self.itemBuyQuantityLabels[pos!] as UILabel).text = "\(selectedValue)"
                        (self.itemBuyQuantityLabels[pos!] as UILabel).textColor = UIColor.blackColor()
                        
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
    
    func preloadBuyDeliveryMethod(pieceIndex: Int) {
        let piece: NSDictionary = buyPieces[pieceIndex] as NSDictionary
        let owner: NSDictionary = piece["user"] as! NSDictionary
        
        // REST call to server to retrieve delivery methods
        var shopId: Int? = owner["id"] as? Int
        
        if shopId != nil {
            manager.POST(SprubixConfig.URL.api + "/delivery/options",
                parameters: [
                    "user_id": shopId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    self.deliveryMethods[pieceIndex] = responseObject["data"] as? [NSDictionary]
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    func selectBuyDeliveryMethod(sender: UIButton) {
        let pos = find(buyPieceViews, sender.superview!)
        
        if deliveryMethods[pos!] != nil {
            self.showBuyDeliveryMethodPicker(sender)
        }
    }
    
    private func showBuyDeliveryMethodPicker(sender: UIButton) {
        let pos = find(buyPieceViews, sender.superview!)
        let piece: NSDictionary = buyPieces[pos!] as NSDictionary
        let buyPieceInfo = buyPiecesInfo[piece["id"] as! Int] as? NSMutableDictionary
        
        // create delivery array
        var deliveryArray: [String] = [String]()
        var deliveryIdsArray: [Int] = [Int]()
        
        for deliveryOption in deliveryMethods[pos!]! {
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
                    buyPieceInfo?.setObject(selectedDeliveryId, forKey: "delivery_option_id")
                    
                    (self.itemBuyDeliveryLabels[pos!] as UILabel).text = "\(selectedValue)"
                    (self.itemBuyDeliveryLabels[pos!] as UILabel).textColor = UIColor.blackColor()
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
    
    func showProfile(gesture: UITapGestureRecognizer) {
        var parentView: UIView? = (gesture.view)?.superview
        
        if parentView != nil {
            let pos: Int? = find(pieceImages, (parentView as! UIImageView))
            
            if pos != nil {
                let pos = find(pieceImages, (parentView as! UIImageView))
                let piece: NSDictionary = pieces[pos!] as NSDictionary
                let user = piece["user"] as! NSDictionary
                
                containerViewController.showUserProfile(user)
                
                // Mixpanel - Viewed User Profile, Outfit View
                mixpanel.track("Viewed User Profile", properties: [
                    "Source": "Outfit View",
                    "Tab": "Outfit",
                    "Target User ID": piece["user_id"] as! Int
                ])
                // Mixpanel - End
            }
        }
    }
    
    func addToCartPressed(sender: UIButton) {
        let pos = find(buyPieceViews, sender.superview!)
        let piece: NSDictionary = buyPieces[pos!] as NSDictionary
        let buyPieceInfo = buyPiecesInfo[piece["id"] as! Int] as? NSMutableDictionary
        
        if  buyPieceInfo?.objectForKey("size") != nil &&
            buyPieceInfo?.objectForKey("quantity") != nil &&
            buyPieceInfo?.objectForKey("delivery_option_id") != nil {
        
            let userId: Int? = defaults.objectForKey("userId") as? Int
            
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
                            
                            // Mixpanel - Added to Cart, Outfit View, Success
                            mixpanel.track("Added To Cart", properties: [
                                "Source": "Outfit View",
                                "Piece ID": self.buyPieceInfo!.objectForKey("piece_id") as! Int,
                                "Status": "Success"
                            ])
                        } else {
                            // error exception
                            TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                            
                            // Mixpanel - Added to Cart, Outfit View, Fail
                            mixpanel.track("Added To Cart", properties: [
                                "Source": "Outfit View",
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
    
    func addCommentsPiece(sender: UIButton) {
        var parentView: UIView? = sender.superview
        
        if parentView != nil {
            let pos: Int? = find(pieceImages, (parentView as! UIImageView))
            
            if pos != nil {
                let piece = pieces[pos!]
                
                // init
                let pieceId = piece["id"] as! Int
                let pieceUser = piece["user"] as! NSDictionary
                let pieceImagesString = piece["images"] as! NSString
                let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
                
                let thumbnailURLString = pieceImageDict["thumbnail"] as! String

                commentsViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("CommentsView") as? CommentsViewController
                
                commentsViewController?.delegate = containerViewController
                commentsViewController?.poutfitImageURL = thumbnailURLString
                commentsViewController?.receiverUsername = pieceUser["username"] as! String
                commentsViewController?.receiverId = pieceUser["id"] as! Int
                commentsViewController?.poutfitIdentifier = "piece_\(pieceId)"
                
                navController!.delegate = nil
                navController!.pushViewController(commentsViewController!, animated: true)
                
                // Mixpanel - Viewed Piece Comments
                mixpanel.track("Viewed Piece Comments", properties: [
                    "Source": "Outfit View",
                    "Piece ID": pieceId,
                    "Owner User ID": piece["user_id"] as! Int
                ])
                mixpanel.people.increment("Piece Comments Viewed", by: 1)
                // Mixpanel - End
            }
        }
    }
    
    func togglePieceLike(sender: UIButton) {
        var keys = likeButtonsDict.allKeysForObject(sender)
        
        if keys.count > 0 {
            let piece: NSDictionary = keys.first as! NSDictionary
            let pieceId = piece["id"] as! Int
            
            if sender.selected != true {
                sender.selected = true
                
                likedPiece(piece)
            } else {
                sender.selected = false
                
                unlikedPiece(piece)
            }
        }
    }
    
    func showMoreOptions(sender: UIButton) {
        let ownerId = user["id"] as! Int
        let outfitId = outfit["id"] as! Int
        
        delegate?.showMoreOptions(ownerId, targetId: outfitId)
    }
    
    func retrieveRecentComments(poutfitIdentifier: String) {
        // firebase retrieve 3 most recent comments
        numTotalComments = 0
        recentComments.removeAll()
        
        poutfitCommentsRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)/comments")
        
        childAddedHandle = poutfitCommentsRef.queryOrderedByChild("created_at").queryLimitedToLast(3).observeEventType(.ChildAdded, withBlock: { snapshot in
            // do some stuff once
            
            if (snapshot.value as? NSNull) != nil {
                // does not exist
                println("Error: (OutfitDetailsCell) poutfitCommentsRef does not exist")
            } else {
                // retrieve total number of comments
                let poutfitCommentCountRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)/num_comments")
                
                poutfitCommentCountRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                    if (snapshot.value as? NSNull) != nil {
                        // does not exist
                        println("Error: (OutfitDetailsCell) poutfitCommentCountRef does not exist")
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
                        println("Error: (OutfitDetailsCell) commentRef does not exist")
                    } else {
                        var comment = snapshot.value as! NSDictionary
                        
                        self.recentComments.append(comment)
                        
                        if self.recentComments.count > 3 {
                            // remove oldest (first one)
                            self.recentComments.removeAtIndex(0)
                        }
                        
                        var nsPath = NSIndexPath(forRow: 4, inSection: 0)
                        self.tableView.reloadRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.None)
                    }
                })
            }
        })
        
        retrieveRecentLikes(poutfitIdentifier)
    }
    
    func retrieveRecentLikes(poutfitIdentifier: String) {
        // retrieve total number of likes
        let poutfitLikesCountRef = firebaseRef.childByAppendingPath("poutfits/\(poutfitIdentifier)/num_likes")
        
        numTotalLikes = 0
        
        poutfitLikesCountRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if (snapshot.value as? NSNull) != nil {
                // does not exist
                println("Error: (PieceDetailsCell) poutfitLikesCountRef does not exist")
            } else {
                self.numTotalLikes = snapshot.value as! Int
                
                var nsPath = NSIndexPath(forRow: 2, inSection: 0)
                self.tableView.reloadRowsAtIndexPaths([nsPath], withRowAnimation: UITableViewRowAnimation.None)
            }
        })
    }
    
    func facebookTapped(sender: UIButton) {
        let outfitImagesString = outfit["images"] as! String
        let outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        let outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
        let outfitThumbnailUrl = outfitImageDict["thumbnail"] as! String
        
        let content : FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = NSURL(string: "http://www.sprubix.com/")
        content.contentTitle = outfit["description"] as! String
        content.contentDescription = "Check this outfit out! Download the Sprubix app now."
        content.imageURL = NSURL(string: outfitThumbnailUrl)
        
        let button : FBSDKShareButton = FBSDKShareButton()
        button.shareContent = content
        button.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        
        // Mixpanel - Share, Facebook
        mixpanel.track("Share", properties: [
            "Type": "Outfit",
            "Platform": "Facebook"
        ])
        // Mixpanel - End
    }
    
    func instagramTapped(sender: UIButton) {
        let instagramUrl = NSURL(string: "instagram://app")
        if(UIApplication.sharedApplication().canOpenURL(instagramUrl!)){
            
            // calculate resized image for IG
            var outfitImagesString = outfit["images"] as! NSString
            var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
            
            var imageURLString = outfitImageDict["original"] as! String
            var imageURL = NSURL(string: imageURLString)
            var data = NSData(contentsOfURL: imageURL!)
            var outfitImage: UIImage = UIImage(data: data!)!
            
            // instagram now allows portrait of aspect ratios between 1.91:1 and 4:5
            // e.g. width: 750px, height: 937.5px
            var IGFrameWidth: CGFloat = 750.0
            var IGFrameHeight: CGFloat = 750.0 //(IGFrameWidth / 4) * 5
            var IGFrameSize: CGSize = CGSizeMake(IGFrameWidth, IGFrameHeight)
            
            // outfit height needs to be equal to IGFrameHeight
            var realWidth: CGFloat = outfitImage.scale * outfitImage.size.width
            var realHeight: CGFloat = outfitImage.scale * outfitImage.size.height
            var finalHeight: CGFloat = IGFrameHeight
            var finalWidth: CGFloat = (realWidth / realHeight) * finalHeight
            
            UIGraphicsBeginImageContextWithOptions(IGFrameSize, false, 0.0) // avoid image quality degrading
            
            outfitImage.drawInRect(CGRectMake((IGFrameWidth - finalWidth)/2, 0, finalWidth, finalHeight))
            
            // final image
            var finalImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            // Instagram App avaible
            let imageData = UIImageJPEGRepresentation(finalImage, 0.9)
            let captionString = outfit["description"] as! String
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
                        "Type": "Outfit",
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
    
    func spruceButtonPressed(sender: UIButton) {
        let spruceViewController = SpruceViewController()
        spruceViewController.outfit = outfit
        spruceViewController.userIdFrom = user["id"] as! Int
        spruceViewController.usernameFrom = user["username"] as! String
        spruceViewController.userThumbnailFrom = user["image"] as! String
        
        navController?.delegate = nil
        navController?.pushViewController(spruceViewController, animated: true)
        
        // Mixpanel - Spruce Outfit
        mixpanel.track("Spruce Outfit", properties: [
            "Source": "Outfit View",
            "Outfit ID": outfit.objectForKey("id") as! Int,
            "Owner User ID": outfit.objectForKey("user_id") as! Int
        ])
        // Mixpanel - End
    }

}

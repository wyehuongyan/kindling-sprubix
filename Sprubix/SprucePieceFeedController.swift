//
//  SprucePieceFeedController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 21/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

protocol SprucePieceFeedProtocol {
    func deleteSprucePieceFeed(sprucePieceFeedController: SprucePieceFeedController)
    func resizeOutfit()
}

class SprucePieceFeedController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var delegate: SprucePieceFeedProtocol?
    
    var piece: NSDictionary?
    var outfit: NSDictionary?
    
    let sprucePieceFeedCellIdentifier = "sprucePieceFeedCell"
    
    let arrowButtonHeight:CGFloat = 25
    let arrowButtonPadding:CGFloat = 10
    
    var pieceType: String!
    var pieceHeight: CGFloat!
    var pieceId: Int?
    var sprucePieces: [NSDictionary] = [NSDictionary]()
    
    var leftArrowButton:UIButton!
    var rightArrowButton:UIButton!
    
    var deleteOverlay:UIView!
    
    var scrolling:Bool = false
    var index:Int! // current page
    var currentVisibleCell: SprucePieceFeedCell!
    var currentPage: Int = 0
    var lastPage: Int?
    
    var startingPieceHeight: CGFloat!
    
    init(collectionViewLayout layout: UICollectionViewLayout!, pieceType: String, pieceHeight: CGFloat = 0, pieceId: Int? = nil, outfit: NSDictionary? = nil) {
        super.init(collectionViewLayout:layout)
        
        self.pieceType = pieceType
        self.pieceHeight = pieceHeight
        self.pieceId = pieceId
        self.outfit = outfit
        
        // store original starting heights
        self.startingPieceHeight = pieceHeight
        
        let collectionView: UICollectionView = self.collectionView!;
        collectionView.pagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = sprubixGray
        
        collectionView.registerClass(SprucePieceFeedCell.self, forCellWithReuseIdentifier: sprucePieceFeedCellIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initButtons()
        retrievePiecesOfType(pieceType)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func initButtons() {
        // left
        leftArrowButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        
        setLeftArrowButtonFrame(pieceHeight)
        
        leftArrowButton.backgroundColor = UIColor.clearColor()
        leftArrowButton.setImage(UIImage(named: "spruce-arrow-left"), forState: UIControlState.Normal)
        leftArrowButton.setImage(UIImage(named: "spruce-arrow-left"), forState: UIControlState.Selected)
        leftArrowButton.tintColor = UIColor.whiteColor()
        leftArrowButton.autoresizesSubviews = true
        leftArrowButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        leftArrowButton.exclusiveTouch = true
        leftArrowButton.addTarget(self, action: "leftArrowPressed:", forControlEvents: UIControlEvents.TouchUpInside)

        Glow.addGlow(leftArrowButton)
        
        view.addSubview(leftArrowButton)
        
        // right
        rightArrowButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        
        setRightArrowButtonFrame(pieceHeight)
       
        rightArrowButton.backgroundColor = UIColor.clearColor()
        rightArrowButton.setImage(UIImage(named: "spruce-arrow-right"), forState: UIControlState.Normal)
        rightArrowButton.setImage(UIImage(named: "spruce-arrow-right"), forState: UIControlState.Selected)
        rightArrowButton.tintColor = UIColor.whiteColor()
        rightArrowButton.autoresizesSubviews = true
        rightArrowButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleWidth
        rightArrowButton.exclusiveTouch = true
        rightArrowButton.addTarget(self, action: "rightArrowPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        Glow.addGlow(rightArrowButton)
        
        view.addSubview(rightArrowButton)
    }
    
    func setLeftArrowButtonFrame(pieceHeight: CGFloat) {
        let arrowButtonYPos:CGFloat = pieceHeight / 2 - arrowButtonHeight / 2
        
        leftArrowButton.frame = CGRect(x: arrowButtonPadding, y: arrowButtonYPos, width: arrowButtonHeight, height: arrowButtonHeight)
        
        if pieceHeight <= 0 {
            leftArrowButton.alpha = 0.0
        } else {
            leftArrowButton.alpha = 1.0
        }
    }
    
    func setRightArrowButtonFrame(pieceHeight: CGFloat) {
        let arrowButtonYPos:CGFloat = pieceHeight / 2 - arrowButtonHeight / 2
        
        rightArrowButton.frame = CGRect(x: screenWidth - arrowButtonHeight - arrowButtonPadding, y: arrowButtonYPos, width: arrowButtonHeight, height: arrowButtonHeight)
        
        if pieceHeight <= 0 {
            rightArrowButton.alpha = 0.0
        } else {
            rightArrowButton.alpha = 1.0
        }
    }
    
    func showDeletionCrosses() {
        // hide the arrows
        leftArrowButton.hidden = true
        rightArrowButton.hidden = true
        
        // a darkened UIView with a red deletion cross at the top left corner is shown
        deleteOverlay = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: pieceHeight))
        deleteOverlay.backgroundColor = UIColor.blackColor()
        deleteOverlay.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.3)
        deleteOverlay.alpha = 0
        
        var deleteCross = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        deleteCross.frame = CGRect(x: screenWidth - arrowButtonPadding - 30, y: arrowButtonPadding, width: 30, height: 30)
        deleteCross.setTitle("X", forState: UIControlState.Normal)
        deleteCross.titleLabel?.font = UIFont(name: deleteCross.titleLabel!.font.fontName, size: 24)
        deleteCross.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        deleteCross.exclusiveTouch = true
        deleteCross.addTarget(self, action: "deleteSprucePieceFeed", forControlEvents: UIControlEvents.TouchUpInside)
        
        deleteOverlay.addSubview(deleteCross)
        
        view.addSubview(deleteOverlay)
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.deleteOverlay.alpha = 1.0
            }, completion: nil)
    }
    
    func hideDeletionCrosses() {
        // show the arrows
        leftArrowButton.hidden = false
        rightArrowButton.hidden = false
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9 , initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.deleteOverlay.alpha = 0
            }, completion: { finished in
                if finished {
                    self.deleteOverlay.removeFromSuperview()
                    self.deleteOverlay = nil
                }
        })
    }
    
    func deleteSprucePieceFeed() {
        // called when red deletion cross is pressed
        delegate?.deleteSprucePieceFeed(self)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sprucePieces.count
    }

    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // when pieces are swiped
        setCurrentVisibleCell()
        
        // Mixpanel - Spruce Outfit Swipe, Swipe
        let visibleRect: CGRect = CGRect(origin: self.collectionView!.contentOffset, size: self.collectionView!.bounds.size)
        let visiblePoint: CGPoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect))
        var visibleIndexPath: NSIndexPath? = self.collectionView!.indexPathForItemAtPoint(visiblePoint)
        
        if visibleIndexPath != nil {
            currentVisibleCell = self.collectionView!.cellForItemAtIndexPath(visibleIndexPath!) as! SprucePieceFeedCell
            index = visibleIndexPath!.item
            
            mixpanel.track("Spruce Outfit Swipe", properties: [
                "Piece ID": (self.collectionView?.cellForItemAtIndexPath(visibleIndexPath!) as! SprucePieceFeedCell).piece.objectForKey("id") as! Int,
                "Owner User ID": (self.collectionView?.cellForItemAtIndexPath(visibleIndexPath!) as! SprucePieceFeedCell).piece.objectForKey("user_id") as! Int,
                "Type": "Swipe"
                ])
            mixpanel.people.increment("Spruce Outfit Swipe", by: 1)
        }
        // Mixpanel - End
        
        delegate?.resizeOutfit()
        checkPagination()
    }
    
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        // when arrows are pressed
        let indexPath: NSIndexPath = NSIndexPath(forItem: index, inSection: 0)
        
        currentVisibleCell = self.collectionView?.cellForItemAtIndexPath(indexPath) as! SprucePieceFeedCell
        
        scrolling = false
        
        // Mixpanel - Spruce Outfit Swipe, Click
        mixpanel.track("Spruce Outfit Swipe", properties: [
            "Piece ID": (self.collectionView?.cellForItemAtIndexPath(indexPath) as! SprucePieceFeedCell).piece.objectForKey("id") as! Int,
            "Owner User ID": (self.collectionView?.cellForItemAtIndexPath(indexPath) as! SprucePieceFeedCell).piece.objectForKey("user_id") as! Int,
            "Type": "Click"
        ])
        mixpanel.people.increment("Spruce Outfit Swipe", by: 1)
        // Mixpanel - End
        
        delegate?.resizeOutfit()
        checkPagination()
    }
    
    func checkPagination() {
        if index >= sprucePieces.count - 1 {
            insertMorePiecesOfType(pieceType)
        }
    }
    
    func setCurrentVisibleCell() {
        let visibleRect: CGRect = CGRect(origin: self.collectionView!.contentOffset, size: self.collectionView!.bounds.size)
        
        let visiblePoint: CGPoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect))
        
        //println("collectionview: \(self.collectionView)")
        
        var visibleIndexPath: NSIndexPath? = self.collectionView!.indexPathForItemAtPoint(visiblePoint)
        
        if visibleIndexPath != nil {
            currentVisibleCell = self.collectionView!.cellForItemAtIndexPath(visibleIndexPath!) as! SprucePieceFeedCell
            
            index = visibleIndexPath!.item
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let collectionCell: SprucePieceFeedCell = collectionView.dequeueReusableCellWithReuseIdentifier(sprucePieceFeedCellIdentifier, forIndexPath: indexPath) as! SprucePieceFeedCell
        
        if indexPath.row == 0 {
            currentVisibleCell = collectionCell
            index = 0
        }
        
        let piece = sprucePieces[indexPath.row] as NSDictionary
        collectionCell.piece = piece
        
        let user = piece["user"] as! NSDictionary
        var userImageURL = user["image"] as? String
        let name = user["name"] as? String
        let username = user["username"] as? String
        
        if userImageURL != nil {
            collectionCell.userThumbnail.setImageWithURL(NSURL(string: userImageURL!))
        }
        
        collectionCell.priceLabel.alpha = 0.0
        
        let shoppable = user["shoppable"] as? NSDictionary
        
        if shoppable != nil {
            let buyable: Bool? = shoppable!["purchasable"] as? Bool
            
            if buyable != nil && buyable! != false && piece["price"] as! String != "0.00" {
                if !piece["quantity"]!.isKindOfClass(NSNull) {

                    let price = piece["price"] as! String
                    let padding: CGFloat = 10
                    let priceLabelHeight: CGFloat = 35
                    
                    collectionCell.priceLabel.text = "$\(price)"
                    collectionCell.priceLabel.frame = CGRectMake(screenWidth - (collectionCell.priceLabel.intrinsicContentSize().width + 20.0) - padding, padding, (collectionCell.priceLabel.intrinsicContentSize().width + 20.0), priceLabelHeight)
                    
                    collectionCell.priceLabel.alpha = 1.0
                    
                }
            }
        }
        
        /*
        collectionCell.usernameLabel.text = username!
        
        if name != nil && name != "" {
            collectionCell.userRealNameLabel.text = name!
        } else {
            collectionCell.userRealNameLabel.text = username!
        }
        */
        
        collectionCell.setNeedsLayout()
        collectionCell.setNeedsDisplay()
        
        return collectionCell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.collectionView!.frame.size
    }
    
    func insertMorePiecesOfType(pieceType: String) {
        let nextPage = currentPage + 1
        
        if lastPage == nil || nextPage <= lastPage {
            let userId:Int? = defaults.objectForKey("userId") as? Int
            
            if userId != nil {
                if outfit != nil {
                    // get owner ids of each individual piece in the outfit
                    let pieces = outfit!["pieces"] as! [NSDictionary]
                    var ownerIds = [Int]()
                    
                    for piece in pieces {
                        var pieceType = piece["type"] as! String
                        
                        // except self
                        if pieceType != self.pieceType {
                            var owner = piece["user"] as! NSDictionary
                            var ownerId: Int = owner["id"] as! Int
                            
                            ownerIds.append(ownerId)
                        }
                    }
                    
                    manager.POST(SprubixConfig.URL.api + "/spruce/pieces?page=\(nextPage)",
                        parameters: [
                            "type" : pieceType,
                            "user_ids": ownerIds
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                            var pieces = responseObject["data"] as! [NSDictionary]
                            self.currentPage = responseObject["current_page"] as! Int
                            self.lastPage = responseObject["last_page"] as? Int
                            
                            self.collectionView?.performBatchUpdates({
                                // update data source
                                for var i = 0; i < pieces.count; i++ {
                                    let piece = pieces[i]
                                    
                                    self.sprucePieces.append(piece)
                                    
                                    self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forItem: self.sprucePieces.count - 1, inSection: 0)])
                                }
                                
                                }, completion: { finished in
                                    
                                    if finished {
                                        if self.piece == nil {
                                            // update current visible cell
                                            self.setCurrentVisibleCell()
                                            
                                            // resize
                                            self.delegate?.resizeOutfit()
                                        }
                                    }
                            })
                        },
                        failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                            println("Error: " + error.localizedDescription)
                    })
                    
                } else {
                    manager.POST(SprubixConfig.URL.api + "/pieces?page=\(nextPage)",
                        parameters: [
                            "type" : pieceType
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                            var pieces = responseObject["data"] as! [NSDictionary]
                            self.currentPage = responseObject["current_page"] as! Int
                            self.lastPage = responseObject["last_page"] as? Int
                            
                            self.collectionView?.performBatchUpdates({
                                // update data source
                                for var i = 0; i < pieces.count; i++ {
                                    let piece = pieces[i]
                                    
                                    self.sprucePieces.append(piece)
                                    
                                    self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forItem: self.sprucePieces.count - 1, inSection: 0)])
                                }
                                
                                }, completion: { finished in
                                    
                                    if finished {
                                        if self.piece == nil {
                                            // update current visible cell
                                            self.setCurrentVisibleCell()
                                            
                                            // resize
                                            self.delegate?.resizeOutfit()
                                        }
                                    }
                            })
                        },
                        failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                            println("Error: " + error.localizedDescription)
                    })
                }
            } else {
                println("userId not found, please login or create an account")
            }
        }
    }

    func retrievePiecesOfType(pieceType: String) {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            if outfit != nil {
                
                // get owner ids of each individual piece in the outfit
                let pieces = outfit!["pieces"] as! [NSDictionary]
                var ownerIds = [Int]()
                
                for piece in pieces {
                    var pieceType = piece["type"] as! String
                    
                    // except self
                    if pieceType != self.pieceType {
                        var owner = piece["user"] as! NSDictionary
                        var ownerId: Int = owner["id"] as! Int
                        
                        ownerIds.append(ownerId)
                    }
                }
                
                manager.POST(SprubixConfig.URL.api + "/spruce/pieces",
                    parameters: [
                        "type": pieceType,
                        "current_piece_id": pieceId != nil ? pieceId! : 0,
                        "user_ids": ownerIds
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        var pieces = responseObject["data"] as! [NSDictionary]
                        self.currentPage = responseObject["current_page"] as! Int
                        self.lastPage = responseObject["last_page"] as? Int
                        
                        self.collectionView?.performBatchUpdates({
                            // update data source
                            for var i = 0; i < pieces.count; i++ {
                                let piece = pieces[i]
                                
                                self.sprucePieces.append(piece)
                                
                                if self.piece != nil {
                                    // there's already a piece at position 0
                                    self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forItem: 1, inSection: 0)])
                                } else {
                                    self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                                }
                            }
                            
                            }, completion: { finished in
                                
                                if finished {
                                    if self.piece == nil {
                                        // update current visible cell
                                        self.setCurrentVisibleCell()
                                        
                                        // resize
                                        self.delegate?.resizeOutfit()
                                    }
                                }
                        })
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        SprubixReachability.handleError(error.code)
                })
                
            } else {
                manager.POST(SprubixConfig.URL.api + "/pieces",
                    parameters: [
                        "type" : pieceType
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        var pieces = responseObject["data"] as! [NSDictionary]
                        self.currentPage = responseObject["current_page"] as! Int
                        self.lastPage = responseObject["last_page"] as? Int
                        
                        self.collectionView?.performBatchUpdates({
                            // update data source
                            for var i = 0; i < pieces.count; i++ {
                                let piece = pieces[i]
                                
                                self.sprucePieces.append(piece)
                                
                                if self.piece != nil {
                                    // there's already a piece at position 0
                                    self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forItem: 1, inSection: 0)])
                                } else {
                                    self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                                }
                            }
                                
                            }, completion: { finished in
                                
                                if finished {
                                    if self.piece == nil {
                                        // update current visible cell
                                        self.setCurrentVisibleCell()
                                        
                                        // resize
                                        self.delegate?.resizeOutfit()
                                    }
                                }
                        })
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                        
                        SprubixReachability.handleError(error.code)
                })
            }
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    func insertMorePieces(pieces: [NSDictionary]) {
        collectionView?.performBatchUpdates({
            // update data source
            for piece in pieces {
                self.sprucePieces.insert(piece, atIndex: self.index)
                self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forItem: self.index, inSection: 0)])
            }
            
            }, completion: { finished in
                
                if finished {
                    // update current visible cell
                    self.setCurrentVisibleCell()
                    
                    // resize
                    self.delegate?.resizeOutfit()
                }
        })
    }
    
    // callback methods for arrows
    func leftArrowPressed(sender: UIButton) {
        if index > 0 && scrolling != true {
            index = index - 1
            
            let indexPath: NSIndexPath = NSIndexPath(forItem: index, inSection: 0)

            scrolling = true
            
            self.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
        }
    }
    
    func rightArrowPressed(sender: UIButton) {
        let numItems:Int = self.collectionView?.numberOfItemsInSection(0) as Int!
        
        if index < numItems - 1 && scrolling != true{
            index = index + 1
            
            let indexPath: NSIndexPath = NSIndexPath(forItem: index, inSection: 0)
            
            scrolling = true
            
            self.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
        }
    }
}

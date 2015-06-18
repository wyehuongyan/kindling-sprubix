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
    
    let sprucePieceFeedCellIdentifier = "sprucePieceFeedCell"
    
    let arrowButtonHeight:CGFloat = 25
    let arrowButtonPadding:CGFloat = 10
    
    var pieceType: String!
    var pieceHeight: CGFloat!
    var sprucePieces: [NSDictionary] = [NSDictionary]()
    
    var leftArrowButton:UIButton!
    var rightArrowButton:UIButton!
    
    var deleteOverlay:UIView!
    
    var scrolling:Bool = false
    var index:Int! // current page
    var currentVisibleCell: SprucePieceFeedCell!
    
    var startingPieceHeight: CGFloat!
    
    init(collectionViewLayout layout: UICollectionViewLayout!, pieceType: String, pieceHeight: CGFloat = 0) {
        super.init(collectionViewLayout:layout)
        
        self.pieceType = pieceType
        self.pieceHeight = pieceHeight
        
        // store original starting heights
        self.startingPieceHeight = pieceHeight
        
        let collectionView :UICollectionView = self.collectionView!;
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
    }
    
    func setRightArrowButtonFrame(pieceHeight: CGFloat) {
        let arrowButtonYPos:CGFloat = pieceHeight / 2 - arrowButtonHeight / 2
        
        rightArrowButton.frame = CGRect(x: screenWidth - arrowButtonHeight - arrowButtonPadding, y: arrowButtonYPos, width: arrowButtonHeight, height: arrowButtonHeight)
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
        deleteCross.frame = CGRect(x: arrowButtonPadding, y: arrowButtonPadding, width: 30, height: 30)
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
    
        delegate?.resizeOutfit()
    }
    
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        // when arrows are pressed
        let indexPath: NSIndexPath = NSIndexPath(forItem: index, inSection: 0)
        
        currentVisibleCell = self.collectionView?.cellForItemAtIndexPath(indexPath) as! SprucePieceFeedCell
        
        scrolling = false
        
        delegate?.resizeOutfit()
    }
    
    func setCurrentVisibleCell() {
        let visibleRect: CGRect = CGRect(origin: self.collectionView!.contentOffset, size: self.collectionView!.bounds.size)
        
        let visiblePoint: CGPoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect))
        
        let visibleIndexPath: NSIndexPath = self.collectionView!.indexPathForItemAtPoint(visiblePoint)!
        
        currentVisibleCell = self.collectionView!.cellForItemAtIndexPath(visibleIndexPath) as! SprucePieceFeedCell
        
        index = visibleIndexPath.item
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let collectionCell: SprucePieceFeedCell = collectionView.dequeueReusableCellWithReuseIdentifier(sprucePieceFeedCellIdentifier, forIndexPath: indexPath) as! SprucePieceFeedCell
        
        if indexPath.row == 0 {
            currentVisibleCell = collectionCell
            index = 0
        }
        
        collectionCell.piece = sprucePieces[indexPath.row] as NSDictionary
        
        collectionCell.setNeedsLayout()
        collectionCell.setNeedsDisplay()
        
        return collectionCell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.collectionView!.frame.size
    }
    
    func retrievePiecesOfType(pieceType: String) {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            // retrieve 3 example pieces
            manager.POST(SprubixConfig.URL.api + "/pieces",
                parameters: [
                    "type" : pieceType
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    var pieces = responseObject["data"] as! [NSDictionary]
                    
                    for piece in pieces {
                        self.sprucePieces.append(piece)
                    }
                    
                    self.collectionView?.reloadData()
                    self.collectionView?.layoutIfNeeded()

                    if self.piece == nil {
                        // does not have a piece initialized (could be removed by owner)
                        // // resize outfit on the new piece from server
                        self.delegate?.resizeOutfit()
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
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

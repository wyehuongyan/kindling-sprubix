//
//  PieceDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

protocol PieceInteractionProtocol {
    func likedPiece(piece: NSDictionary)
    func unlikedPiece(piece: NSDictionary)
}

class PieceDetailsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, TransitionProtocol, HorizontalPageViewControllerProtocol, PieceDetailsOutfitProtocol, DetailsCellActions {
    var pieceInteractionDelegate: PieceInteractionProtocol?
    
    let pieceDetailsCellIdentifier = "PieceDetailsCell"
    
    var parentOutfitId: Int? // to detect if this piece was accessed from an outfit
    var pieces: [NSDictionary] = [NSDictionary]()
    var inspiredBy: NSDictionary!
    var user: NSDictionary!
    var pullOffset = CGPointZero
    
    var piecesRelevantCollectionView: UICollectionView? // relevant outfit collection from pieceDetailsCell
    
    init(collectionViewLayout layout: UICollectionViewLayout!, currentIndexPath indexPath: NSIndexPath){
        super.init(collectionViewLayout:layout)
        
        let collectionView :UICollectionView = self.collectionView!;
        collectionView.pagingEnabled = true
        collectionView.backgroundColor = UIColor.whiteColor()
        
        collectionView.registerClass(PieceDetailsCell.self, forCellWithReuseIdentifier: pieceDetailsCellIdentifier)
        collectionView.setToIndexPath(indexPath)
        
        collectionView.performBatchUpdates({collectionView.reloadData()}, completion: { finished in
            if finished {
                collectionView.scrollToItemAtIndexPath(indexPath,atScrollPosition:.CenteredHorizontally, animated: false)
                
                // Mixpanel - Viewed Piece Details
                mixpanel.track("Viewed Piece Details", properties: [
                    "Piece ID": self.pieces[indexPath.row].objectForKey("id") as! Int,
                    "Owner User ID": self.pieces[indexPath.row].objectForKey("user_id") as! Int
                ])
                mixpanel.people.increment("Viewed Piece Details", by: 1)
                // Mixpanel - End
            }})
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.collectionView!.frame.size
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let collectionCell: PieceDetailsCell = collectionView.dequeueReusableCellWithReuseIdentifier(pieceDetailsCellIdentifier, forIndexPath: indexPath) as! PieceDetailsCell
        
        var piece = pieces[indexPath.row] as NSDictionary
        
        collectionCell.piece = piece
        collectionCell.parentOutfitId = parentOutfitId
        collectionCell.user = piece["user"] as! NSDictionary
        collectionCell.inspiredBy = piece["inspired_by"] as? NSDictionary // should be removed
        collectionCell.detailsCellActionDelegate = self
        
        collectionCell.tappedAction = {}
        collectionCell.doubleTappedAction = { like in
            
            if like == true {
                self.pieceInteractionDelegate?.likedPiece(piece)
            } else {
                self.pieceInteractionDelegate?.unlikedPiece(piece)
            }
            
            return
        }
        
        // return to previous
        collectionCell.pullAction = { offset in            
            self.pullOffset = offset
           
            // reset to nil
            collectionCell.commentsViewController = nil
            
            self.returnToPrevious()
        }
        
        // return to main feed
        collectionCell.returnAction = { Void in
            self.returnToMainFeed()
            
            return
        }
        
        collectionCell.navController = self.navigationController
        collectionCell.delegate = self
        
        collectionCell.initPieceCollectionView()
        
        collectionCell.setNeedsLayout()
        collectionCell.layoutIfNeeded()
        
        return collectionCell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return pieces.count
    }
    
    private func returnToPrevious() {
        var childrenCount = self.navigationController!.viewControllers.count
        var prevChild: AnyObject = self.navigationController!.viewControllers[childrenCount-2]
        
        if prevChild.isKindOfClass(OutfitDetailsViewController) || prevChild.isKindOfClass(NotificationViewController) || prevChild.isKindOfClass(CartViewController) {
            //println("this is how we roll")
            self.navigationController!.delegate = nil
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = kCATransitionReveal
            transition.subtype = kCATransitionFromBottom
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
            self.navigationController!.popViewControllerAnimated(false)
        } else {
            self.navigationController!.delegate = transitionDelegateHolder
            self.navigationController!.popViewControllerAnimated(true)
        }
    }
    
    private func returnToMainFeed() {
        self.navigationController!.delegate = transitionDelegateHolder
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromBottom
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
        
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    // TransitionProtocol
    func transitionCollectionView() -> UICollectionView!{
        
        if piecesRelevantCollectionView != nil {
            //println("piecesCollectionView: \(piecesCollectionView)")
            return piecesRelevantCollectionView
        }
        
        return collectionView
    }
    
    // HorizontalPageViewControllerProtocol
    func pageViewCellScrollViewContentOffset() -> CGPoint{
        return self.pullOffset
    }
    
    // PieceDetailsOutfitProtocol
    func relevantOutfitSelected(collectionView: UICollectionView, index: NSIndexPath) {
        piecesRelevantCollectionView = collectionView
    }
    
    // DetailsCellActions
    func showMoreOptions(ownerId: Int, targetId: Int) {
        
        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertViewController.view.tintColor = UIColor.grayColor()
        
        // actions
        let reportAction = UIAlertAction(title: "Report inappropriate", style: UIAlertActionStyle.Default, handler: {
            action in
            // handler
            println("report")
        })
        
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        // check if you're the owner (i.e. person who posted this outfit)
        if userId != nil && userId == ownerId {
            let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {
                action in
                // handler
                var alert = UIAlertController(title: "Are you sure?", message: "Deleting this item is permanent!", preferredStyle: UIAlertControllerStyle.Alert)
                alert.view.tintColor = sprubixColor
                
                // Yes
                alert.addAction(UIAlertAction(title: "Yes, delete it", style: UIAlertActionStyle.Default, handler: { action in
                    
                    // REST call to server to delete outfit id
                    manager.DELETE(SprubixConfig.URL.api + "/piece/\(targetId)",
                        parameters: [
                            "owner_id": ownerId
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject:
                            AnyObject!) in
                            
                            var result = responseObject as! NSDictionary
                            
                            if result["status"] as! String == "200" {
                                // deleted successfully
                                // // go back one state
                                println("Notification: Piece deleted successfully!")
                                self.returnToPrevious()
                            } else {
                                // failed to delete
                                // // notify user
                            }
                            
                        },
                        failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                            println("Error: " + error.localizedDescription)
                    })
                }))
                
                // No
                alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
            })
            
            alertViewController.addAction(deleteAction)
        }
        
        // cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {
            action in
            // handler
            self.dismissViewControllerAnimated(true, completion: nil)
            alertViewController.removeFromParentViewController()
        })
        
        alertViewController.addAction(reportAction)
        alertViewController.addAction(cancelAction)
        
        self.presentViewController(alertViewController, animated: true, completion: nil)
    }
}

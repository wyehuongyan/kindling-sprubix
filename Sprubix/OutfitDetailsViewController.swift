//
//  OutfitDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import MRProgress

class OutfitDetailsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, TransitionProtocol, HorizontalPageViewControllerProtocol, DetailsCellActions {
    
    // loading overlay
    var overlay: MRProgressOverlayView!
    
    let outfitDetailsCellIdentifier = "OutfitDetailsCell"
    
    var outfits: [NSDictionary] = [NSDictionary]()
    var pullOffset = CGPointZero
    
    var currentVisibleOutfit: NSDictionary?
    var currentVisibleIndexPath: NSIndexPath?
    
    var delegate: OutfitInteractionProtocol?
    
    init(collectionViewLayout layout: UICollectionViewLayout!, currentIndexPath indexPath: NSIndexPath){
        super.init(collectionViewLayout:layout)
        
        let collectionView :UICollectionView = self.collectionView!;
        collectionView.pagingEnabled = true
        collectionView.backgroundColor = UIColor.whiteColor()
        
        collectionView.registerClass(OutfitDetailsCell.self, forCellWithReuseIdentifier: outfitDetailsCellIdentifier)
        collectionView.setToIndexPath(indexPath)
        
        collectionView.performBatchUpdates({collectionView.reloadData()}, completion: { finished in
            if finished {
                collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition:.CenteredHorizontally, animated: false)
                
                self.currentVisibleIndexPath = indexPath
                self.currentVisibleOutfit = self.outfits[indexPath.row]
                
                // Mixpanel People - Viewed Outfit Details
                mixpanel.people.increment("Outfit Details Viewed", by: 1)
                // Mixpanel - End
            }})
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if currentVisibleIndexPath != nil && currentVisibleOutfit != nil {
            let outfitId: Int = currentVisibleOutfit!["id"] as! Int
            
            // get most recent version of this outfit (some pieces could be deleted)
            manager.POST(SprubixConfig.URL.api + "/outfits",
                parameters: [
                    "id": outfitId
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    // replace outfit in outfits with latest
                    let updatedOutfit = (responseObject["data"] as! NSArray)[0] as! NSDictionary
                    
                    self.outfits.insert(updatedOutfit, atIndex: self.currentVisibleIndexPath!.row)
                    self.outfits.removeAtIndex(self.currentVisibleIndexPath!.row + 1)
                    
                    let currentOutfitDetailsCell = self.collectionView?.cellForItemAtIndexPath(self.currentVisibleIndexPath!) as! OutfitDetailsCell
                    
                    currentOutfitDetailsCell.outfit = self.outfits[self.currentVisibleIndexPath!.row]
                    currentOutfitDetailsCell.tableView.reloadData()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
        
        self.navigationController?.navigationBarHidden = true
        
        containerViewController.statusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // when pieces are swiped
        setCurrentVisibleOutfit()
    }
    
    func setCurrentVisibleOutfit() {
        let visibleRect: CGRect = CGRect(origin: self.collectionView!.contentOffset, size: self.collectionView!.bounds.size)
        
        let visiblePoint: CGPoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect))
        
        let visibleIndexPath: NSIndexPath = self.collectionView!.indexPathForItemAtPoint(visiblePoint)!
        
        currentVisibleIndexPath = visibleIndexPath
        currentVisibleOutfit = outfits[visibleIndexPath.row]
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.collectionView!.frame.size
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let collectionCell: OutfitDetailsCell = collectionView.dequeueReusableCellWithReuseIdentifier(outfitDetailsCellIdentifier, forIndexPath: indexPath) as! OutfitDetailsCell
        
        var outfit = outfits[indexPath.row] as NSDictionary
        var inspiredBy: AnyObject = outfit["inspired_by"]! // the immediate previous person (not the true owner)
        
        if inspiredBy.isKindOfClass(NSNull) {
            collectionCell.inspiredBy = nil
        } else {            
            collectionCell.inspiredBy = outfit["inspired_by"] as! NSDictionary
        }
        
        collectionCell.user = outfit["user"] as! NSDictionary!
        collectionCell.outfit = outfit
        collectionCell.delegate = self
        
        collectionCell.tappedAction = {}
        
        // return to previous
        collectionCell.pullAction = { offset in
            self.pullOffset = offset
            
            // reset to nil
            collectionCell.commentsViewController = nil
            collectionCell.buyPieceInfo?.removeAllObjects()
            
            self.returnToPrevious()
        }
        
        // return to main feed
        collectionCell.returnAction = { Void in
            self.returnToMainFeed()
            
            return
        }

        collectionCell.navController = self.navigationController
        
        collectionCell.initOutfitTableView()
        
        collectionCell.setNeedsLayout()
        collectionCell.setNeedsDisplay()
        
        return collectionCell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return outfits.count
    }
    
    private func returnToPrevious() {
        var childrenCount = self.navigationController!.viewControllers.count
        var prevChild: AnyObject = self.navigationController!.viewControllers[childrenCount-2]
        
        if prevChild.isKindOfClass(NotificationViewController) || prevChild.isKindOfClass(CheckoutPointsViewController) {
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
        return collectionView
    }
    
    func pageViewCellScrollViewContentOffset() -> CGPoint{
        return self.pullOffset
    }
    
    // DetailsCellActions
    func showMoreOptions(ownerId: Int, targetId: Int) {
        
        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertViewController.view.tintColor = UIColor.grayColor()
        
        // actions
        let reportAction = UIAlertAction(title: "Report inappropriate", style: UIAlertActionStyle.Default, handler: {
            action in

            // init overlay
            self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, title: "Submitting...", mode: MRProgressOverlayViewMode.Indeterminate, animated: true)
            
            self.overlay.tintColor = sprubixColor

            // REST call to server to report inappropriate
            manager.POST(SprubixConfig.URL.api + "/mail/report",
                parameters: [
                    "poutfit_type": "Outfit",
                    "poutfit_id": targetId
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    self.overlay.dismiss(true)
                    
                    var result = responseObject as! NSDictionary
                    
                    if result["status"] as! String == "200" {
                        // reported successfully
                        // // go back one state
                        var alert = UIAlertController(title: "Report Submitted", message: "Thank you. We will be looking into this shortly.", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.view.tintColor = sprubixColor
                        
                        // Yes
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { action in
                            
                            //self.returnToPrevious()
                        }))
                        
                        self.presentViewController(alert, animated: true, completion: nil)
                        
                    } else {
                        // failed to report
                        // // notify user
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)

                    self.overlay.dismiss(true)
            })
        })
        
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        // check if you're the owner (i.e. person who posted this outfit)
        if userId != nil && userId == ownerId {
            let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {
                action in
                // handler
                var alert = UIAlertController(title: "Are you sure?", message: "Deleting this outfit is permanent!", preferredStyle: UIAlertControllerStyle.Alert)
                alert.view.tintColor = sprubixColor
                
                // Yes
                alert.addAction(UIAlertAction(title: "Yes, delete it", style: UIAlertActionStyle.Default, handler: { action in
                    
                    // REST call to server to delete outfit id
                    manager.DELETE(SprubixConfig.URL.api + "/outfit/\(targetId)",
                        parameters: [
                            "owner_id": ownerId
                        ],
                        success: { (operation: AFHTTPRequestOperation!, responseObject:
                            AnyObject!) in
                            
                            var result = responseObject as! NSDictionary
                            
                            if result["status"] as! String == "200" {
                                // deleted successfully
                                // // go back one state
                                println("Notification: Outfit deleted successfully!")
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
    
    func setOutfitsLiked(outfitId: Int, liked: Bool) {
        delegate?.setOutfitsLiked(outfitId, liked: liked)
    }
    
    func likedOutfit(outfitId: Int, thumbnailURLString: String, itemIdentifier: String, receiver: NSDictionary) {
        delegate?.likedOutfit(outfitId, thumbnailURLString: thumbnailURLString, itemIdentifier: itemIdentifier, receiver: receiver)
    }
    
    func unlikedOutfit(outfitId: Int, itemIdentifier: String, receiver: NSDictionary) {
        delegate?.unlikedOutfit(outfitId, itemIdentifier: itemIdentifier, receiver: receiver)
    }
}

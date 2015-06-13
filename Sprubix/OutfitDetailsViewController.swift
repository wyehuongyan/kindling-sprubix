//
//  OutfitDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class OutfitDetailsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, TransitionProtocol, HorizontalPageViewControllerProtocol, DetailsCellActions {
    let outfitDetailsCellIdentifier = "OutfitDetailsCell"
    
    var outfits: [NSDictionary] = [NSDictionary]()
    var pullOffset = CGPointZero
    
    init(collectionViewLayout layout: UICollectionViewLayout!, currentIndexPath indexPath: NSIndexPath){
        super.init(collectionViewLayout:layout)
        
        let collectionView :UICollectionView = self.collectionView!;
        collectionView.pagingEnabled = true
        collectionView.backgroundColor = UIColor.whiteColor()
        
        collectionView.registerClass(OutfitDetailsCell.self, forCellWithReuseIdentifier: outfitDetailsCellIdentifier)
        collectionView.setToIndexPath(indexPath)
        
        collectionView.performBatchUpdates({collectionView.reloadData()}, completion: { finished in
            if finished {
                collectionView.scrollToItemAtIndexPath(indexPath,atScrollPosition:.CenteredHorizontally, animated: false)
            }})
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = true
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
            
            var childrenCount = self.navigationController!.viewControllers.count
            var prevChild: AnyObject = self.navigationController!.viewControllers[childrenCount-2]
            
            // reset to nil
            collectionCell.commentsViewController = nil
            
            if prevChild.isKindOfClass(NotificationViewController) {
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
        
        // return to main feed
        collectionCell.returnAction = { Void in
            self.navigationController!.delegate = transitionDelegateHolder
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = kCATransitionReveal
            transition.subtype = kCATransitionFromBottom
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
            
            self.navigationController?.popToRootViewControllerAnimated(true)
            
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
    
    func transitionCollectionView() -> UICollectionView!{
        return collectionView
    }
    
    func pageViewCellScrollViewContentOffset() -> CGPoint{
        return self.pullOffset
    }
    
    // DetailsCellActions
    func showMoreOptions(ownerId: Int) {
        
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
                println("delete")
            })
            
            alertViewController.addAction(deleteAction)
        }
        
        // cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {
            action in
            // handler
            println("cancel")
            
            self.dismissViewControllerAnimated(true, completion: nil)
            alertViewController.removeFromParentViewController()
        })
        
        alertViewController.addAction(reportAction)
        alertViewController.addAction(cancelAction)
        
        self.presentViewController(alertViewController, animated: true, completion: nil)
    }
}

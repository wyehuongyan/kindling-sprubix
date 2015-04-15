//
//  OutfitDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class OutfitDetailsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, TransitionProtocol, HorizontalPageViewControllerProtocol {
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
        let collectionCell: OutfitDetailsCell = collectionView.dequeueReusableCellWithReuseIdentifier(outfitDetailsCellIdentifier, forIndexPath: indexPath) as OutfitDetailsCell
        
        var outfit = outfits[indexPath.row] as NSDictionary
        var inspiredBy: AnyObject = outfit["inspired_by"]!
        
        if inspiredBy.isKindOfClass(NSNull) {
            collectionCell.inspiredBy = nil
        } else {            
            collectionCell.inspiredBy = outfit["inspired_by"] as NSDictionary!
        }
        
        collectionCell.user = outfit["user"] as NSDictionary!
        collectionCell.outfit = outfit
        
        collectionCell.tappedAction = {}
        
        // return to previous
        collectionCell.pullAction = { offset in
            self.pullOffset = offset
            
            self.navigationController!.delegate = transitionDelegateHolder
            self.navigationController!.popViewControllerAnimated(true)
        }
        
        // return to main feed
        collectionCell.returnAction = { Void in
            self.navigationController!.delegate = nil
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = kCATransitionReveal
            transition.subtype = kCATransitionFromBottom
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
            
            self.navigationController?.popToViewController(self.navigationController?.viewControllers.first! as UIViewController, animated: false)
            
            return
        }

        collectionCell.navController = self.navigationController
        
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
}

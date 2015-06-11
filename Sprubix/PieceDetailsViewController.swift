//
//  PieceDetailsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class PieceDetailsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, TransitionProtocol, HorizontalPageViewControllerProtocol, PieceDetailsOutfitProtocol {
    let pieceDetailsCellIdentifier = "PieceDetailsCell"
    
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
        
        collectionCell.user = piece["user"] as! NSDictionary
        collectionCell.inspiredBy = piece["inspired_by"] as? NSDictionary // supposed to be previous
        collectionCell.tappedAction = {}
        
        // return to previous
        collectionCell.pullAction = { offset in            
            self.pullOffset = offset
            
            var childrenCount = self.navigationController!.viewControllers.count
            var prevChild: AnyObject = self.navigationController!.viewControllers[childrenCount-2]
            
            // reset to nil
            collectionCell.commentsViewController = nil
            
            if prevChild.isKindOfClass(OutfitDetailsViewController) || prevChild.isKindOfClass(NotificationViewController) {
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
        collectionCell.delegate = self
        
        collectionCell.initPieceCollectionView()
        
        collectionCell.setNeedsLayout()
        collectionCell.layoutIfNeeded()
        
        return collectionCell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return pieces.count
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
}

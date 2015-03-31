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
        
        collectionCell.outfit = outfit
        collectionCell.tappedAction = {}
        collectionCell.pullAction = { offset in
            self.pullOffset = offset
            
            //var childrenCount = self.navigationController!.viewControllers.count
            //println("prev child: \(self.navigationController!.viewControllers[childrenCount-2])")
            
            self.navigationController!.delegate = transitionDelegateHolder
            self.navigationController!.popViewControllerAnimated(true)
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

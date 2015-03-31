//
//  TransitionProtocol.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

@objc protocol TransitionProtocol{
    func transitionCollectionView() -> UICollectionView!
}

@objc protocol TransitionWaterfallGridViewProtocol{
    func snapShotForTransition() -> UIView!
}

@objc protocol WaterFallViewControllerProtocol : TransitionProtocol{
    func viewWillAppearWithPageIndex(pageIndex : NSInteger)
}

@objc protocol HorizontalPageViewControllerProtocol : TransitionProtocol{
    func pageViewCellScrollViewContentOffset() -> CGPoint
}
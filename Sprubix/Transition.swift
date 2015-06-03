//
//  Transition.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

let animationDuration = 0.35
//let animationScale = screenWidth/(gridWidth) // screenWidth / the width of waterfall collection view's grid

class Transition: NSObject, UIViewControllerAnimatedTransitioning {
    var presenting = false
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval{
        return animationDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as UIViewController!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as UIViewController!
        let containerView = transitionContext.containerView()
        
        if presenting {
            let toView = toViewController.view
            containerView.addSubview(toView)
            toView.hidden = true
            
            let waterFallView = (toViewController as! TransitionProtocol).transitionCollectionView()
            let pageView = (fromViewController as! TransitionProtocol).transitionCollectionView()
            waterFallView.layoutIfNeeded()
            let indexPath = pageView.fromPageIndexPath()
            let gridView = waterFallView.cellForItemAtIndexPath(indexPath)
            
            if gridView != nil {
                let leftUpperPoint = gridView != nil ? gridView!.convertPoint(CGPointZero, toView: nil) : CGPointZero
                
                let snapShot = (gridView as! TransitionWaterfallGridViewProtocol).snapShotForTransition()

                let animationScale = screenWidth/(snapShot.frame.width)
                
                snapShot.transform = CGAffineTransformMakeScale(animationScale, animationScale)
                let pullOffsetY = (fromViewController as! HorizontalPageViewControllerProtocol).pageViewCellScrollViewContentOffset().y
                let offsetY : CGFloat = fromViewController.navigationController?.navigationBarHidden != false ? 0.0 : navigationHeaderAndStatusbarHeight
                
                snapShot.origin(CGPointMake(0, -pullOffsetY+offsetY))
                containerView.addSubview(snapShot)
                
                toView.hidden = false
                toView.alpha = 0
                toView.transform = snapShot.transform
                toView.frame = CGRectMake(-(leftUpperPoint.x * animationScale),-((leftUpperPoint.y-offsetY) * animationScale+pullOffsetY+offsetY),
                    toView.frame.size.width, toView.frame.size.height)
                let whiteViewContainer = UIView(frame: screenBounds)
                whiteViewContainer.backgroundColor = UIColor.whiteColor()
                containerView.addSubview(snapShot)
                containerView.insertSubview(whiteViewContainer, belowSubview: toView)
                
                UIView.animateWithDuration(fromViewController.navigationController != nil ? animationDuration : 0, animations: {
                    snapShot.transform = CGAffineTransformIdentity
                    snapShot.frame = CGRectMake(leftUpperPoint.x, leftUpperPoint.y, snapShot.frame.size.width, snapShot.frame.size.height)
                    toView.transform = CGAffineTransformIdentity
                    toView.frame = CGRectMake(0, 0, toView.frame.size.width, toView.frame.size.height);
                    toView.alpha = 1
                    }, completion:{finished in
                        if finished {
                            snapShot.removeFromSuperview()
                            whiteViewContainer.removeFromSuperview()
                            transitionContext.completeTransition(true)
                        }
                })
            } else {
                // due to PieceDetailsViewController's return to main feed
                toView.hidden = false
                toView.frame = CGRectMake(0, 0, toView.frame.size.width, toView.frame.size.height);
                toView.alpha = 1
                
                transitionContext.completeTransition(true)
            }
        }else{
            let fromView = fromViewController.view
            let toView = toViewController.view
            
            let waterFallView : UICollectionView = (fromViewController as! TransitionProtocol).transitionCollectionView()
            let pageView : UICollectionView = (toViewController as! TransitionProtocol).transitionCollectionView()
            
            let whiteViewContainer = UIView(frame: screenBounds)
            whiteViewContainer.backgroundColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1)
            
            containerView.addSubview(fromView)
            containerView.addSubview(toView)
            containerView.insertSubview(whiteViewContainer, belowSubview: toView)
            
            let indexPath = waterFallView.toIndexPath()
            let gridView = waterFallView.cellForItemAtIndexPath(indexPath)
            
            let leftUpperPoint = gridView!.convertPoint(CGPointZero, toView: nil)
            
            pageView.hidden = true
            pageView.scrollToItemAtIndexPath(indexPath, atScrollPosition:.CenteredHorizontally, animated: false)
            
            let offsetY : CGFloat = fromViewController.navigationController!.navigationBarHidden ? 0.0 : navigationHeaderAndStatusbarHeight
            
            let offsetStatuBar : CGFloat = fromViewController.navigationController!.navigationBarHidden ? 0.0 :
            statusbarHeight;
            
//            println("from")
//            println(waterFallView)
//            
//            println("to")
//            println(pageView)
//            
//            println("gridview")
//            println(gridView)
//            println(gridView as? TransitionWaterfallGridViewProtocol)
            
            let snapShot = (gridView as! TransitionWaterfallGridViewProtocol).snapShotForTransition()
            
            let animationScale = screenWidth/(snapShot.frame.width)
            
            containerView.addSubview(snapShot)
            snapShot.origin(leftUpperPoint)
            UIView.animateWithDuration(animationDuration, animations: {
                snapShot.transform = CGAffineTransformMakeScale(animationScale,
                    animationScale)
                snapShot.frame = CGRectMake(0, offsetY, snapShot.frame.size.width, snapShot.frame.size.height)
                
                fromView.alpha = 0
                fromView.transform = snapShot.transform
                fromView.frame = CGRectMake(-(leftUpperPoint.x)*animationScale,
                    -(leftUpperPoint.y-offsetStatuBar)*animationScale+offsetStatuBar,
                    fromView.frame.size.width,
                    fromView.frame.size.height)
                },completion:{finished in
                    if finished {
                        snapShot.removeFromSuperview()
                        pageView.hidden = false
                        whiteViewContainer.removeFromSuperview()
                        fromView.transform = CGAffineTransformIdentity
                        transitionContext.completeTransition(true)
                    }
            })
        }
    }
}

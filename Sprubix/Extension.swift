//
//  Extension.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    func origin (point : CGPoint){
        frame.origin.x = point.x
        frame.origin.y = point.y
    }
}

var kIndexPathPointer = "kIndexPathPointer"

extension NSURL {
    
    var allQueryItems: [NSURLQueryItem] {
        get {
            let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)!
            let allQueryItems = components.queryItems!
            return allQueryItems as! [NSURLQueryItem]
        }
    }
    
    func queryItemForKey(key: String) -> NSURLQueryItem? {
        
        let predicate = NSPredicate(format: "name=%@", key)
        return (allQueryItems as NSArray).filteredArrayUsingPredicate(predicate).first as? NSURLQueryItem
        
    }
}

extension UICollectionView{
    //    var currentIndexPath : NSIndexPath{
    //    get{
    //        return objc_getAssociatedObject(self,kIndexPathPointer) as NSIndexPath
    //    }set{
    //        objc_setAssociatedObject(self, kIndexPathPointer, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    //    }} WTF! error when building, it's a bug
    //    http://stackoverflow.com/questions/24021291/import-extension-file-in-swift
    
    func setToIndexPath (indexPath : NSIndexPath){
        objc_setAssociatedObject(self, &kIndexPathPointer, indexPath, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
    
    func toIndexPath () -> NSIndexPath {
        let index = self.contentOffset.x/self.frame.size.width
        if index > 0 {
            return NSIndexPath(forRow: Int(index), inSection: 0)
        }else if let indexPath = objc_getAssociatedObject(self,&kIndexPathPointer) as? NSIndexPath {
            return indexPath
        }else{
            return NSIndexPath(forRow: 0, inSection: 0)
        }
    }
    
    func fromPageIndexPath () -> NSIndexPath {
        let index : Int = Int(self.contentOffset.x/self.frame.size.width)
        return NSIndexPath(forRow: index, inSection: 0)
    }
}

extension UINavigationController {
    public override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return self.topViewController
    }
    
    public override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return self.topViewController
    }
}

//
//  SprubixStretchyHeader.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 10/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SprubixStretchyHeader: CHTCollectionViewWaterfallLayout {
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        var collectionView:UICollectionView = self.collectionView!
        var insets:UIEdgeInsets = collectionView.contentInset
        var offset:CGPoint = collectionView.contentOffset
        var minY:CGFloat = -insets.top
        
        // First get the superclass attributes.
        var attributes: NSArray = super.layoutAttributesForElementsInRect(rect)!
        
        // Check if we've pulled below past the lowest position
        if (offset.y < minY) {
            
            // Figure out how much we've pulled down
            var deltaY:CGFloat = fabs(offset.y - minY)
            
            for attrs in attributes {
                
                var attr = attrs as! UICollectionViewLayoutAttributes
                
                // Locate the header attributes
                var kind:NSString? = attr.representedElementKind
                
                if (kind == CHTCollectionElementKindSectionHeader) {
                    
                    // Adjust the header's height and y based on how much the user
                    // has pulled down.

                    var headerRect:CGRect = attr.frame
                    headerRect.size.height = max(minY, self.headerHeight + deltaY);
                    headerRect.origin.y = headerRect.origin.y - deltaY;
                    attr.frame = headerRect
                    break
                }
            }
        }
        
        return attributes as [AnyObject];
    }
}

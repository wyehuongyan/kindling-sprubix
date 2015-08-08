//
//  ProfileOutfitCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 10/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class ProfileOutfitCell: UICollectionViewCell, TransitionWaterfallGridViewProtocol {
    var imageURLString : String!
    var imageViewContent : UIImageView = UIImageView()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.lightGrayColor()
        layer.cornerRadius = 10.0
        clipsToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.lightGrayColor().CGColor
        
        contentView.addSubview(imageViewContent)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        let imageURL = NSURL(string: imageURLString!)
        
        imageViewContent.frame = CGRectMake(0, 0, frame.size.width, frame.size.height)
        
        imageViewContent.image = nil
        imageViewContent.setImageWithURL(imageURL)
        imageViewContent.contentMode = UIViewContentMode.ScaleAspectFill
    }
    
    func snapShotForTransition() -> UIView! {
        let snapShotView = UIImageView(image: self.imageViewContent.image)
        snapShotView.frame = imageViewContent.frame
        
        //println(snapShotView)
        
        return snapShotView
    }
}

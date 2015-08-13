//
//  ProfilePieceCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 12/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class ProfilePieceCell: UICollectionViewCell, TransitionWaterfallGridViewProtocol {
    var imageURLString : String!
    var imageViewContent : UIImageView = UIImageView()
    var imageGridSize: CGRect!
    
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
        snapShotView.contentMode = UIViewContentMode.ScaleAspectFit
        
        //var imageHeight = imageViewContent.frame.width / snapShotView.frame.width * snapShotView.frame.height
        //snapShotView.frame = CGRect(x: 0, y: 0, width: imageViewContent.frame.width, height: imageHeight)
        
        return snapShotView
    }
}

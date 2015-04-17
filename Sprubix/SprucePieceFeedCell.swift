//
//  SprucePieceFeedCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 21/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SprucePieceFeedCell: UICollectionViewCell {
    var pieceImageView: UIImageView = UIImageView()
    var piece: NSDictionary!
    
    var pieceHeight: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        
        contentView.addSubview(pieceImageView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // calculate piece UIImageView height
        var itemHeight = piece["height"] as! CGFloat
        var itemWidth = piece["width"] as! CGFloat
        
        pieceHeight = itemHeight * screenWidth / itemWidth
        
        var pieceImagesString = piece["images"] as! String
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        pieceImageView.image = nil
        pieceImageView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        pieceImageView.clipsToBounds = true
        pieceImageView.contentMode = UIViewContentMode.ScaleAspectFill
        //pieceImageView.userInteractionEnabled = true
        pieceImageView.frame = CGRect(x:0, y: 0, width: frame.size.width, height: frame.size.height)
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        var pieceCoverURL = NSURL(string: pieceImagesDict["cover"] as! String)
        
        pieceImageView.setImageWithURL(pieceCoverURL)
    }
}

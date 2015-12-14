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
    var compressedDueToDress: Bool!
    
    var userThumbnail: UIImageView!
    //var userRealNameLabel: UILabel!
    //var usernameLabel: UILabel!
    var priceLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        
        contentView.addSubview(pieceImageView)
        
        let userImageWidth: CGFloat = 35.0
        userThumbnail = UIImageView(frame: CGRectMake(10, 10, userImageWidth, userImageWidth))
        
        userThumbnail.contentMode = UIViewContentMode.ScaleAspectFit
        userThumbnail.layer.cornerRadius = userThumbnail.frame.size.width / 2
        userThumbnail.clipsToBounds = true
        userThumbnail.layer.borderWidth = 0.5
        userThumbnail.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        contentView.addSubview(userThumbnail)
        
        /*
        usernameLabel = UILabel(frame: CGRectMake(userThumbnail.frame.origin.x + userImageWidth + 5, 10, screenWidth / 2, userImageWidth / 2))
        
        usernameLabel.textColor = sprubixColor
        usernameLabel.font = UIFont.systemFontOfSize(12.0)
        
        contentView.addSubview(usernameLabel)
        
        userRealNameLabel = UILabel(frame: CGRectMake(userThumbnail.frame.origin.x + userImageWidth + 5, 10 + userImageWidth / 2, screenWidth / 2, userImageWidth / 2))
        
        userRealNameLabel.textColor = UIColor.grayColor()
        userRealNameLabel.font = UIFont.systemFontOfSize(12.0)
        
        contentView.addSubview(userRealNameLabel)
        */
        
        // price label
        let padding: CGFloat = 10
        let priceLabelHeight: CGFloat = 35
        priceLabel = UILabel()
        priceLabel.textAlignment = NSTextAlignment.Center
        priceLabel.font = UIFont.boldSystemFontOfSize(18.0)
        priceLabel.layer.cornerRadius = priceLabelHeight / 2
        priceLabel.clipsToBounds = true
        priceLabel.textColor = UIColor.whiteColor()
        priceLabel.backgroundColor = sprubixColor
        priceLabel.alpha = 0.0

        contentView.addSubview(priceLabel)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var pieceImagesString = piece["images"] as! String
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        pieceImageView.image = nil
        pieceImageView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        pieceImageView.clipsToBounds = true
        pieceImageView.contentMode = UIViewContentMode.ScaleAspectFit
        pieceImageView.backgroundColor = sprubixGray
        pieceImageView.frame = CGRect(x:0, y: 0, width: frame.size.width, height: frame.size.height)
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        var pieceCoverURL = NSURL(string: pieceImagesDict["cover"] as! String)
        
        pieceImageView.setImageWithURL(pieceCoverURL)
    }
}

//
//  CheckoutPointsSectionHeader.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CheckoutPointsSectionHeader: UITableViewCell {

    @IBOutlet var outfitImageView: UIImageView!
    @IBOutlet var addedFromOutfit: UILabel!
    
    var tappedOnOutfitAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        outfitImageView.backgroundColor = sprubixGray
        outfitImageView.contentMode = UIViewContentMode.ScaleAspectFit
        outfitImageView.layer.cornerRadius = 5
        outfitImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        outfitImageView.layer.borderWidth = 0.5
        outfitImageView.clipsToBounds = true
        
        contentView.backgroundColor = sprubixLightGray
        
        // gesture recognizer for outfit imageview
        let outfitImageSingleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "outfitTapped:")
        outfitImageView.addGestureRecognizer(outfitImageSingleTapGestureRecognizer)
        outfitImageView.userInteractionEnabled = true
        
        // // gesture recognizer for outfit username
        let addedFromOutfitSingleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "outfitTapped:")
        outfitImageView.addGestureRecognizer(addedFromOutfitSingleTapGestureRecognizer)
        outfitImageView.userInteractionEnabled = true
    }
    
    func outfitTapped(gesture: UITapGestureRecognizer) {
        tappedOnOutfitAction?()
    }
}

class CheckoutPointsIndividualSectionHeader: UITableViewCell {
    @IBOutlet var individuallyAdded: UILabel!
}

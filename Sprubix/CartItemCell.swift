//
//  CartItemCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 30/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CartItemCell: UITableViewCell {
    
    @IBOutlet var cartItemImageView: UIImageView!
    @IBOutlet var cartItemName: UILabel!
    @IBOutlet var cartItemPrice: UILabel!
    @IBOutlet var cartItemSize: UILabel!
    @IBOutlet var cartItemQuantity: UILabel!
    
    @IBOutlet var editCartItemButton: UIButton!
    @IBOutlet var deleteCartItemButton: UIButton!
    
    @IBAction func editCartItem(sender: AnyObject) {
        editCartItemAction?()
    }
    
    @IBAction func deleteCartItem(sender: AnyObject) {
        deleteCartItemAction?()
    }
    
    var editCartItemAction: (() -> Void)?
    var deleteCartItemAction: (() -> Void)?
    var tappedOnImageAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cartItemImageView.layer.cornerRadius = 8.0
        cartItemImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        cartItemImageView.layer.borderWidth = 0.5
        cartItemImageView.clipsToBounds = true
        
        editCartItemButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        //editCartItemButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        editCartItemButton.imageEdgeInsets = UIEdgeInsetsMake(0, 2, 2, 0)
        Glow.addGlow(editCartItemButton)
        
        deleteCartItemButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        // top, left, bottom, right
        deleteCartItemButton.imageEdgeInsets = UIEdgeInsetsMake(6, 8, 4, 2)
        Glow.addGlow(deleteCartItemButton)
        
        // gesture recognizer for item imageview
        let singleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "imageTapped:")
        cartItemImageView.addGestureRecognizer(singleTapGestureRecognizer)
        cartItemImageView.userInteractionEnabled = true
    }
    
    func imageTapped(gesture: UITapGestureRecognizer) {
        tappedOnImageAction?()
    }
}

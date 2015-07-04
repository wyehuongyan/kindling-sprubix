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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cartItemImageView.layer.cornerRadius = 8.0
        cartItemImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        cartItemImageView.layer.borderWidth = 0.5
        cartItemImageView.clipsToBounds = true
        
        editCartItemButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        editCartItemButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        Glow.addGlow(editCartItemButton)
        
        deleteCartItemButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        deleteCartItemButton.imageEdgeInsets = UIEdgeInsetsMake(9, 8, 7, 8)
        Glow.addGlow(deleteCartItemButton)
    }
}

//
//  OrderDetailsUserCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 20/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class OrderDetailsUserCell: UITableViewCell {
    let userImageViewWidth: CGFloat = 80.0
    var userImageView: UIImageView!
    
    var username: UILabel!
    var address: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // create user image view
        userImageView = UIImageView(frame: CGRectMake(10, 10, userImageViewWidth, userImageViewWidth))
        
        userImageView.backgroundColor = sprubixGray
        userImageView.contentMode = UIViewContentMode.ScaleAspectFit
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 0.5
        userImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        contentView.addSubview(userImageView)
        
        username = UILabel(frame: CGRectMake(userImageViewWidth + 20, 10, screenWidth - (userImageViewWidth + 20) - 10, 20))
        username.lineBreakMode = NSLineBreakMode.ByWordWrapping
        username.numberOfLines = 0
        username.font = UIFont.systemFontOfSize(17.0)
        username.textColor = UIColor.darkGrayColor()
        
        address = UILabel()
        address.lineBreakMode = NSLineBreakMode.ByWordWrapping
        address.numberOfLines = 0
        address.font = UIFont.systemFontOfSize(16.0)
        address.textColor = UIColor.darkGrayColor()
        
        contentView.addSubview(username)
        contentView.addSubview(address)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func initUserInfo() {
        let addressHeight = heightForTextLabel(address.text!, font: address.font, width: username.frame.width, padding: 0)
        
        address.frame = CGRectMake(username.frame.origin.x, username.frame.height + 8, username.frame.width, addressHeight)
    }
    
    func heightForTextLabel(text:String, font:UIFont, width:CGFloat, padding: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height + padding
    }
}

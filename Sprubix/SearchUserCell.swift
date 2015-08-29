//
//  SearchUserCell.swift
//  Sprubix
//
//  Created by Shion Wah on 29/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SearchUserCell: UITableViewCell {
    var delegate: UserFollowInteractionProtocol?
    var user: NSDictionary!
    
    var userImageView: UIImageView!
    var username: UILabel!
    var realname: UILabel!
    
    let userImageViewHeight: CGFloat = 40
    let nameHeight: CGFloat = 20
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Initialization code
        userImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: userImageViewHeight, height: userImageViewHeight))
        userImageView.backgroundColor = sprubixGray
        userImageView.contentMode = UIViewContentMode.ScaleAspectFit
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 0.5
        userImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        userImageView.userInteractionEnabled = true
        
        contentView.addSubview(userImageView)
        
        let usernameX: CGFloat = userImageViewHeight + 10 * 2
        username = UILabel(frame: CGRect(x: usernameX, y: 10, width: screenWidth - usernameX - 10, height: nameHeight))
        username.textColor = sprubixColor
        username.font = UIFont.boldSystemFontOfSize(15)
        
        realname = UILabel(frame: CGRect(x: usernameX, y: 30, width: screenWidth - usernameX - 10, height: nameHeight))
        realname.tintColor = UIColor.darkGrayColor()
        realname.font = UIFont.systemFontOfSize(14)
        
        contentView.addSubview(username)
        contentView.addSubview(realname)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func showProfile() {
        delegate?.showProfile(user)
    }

}

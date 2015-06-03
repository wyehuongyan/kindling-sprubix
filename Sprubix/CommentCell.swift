//
//  CommentCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 29/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userComment: SprubixTweetLabel!
    @IBOutlet var timeAgo: UILabel!
    
    var authorName: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        userImageView.backgroundColor = sprubixGray
        userImageView.contentMode = UIViewContentMode.ScaleAspectFit
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 0.5
        userImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
}

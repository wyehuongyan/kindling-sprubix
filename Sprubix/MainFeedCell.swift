//
//  MainFeedCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 26/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol OutfitInteractionProtocol {
    func tappedOutfit(indexPath: NSIndexPath)
    
    func setOutfitsLiked(outfitId: Int, liked: Bool)
    func likedOutfit(outfitId: Int, outfitImageURL: String, itemIdentifier: String, user: NSDictionary)
    func unlikedOutfit(outfitId: Int, itemIdentifier: String, user: NSDictionary)
    
    func commentOutfit()
    func spruceOutfit(indexPath: NSIndexPath)
    func showProfile(user: NSDictionary)
}

class MainFeedCell: UICollectionViewCell, TransitionWaterfallGridViewProtocol {
    var delegate: OutfitInteractionProtocol?
    var indexPath: NSIndexPath!
    var itemIdentifier: String!
    
    var imageURLString : String!
    var imageViewContent : UIImageView = UIImageView()
    var imageHeight: CGFloat!
    
    // user info and buttons
    var user: NSDictionary!
    var creationTime: NSDictionary!
    
    var infoView: UIView!
    let cellInfoViewHeight: CGFloat = 80
    
    var userName: UILabel!
    var userThumbnail: UIImageView!
    var timestamp: UILabel!
    var spruceButton: UIButton!
    var likeButton: UIButton!
    var commentsButton: UIButton!
    
    var liked: Bool?
    var outfitId: Int!
    
    let padding: CGFloat = 5
    var likeImageView:UIImageView!
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.whiteColor()
        layer.cornerRadius = 10.0
        clipsToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.lightGrayColor().CGColor
        
        contentView.addSubview(imageViewContent)
    }
    
    override func prepareForReuse() {
        infoView.removeFromSuperview()
        likeButton.selected = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let imageURL = NSURL(string: imageURLString!)
        
        imageViewContent.frame = CGRectMake(0, 0, frame.size.width, frame.size.height - cellInfoViewHeight)
        imageViewContent.setImageWithURL(imageURL)
        imageViewContent.contentMode = UIViewContentMode.ScaleAspectFill
        imageViewContent.userInteractionEnabled = true
        
        // gesture recognizers
        var outfitTapped: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "outfitTapped:")
        outfitTapped.numberOfTapsRequired = 1
        
        imageViewContent.addGestureRecognizer(outfitTapped)
        
        var outfitLiked: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "outfitLiked:")
        outfitLiked.numberOfTapsRequired = 2
        
        imageViewContent.addGestureRecognizer(outfitLiked)
        
        outfitTapped.requireGestureRecognizerToFail(outfitLiked) // so that single tap will not be called during a double tap
        
        // info view containing user info and buttons
        infoView = UIView(frame: CGRectMake(0, imageViewContent.frame.size.height, frame.size.width, cellInfoViewHeight))
        infoView.backgroundColor = UIColor.whiteColor()
        
        // build ui
        // user thumbnail
        let userThumbnailWidth: CGFloat = infoView.frame.size.height / 2 - padding * 2
        userThumbnail = UIImageView(frame: CGRectMake(padding, padding, userThumbnailWidth, userThumbnailWidth))
        
        userThumbnail.layer.cornerRadius = userThumbnail.frame.size.width / 2
        userThumbnail.clipsToBounds = true
        userThumbnail.layer.borderWidth = 0.5
        userThumbnail.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        let userThumbnailURL = NSURL(string: user["image"] as! String)
        userThumbnail.setImageWithURL(userThumbnailURL)
        
        // gesture recognizer
        let userThumbnailToProfile:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showProfile:")
        userThumbnailToProfile.numberOfTapsRequired = 1

        userThumbnail.userInteractionEnabled = true
        userThumbnail.addGestureRecognizer(userThumbnailToProfile)
        
        infoView.addSubview(userThumbnail)
        
        // user name
        let userNameWidth: CGFloat = frame.size.width / 2
        userName = UILabel(frame: CGRectMake(2 * padding + userThumbnail.frame.size.width, padding, userNameWidth, userThumbnailWidth))
        
        userName.text = user["username"] as? String
        userName.font = UIFont(name: userName.font.fontName, size: 14)
        userName.textColor = UIColor.lightGrayColor()
        
        let userNameToProfile:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showProfile:")
        userNameToProfile.numberOfTapsRequired = 1
        
        userName.userInteractionEnabled = true
        userName.addGestureRecognizer(userNameToProfile)
        
        infoView.addSubview(userName)
        
        // timestamp
        let timestampWidth: CGFloat = infoView.frame.size.height / 2 - padding
        timestamp = UILabel(frame: CGRectMake(frame.size.width - timestampWidth - padding, padding, timestampWidth, userThumbnailWidth))
        
        let timestampString = creationTime["created_at_human"] as! String
        var timestampArray = split(timestampString) {$0 == " "}
        var time = timestampArray[0]
        var stamp = timestampArray[1]
        
        timestamp.text = time + stamp[0]
        timestamp.textAlignment = NSTextAlignment.Right
        timestamp.font = UIFont(name: timestamp.font.fontName, size: 14)
        timestamp.textColor = UIColor.lightGrayColor()
        
        infoView.addSubview(timestamp)
        
        var infoViewBottom: UIView = UIView(frame: CGRectMake(0, infoView.frame.size.height / 2, frame.size.width, infoView.frame.size.height / 2))
        infoViewBottom.backgroundColor = sprubixLightGray
        
        // like button
        let likeButtonWidth = frame.size.width / 6
        likeButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image = UIImage(named: "main-like")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        likeButton.setImage(image, forState: UIControlState.Normal)
        likeButton.setImage(UIImage(named: "main-like-filled"), forState: UIControlState.Selected)
        likeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        likeButton.imageView?.tintColor = UIColor.lightGrayColor()
        likeButton.backgroundColor = sprubixLightGray
        likeButton.frame = CGRectMake(4 * likeButtonWidth, 0, likeButtonWidth, infoViewBottom.frame.size.height)
        likeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        likeButton.addTarget(self, action: "toggleOutfitLike:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // check likebutton selected
        let userData: NSDictionary? = defaults.dictionaryForKey("userData")
        let username = userData!["username"] as! String
        
        let poutfitLikesUserRef = firebaseRef.childByAppendingPath("poutfits/\(itemIdentifier)/likes/\(username)")
        
        if liked != nil {
            self.likeButton.selected = self.liked!
        } else {
            // check if user has already liked this outfit
            poutfitLikesUserRef.observeSingleEventOfType(.Value, withBlock: {
                snapshot in
                
                if (snapshot.value as? NSNull) != nil {
                    // not yet liked
                    self.liked = false
                } else {
                    self.liked = true
                }
                
                self.likeButton.selected = self.liked!
                
                self.delegate?.setOutfitsLiked(self.outfitId, liked: self.liked!)
            })
        }
        
        infoViewBottom.addSubview(likeButton)
        
        // spruce button
        let spruceButtonWidth = frame.size.width / 3
        spruceButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        image = UIImage(named: "main-spruce")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        spruceButton.setImage(image, forState: UIControlState.Normal)
        spruceButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        spruceButton.imageView?.tintColor = sprubixColor
        spruceButton.backgroundColor = sprubixLightGray
        spruceButton.frame = CGRectMake(0, 0, spruceButtonWidth, infoViewBottom.frame.size.height)
        spruceButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 0)
        spruceButton.addTarget(self, action: "spruceOutfit:", forControlEvents: UIControlEvents.TouchUpInside)
        
        infoViewBottom.addSubview(spruceButton)
        
        // comments button
        commentsButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        image = UIImage(named: "main-comments")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        commentsButton.setImage(image, forState: UIControlState.Normal)
        commentsButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        commentsButton.imageView?.tintColor = UIColor.lightGrayColor()
        commentsButton.backgroundColor = sprubixLightGray
        commentsButton.frame = CGRectMake(5 * likeButtonWidth, 0, likeButtonWidth, infoViewBottom.frame.size.height)
        commentsButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        infoViewBottom.addSubview(commentsButton)
        
        infoView.addSubview(infoViewBottom)
        
        // like heart image
        let likeImageViewWidth:CGFloat = 75
        likeImageView = UIImageView(image: UIImage(named: "main-like-filled-large"))
        likeImageView.frame = CGRect(x: frame.size.width / 2 - likeImageViewWidth / 2, y: 0, width: likeImageViewWidth, height: frame.size.height - cellInfoViewHeight)
        likeImageView.contentMode = UIViewContentMode.ScaleAspectFit
        likeImageView.alpha = 0
        
        contentView.addSubview(likeImageView)
        contentView.addSubview(infoView)
    }
    
    func snapShotForTransition() -> UIView! {
        let snapShotView = UIImageView(image: self.imageViewContent.image)
        snapShotView.frame = imageViewContent.frame
        
        //println(snapShotView)
        
        return snapShotView
    }
    
    // button actions
    func toggleOutfitLike(sender: UIButton) {
        if sender.selected != true {
            sender.selected = true
            liked = true
            
            outfitLiked(UITapGestureRecognizer())
        } else {
            sender.selected = false
            liked = false
            
            delegate?.unlikedOutfit(outfitId, itemIdentifier: itemIdentifier, user: user)
        }
    }
    
    func spruceOutfit(sender: UIButton) {
        delegate?.spruceOutfit(indexPath)
    }
    
    // gesture recognizer callbacks
    func outfitTapped(gesture: UITapGestureRecognizer) {
        delegate?.tappedOutfit(indexPath)
    }
    
    func outfitLiked(gesture: UITapGestureRecognizer) {
        delegate?.likedOutfit(outfitId, outfitImageURL: imageURLString, itemIdentifier: itemIdentifier, user: user)
        
        UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.likeImageView.alpha = 1.0
            }, completion: { finished in
                if finished {
                    UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                        self.likeImageView.alpha = 0.0
                        }, completion: nil)
                }
        })
        
        likeButton.selected = true
    }
    
    func showProfile(gesture: UITapGestureRecognizer) {
        delegate?.showProfile(user)
    }
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
}